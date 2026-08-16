# OpenTelemetry Observability Lab

A hands-on Kubernetes observability platform built around OpenTelemetry. The [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo) supplies application telemetry; this repository owns the collection, storage, querying, visualisation, and alert-rule layers around it.

It is intended for learning, experimentation, and portfolio work. It is not a production-ready reference deployment.

## Architecture

```text
                         OTLP (gRPC / HTTP)
OpenTelemetry Demo  ---------------------------->  OpenTelemetry Collector
                                                           |
                                             +-------------+-------------+
                                             |                           |
                                     Prometheus remote write          OTLP
                                             |                           |
                                             v                           v
                                    VictoriaMetrics                  Jaeger
                                             |                           |
                                             +-------------+-------------+
                                                           |
                                                           v
                                                        Grafana
                                                dashboards + alert rules
```

| Component | Purpose |
| --- | --- |
| OpenTelemetry Operator | Reconciles the `OpenTelemetryCollector` custom resource. |
| OpenTelemetry Collector | Receives OTLP, enriches it with Kubernetes metadata, batches it, and exports it. |
| VictoriaMetrics | Stores metrics and exposes a Prometheus-compatible query API. |
| Jaeger | Stores and displays distributed traces. |
| Grafana | Provides datasources, dashboards, and Grafana-managed alert rules. |
| OpenTelemetry Demo | Generates application, PostgreSQL, Kafka, and runtime telemetry. |

Logs are accepted by the Collector and sent to its `debug` exporter only; this lab has no persistent log backend.

## Repository layout

```text
helm/
  grafana/                   Datasources, alert rules, dashboard sidecar
  opentelemetry-operator/    Operator resource limits
  otel-demo/                 Demo endpoint configuration
  victoria-metrics/          VictoriaMetrics settings
manifests/
  collector.yaml             Collector and telemetry pipelines
  collector-rbac.yaml        Service account and Kubernetes metadata permissions
dashboards/                  Grafana dashboard JSON files
scripts/
  install.sh                 End-to-end installation
  port-forward.sh            Local access to all UIs
  uninstall.sh               Teardown
```

## Prerequisites

- A working Kubernetes cluster (Minikube, kind, or another local cluster)
- `kubectl` configured for that cluster
- Helm 3
- Git

Docker is required only when your local Kubernetes distribution requires it. The installer creates namespaces, CRDs, cluster-scoped RBAC, and Helm releases.

## Quick start

```bash
git clone https://github.com/alexez-cy/otel-observability-lab.git
cd otel-observability-lab
bash scripts/install.sh
```

The installer adds the required Helm repositories and installs:

1. cert-manager
2. OpenTelemetry Operator
3. VictoriaMetrics
4. Jaeger
5. Grafana and its dashboard ConfigMap
6. Collector RBAC and the Collector custom resource
7. OpenTelemetry Demo

The Grafana Helm chart is pinned to `10.5.15`, which packages Grafana OSS `12.3.1`. The other charts are resolved from their configured Helm repositories at install time.

## Access

Run the forwarding helper in a dedicated terminal:

```bash
bash scripts/port-forward.sh
```

| Service | URL |
| --- | --- |
| Grafana | <http://localhost:3000> |
| Jaeger | <http://localhost:16686> |
| VictoriaMetrics | <http://localhost:8428> |
| OpenTelemetry Demo | <http://localhost:8081> |

Retrieve the Grafana administrator password:

```bash
kubectl get secret -n observability grafana \
  -o jsonpath='{.data.admin-password}' | base64 --decode
echo
```

Sign in as `admin`.

## Verify the deployment

```bash
kubectl get pods -n observability
kubectl get pods -n otel-demo
kubectl get opentelemetrycollector -n observability
kubectl logs -n observability deployment/collector-collector --tail=100
```

Open the demo UI and generate traffic, then check:

- Grafana dashboards in **Dashboards**
- Grafana-managed rules in **Alerting → Alert rules**
- Jaeger traces in **Search**
- VictoriaMetrics query results at <http://localhost:8428/vmui/>

Metric names are produced by the deployed OpenTelemetry Demo version. If that chart is upgraded, validate the dashboard and alert PromQL expressions in VictoriaMetrics before relying on them.

## Telemetry pipeline

The Collector is declared in [manifests/collector.yaml](manifests/collector.yaml). It accepts OTLP on:

- gRPC: `4317`
- HTTP: `4318`

Each metrics, traces, and logs pipeline uses:

1. `memory_limiter` to protect the Collector process
2. `batch` to reduce export overhead
3. `k8sattributes` to associate telemetry with Kubernetes resources

Metrics go to VictoriaMetrics through Prometheus Remote Write. Traces go to Jaeger over OTLP. The Collector's service account has read-only, cluster-scoped permissions required by `k8sattributes`; see [manifests/collector-rbac.yaml](manifests/collector-rbac.yaml).

## Dashboards

The dashboard sidecar watches ConfigMaps labeled `grafana_dashboard=1`. During installation, `scripts/install.sh` creates that ConfigMap from every JSON file in [dashboards](dashboards/).

The supplied dashboards cover:

- Service RED signals: request rate, errors, and latency
- PostgreSQL/database activity
- Kafka throughput, lag, latency, and partition health
- Process and runtime system metrics

Grafana is provisioned with stable datasource UIDs:

| Datasource | UID |
| --- | --- |
| VictoriaMetrics | `victoriametrics` |
| Jaeger | `jaeger` |

## Declarative Grafana Alerting

Alert rules are provisioned by the Grafana Helm chart from the `alerting:` section of [helm/grafana/values.yaml](helm/grafana/values.yaml). The chart renders `rules.yaml` into Grafana's provisioning directory and restarts the deployment when that configuration changes. No alerting sidecar or additional controller is used.

The `observability-alerts` rule group evaluates every minute and includes:

- high HTTP 5xx rate
- high HTTP p95 latency
- high database p95 latency
- high Kafka consumer lag
- Kafka under-replicated partitions

Rules use `NoData` when no series are returned and enter `Alerting` when the query fails. They are Grafana-managed rules, so change the Helm values and upgrade Grafana instead of editing them in the UI.

This repository provisions rules only. It does **not** provision a contact point or notification policy, so configure a contact point in Grafana before expecting Slack, email, PagerDuty, or webhook notifications.

After changing a dashboard, recreate the watched ConfigMap:

```bash
kubectl create configmap grafana-dashboards \
  --namespace observability \
  --from-file=dashboards/ \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap grafana-dashboards \
  --namespace observability \
  grafana_dashboard=1 --overwrite
```

After changing an alert rule, upgrade Grafana:

```bash
helm upgrade --install grafana grafana/grafana \
  --namespace observability \
  --version 10.5.15 \
  -f helm/grafana/values.yaml
```

## Teardown

```bash
bash scripts/uninstall.sh
```

Review the script before running it on a shared cluster. The Collector RBAC uses cluster-scoped resources and should be removed manually if teardown is interrupted.

## Scope and next steps

Useful extensions for a more production-like deployment include:

- pinning every Helm chart version and adding CI manifest validation
- persistent storage and backups for VictoriaMetrics, Jaeger, and Grafana
- Collector resource requests/limits and high availability
- TLS, authentication, and network policies between components
- a log backend such as Loki
- Kubernetes/node metrics and recording rules
- declarative contact points and notification policies, with secrets kept out of Git

## License

This project is provided for educational, experimentation, and portfolio purposes.

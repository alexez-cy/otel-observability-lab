# OpenTelemetry Grafana Dashboards

Dashboards for the OpenTelemetry observability lab, built around the metrics already exported by the OpenTelemetry Collector to VictoriaMetrics.

## Dashboards

### Service Overview
Focuses on the RED signals for HTTP services:

- Request rate
- 5xx error rate
- p95/p99 latency
- Active requests
- Response throughput

### PostgreSQL / Database Overview
Uses the Npgsql/OpenTelemetry database metrics available in VictoriaMetrics:

- Connection usage
- Operation latency
- Connection wait time
- Bytes read/written
- Executing operations
- Prepared statement ratio

### Kafka Overview
Covers Kafka client and broker telemetry:

- Consumer throughput
- Consumer lag
- Fetch latency
- Request latency
- Network throughput
- Partition health
- Consumer rebalances

### Runtime & System Overview
Uses the system/process metrics already exported by the application telemetry:

- CPU utilization
- Memory utilization
- Process CPU/memory
- Network throughput
- Disk I/O
- Swap utilization
- Open file descriptors

## Datasources

VictoriaMetrics:

```text
http://vm-victoria-metrics-single-server:8428
```

Jaeger:

```text
http://jaeger:16686
```

The datasource UIDs are stable:

```text
victoriametrics
jaeger
```

## Provisioning

The supplied `values.yaml` enables Grafana's dashboard sidecar. Apply the dashboard ConfigMaps:

```bash
kubectl apply -f dashboard-configmaps.yaml
```

Then install/upgrade Grafana:

```bash
helm upgrade --install grafana \
  grafana/grafana \
  --namespace observability \
  --create-namespace \
  -f values.yaml
```

For an existing Grafana deployment, the sidecar will watch the labeled ConfigMaps and load the dashboards automatically.

## Access

```bash
kubectl port-forward -n observability svc/grafana 3000:80
```

Open:

```text
http://localhost:3000
```

Retrieve the admin password:

```bash
kubectl get secret -n observability grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

## Metric Source

These dashboards intentionally use the metrics already present in VictoriaMetrics instead of assuming a Prometheus/node-exporter/Kubernetes monitoring stack.

The OpenTelemetry Collector currently receives OTLP metrics and exports them using Prometheus Remote Write.

If metric names change with a future OpenTelemetry Demo version, update the PromQL expressions in the relevant dashboard JSON.

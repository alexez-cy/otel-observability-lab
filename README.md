# OpenTelemetry Observability Lab

A reproducible Kubernetes observability platform built with OpenTelemetry, VictoriaMetrics, Jaeger, and Grafana.

The [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo) is used as the telemetry source. The focus of this project is the observability platform around the application: collecting, processing, storing, querying, and visualizing telemetry.

## Architecture

```text
                 OpenTelemetry Demo
                  Microservices App
                         |
                         | OTLP
                         v
              +-----------------------+
              | OpenTelemetry         |
              | Collector             |
              |                       |
              | - OTLP receiver       |
              | - memory limiter      |
              | - batch processing    |
              +-----------+-----------+
                          |
                 +--------+--------+
                 |                 |
              metrics            traces
                 |                 |
                 v                 v
        +----------------+   +-------------+
        | VictoriaMetrics|   |    Jaeger   |
        +-------+--------+   +------+------+ 
                |                   |
                +--------+----------+
                         |
                         v
                    +---------+
                    | Grafana |
                    +---------+
```

## Components

### OpenTelemetry Operator

Manages the OpenTelemetry Collector deployment using a Kubernetes `OpenTelemetryCollector` resource.

### OpenTelemetry Collector

The Collector is the central telemetry pipeline.

It receives OTLP telemetry over:

- gRPC — `4317`
- HTTP — `4318`

The pipeline uses:

- memory limiting to protect the Collector from excessive resource usage
- batching to improve telemetry processing efficiency

Metrics are exported to VictoriaMetrics using Prometheus Remote Write.

Traces are exported to Jaeger using OTLP.

### VictoriaMetrics

VictoriaMetrics stores metrics received from the OpenTelemetry Collector and provides a Prometheus-compatible query interface for Grafana.

### Jaeger

Jaeger stores and visualizes distributed traces received from the OpenTelemetry Collector.

### Grafana

Grafana provides the visualization layer and is automatically provisioned with:

- VictoriaMetrics datasource
- Jaeger datasource
- Observability dashboards

The PostgreSQL, Kafka, and application workloads are provided by the OpenTelemetry Demo. They are used as realistic telemetry sources for testing and demonstrating the observability platform.


## Prerequisites

- Kubernetes / Minikube
- kubectl
- Helm
- Docker
- Git

## Installation

Clone the repository:

```bash
git clone https://github.com/alexez-cy/otel-observability-lab.git
cd otel-observability-lab
```

Run the installation script:

```bash
./scripts/install.sh
```

The script installs and configures:

1. cert-manager
2. OpenTelemetry Operator
3. VictoriaMetrics
4. Jaeger
5. Grafana
6. OpenTelemetry Collector
7. OpenTelemetry Demo

The script also waits for the main workloads to become ready.

## Access

Use the port-forwarding script to access the services locally:

```bash
./scripts/port-forward.sh
```

### Grafana credentials

The Grafana admin password is stored in a Kubernetes Secret.

Retrieve it with:

```bash
kubectl get secret -n observability grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

## Design Goals

This project demonstrates practical platform and observability engineering concepts:

- Reproducible Kubernetes deployments
- Declarative configuration with Helm
- OpenTelemetry Collector pipeline design
- OTLP ingestion over gRPC and HTTP
- Telemetry batching and resource protection
- Prometheus Remote Write
- Metrics storage with VictoriaMetrics
- Distributed tracing with Jaeger
- Automated Grafana datasource provisioning
- Automated Grafana dashboard provisioning
- Observability of distributed applications

## Future Improvements

Possible extensions include:

- Kubernetes node and workload metrics
- Alerting and recording rules
- Grafana alerting
- Persistent storage configuration
- TLS between observability components
- CI validation of Helm and Kubernetes manifests
- Collector high-availability deployment

## License

This project is intended for educational, experimentation, and portfolio purposes.
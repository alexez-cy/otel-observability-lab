OpenTelemetry Observability Lab

Overview

This project is a hands-on observability lab built on Kubernetes using Minikube. It demonstrates how to collect, process, store, and visualize telemetry using the OpenTelemetry ecosystem and modern observability tools.

The goal is to provide a reproducible environment for learning and experimenting with OpenTelemetry concepts, Collector pipelines, metrics, traces, and Kubernetes observability.

⸻

Architecture

                          +----------------+
                          |    Grafana     |
                          +--------+-------+
                                   |
                    +--------------+--------------+
                    |                             |
                    |                             |
          +---------v---------+         +---------v---------+
          | VictoriaMetrics   |         |      Jaeger       |
          +---------+---------+         +---------+---------+
                    ^                             ^
                    |                             |
                    +-------------+---------------+
                                  |
                    +-------------v---------------+
                    | OpenTelemetry Collector     |
                    | (Operator Managed)          |
                    +-------------+---------------+
                                  ^
                                  |
                    +-------------+---------------+
                    | OpenTelemetry Demo          |
                    | (Microservices Application) |
                    +-----------------------------+

Prerequisites

Kubernetes (Minikube)
kubectl
Helm
Docker
Git

Installation

The installation process will be automated through the scripts in the scripts/ directory.

Example workflow:

git clone https://github.com/alexez-cy/otel-observability-lab.git
cd otel-observability-lab
./scripts/install.sh

⸻


Port forwarding will be provided by:

./scripts/port-forward.sh

⸻

License

This project is intended for educational and experimentation purposes.

#!/usr/bin/env bash

set -Eeuo pipefail

NAMESPACE="observability"
DEMO_NAMESPACE="otel-demo"

# cleanup() {
#     echo
#     echo "Stopping port-forwards..."
#     jobs -p | xargs -r kill
# }

# trap cleanup EXIT INT TERM


echo "Starting port-forwards..."

# Grafana
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/grafana \
    3000:3000 \
    > /tmp/grafana-port-forward.log 2>&1 &

# Jaeger
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/jaeger \
    16686:16686 \
    > /tmp/jaeger-port-forward.log 2>&1 &

# VictoriaMetrics
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/vm-victoria-metrics-single-server \
    8428:8428 \
    > /tmp/victoria-metrics-port-forward.log 2>&1 &

# OpenTelemetry Demo frontend
kubectl port-forward \
    -n "${DEMO_NAMESPACE}" \
    svc/frontendproxy \
    8080:8080 \
    > /tmp/otel-demo-port-forward.log 2>&1 &


sleep 3

echo
echo "========================================"
echo " OpenTelemetry Observability Lab"
echo "========================================"
echo
echo "Grafana:"
echo "  http://localhost:3000"
echo
echo "Jaeger:"
echo "  http://localhost:16686"
echo
echo "VictoriaMetrics:"
echo "  http://localhost:8428"
echo
echo "OpenTelemetry Demo:"
echo "  http://localhost:8080"
echo
echo "Press Ctrl+C to stop all port-forwards."
echo
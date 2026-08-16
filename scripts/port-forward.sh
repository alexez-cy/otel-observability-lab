#!/usr/bin/env bash

set -Eeuo pipefail

NAMESPACE="observability"
DEMO_NAMESPACE="otel-demo"

# Cleanup function
cleanup() {
    echo
    echo "Stopping all port-forwards..."
    jobs -p | xargs -r kill 2>/dev/null || true
    echo "Port-forwards stopped."
    echo
}

# Trap signals to ensure cleanup on exit or interruption
trap cleanup EXIT INT TERM


# Helper function
info() {
    local msg="$1"
    echo
    echo "================================================="
    echo "$msg"
    echo "================================================="
    echo
}

echo "Starting port-forwards..."

# Define port mappings (avoiding common conflict ports)
GRAFANA_PORT="3000"  # Default Grafana is 3000
JAEGER_PORT="16686"  # Default Jaeger UI
VM_PORT="8428"       # VictoriaMetrics
DEMO_PORT="8081"     # OpenTelemetry Demo frontend (8080 is common, using 8081)

echo "Port mapping:"
echo "  Grafana:   http://localhost:${GRAFANA_PORT}"
echo "  Jaeger:    http://localhost:${JAEGER_PORT}"
echo "  VictoriaMetrics: http://localhost:${VM_PORT}"
echo "  OpenTelemetry Demo: http://localhost:${DEMO_PORT}"
echo

# Grafana - runs on port 80 inside the service
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/grafana \
    "${GRAFANA_PORT}:80" \
    &

# Jaeger
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/jaeger \
    "${JAEGER_PORT}:16686" \
    &

# VictoriaMetrics
kubectl port-forward \
    -n "${NAMESPACE}" \
    svc/vm-victoria-metrics-single-server \
    "${VM_PORT}:8428" \
    &

# OpenTelemetry Demo frontend - service name is 'frontend-proxy'
kubectl port-forward \
    -n "${DEMO_NAMESPACE}" \
    svc/frontend-proxy \
    "${DEMO_PORT}:8080" \
    &

# Wait a moment for all services to be ready
wait
sleep 3

# Check the status of all services
info "Checking Services..."
kubectl get svc -n "${NAMESPACE}" -o wide
kubectl get svc -n "${DEMO_NAMESPACE}" -o wide

info "Port-forwards are running."
echo
echo "Grafana:"
echo "  http://localhost:${GRAFANA_PORT}"
echo
echo "Jaeger:"
echo "  http://localhost:${JAEGER_PORT}"
echo
echo "VictoriaMetrics:"
echo "  http://localhost:${VM_PORT}"
echo
echo "OpenTelemetry Demo:"
echo "  http://localhost:${DEMO_PORT}"
echo
echo "Press Ctrl+C to stop all port-forwards."
echo

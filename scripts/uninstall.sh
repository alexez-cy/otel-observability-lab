#!/usr/bin/env bash

set -Eeuo pipefail

# Remove the Collector and its cluster-scoped RBAC before uninstalling the
# operator that owns the OpenTelemetryCollector CRD.
kubectl delete -f manifests/collector.yaml --ignore-not-found=true
kubectl delete -f manifests/collector-rbac.yaml --ignore-not-found=true

helm uninstall otel-demo -n otel-demo || true

helm uninstall grafana -n observability || true

helm uninstall vm -n observability || true

helm uninstall jaeger -n observability || true

helm uninstall opentelemetry-operator -n observability || true

helm uninstall cert-manager -n cert-manager || true

helm repo remove vm || true

helm repo remove grafana || true

helm repo remove open-telemetry || true

helm repo remove jetstack || true

helm repo remove jaegertracing || true

kubectl delete namespace observability --ignore-not-found=true

kubectl delete namespace otel-demo --ignore-not-found=true


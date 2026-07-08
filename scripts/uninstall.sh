#!/usr/bin/env bash

set -Eeuo pipefail

helm uninstall otel-demo -n otel-demo || true

helm uninstall grafana -n observability || true

helm uninstall vm -n observability || true

helm uninstall jaeger -n observability || true

helm uninstall opentelemetry-operator -n observability || true

helm repo remove vm || true

helm repo remove grafana || true

helm repo remove open-telemetry || true

helm repo remove jetstack || true

kubectl delete -f manifests/collector.yaml --ignore-not-found=true



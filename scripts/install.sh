#!/usr/bin/env bash

set -Eeuo pipefail

########################################
# Configuration
########################################

OBS_NAMESPACE="observability"
DEMO_NAMESPACE="otel-demo"

########################################
# Helper functions
########################################

info() {
    echo
    echo "================================================="
    echo "$1"
    echo "================================================="
}


########################################
# Helm repositories
########################################

info "Adding Helm repositories"



helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add vm https://victoriametrics.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update


########################################
# cert-manager
########################################

info "Installing cert-manager"


helm upgrade --install cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true

kubectl rollout status deployment/cert-manager \
    -n cert-manager \
    --timeout=180s

kubectl rollout status deployment/cert-manager-webhook \
    -n cert-manager \
    --timeout=180s

kubectl rollout status deployment/cert-manager-cainjector \
    -n cert-manager \
    --timeout=180s

########################################
# Operator
########################################

info "Installing OpenTelemetry Operator"

helm upgrade --install opentelemetry-operator \
    open-telemetry/opentelemetry-operator \
    --namespace "${OBS_NAMESPACE}"

kubectl rollout status deployment/opentelemetry-operator \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

########################################
# VictoriaMetrics
########################################

info "Installing VictoriaMetrics"

helm upgrade --install vm \
    vm/victoria-metrics-single \
    --namespace "${OBS_NAMESPACE}" \
    --create-namespace \
    -f helm/victoria-metrics/values.yaml

kubectl rollout status \
    statefulset/vm-victoria-metrics-single-server \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

########################################
# Jaeger
########################################

info "Installing Jaeger"

helm upgrade --install jaeger \
    jaegertracing/jaeger \
    --namespace "${OBS_NAMESPACE}" \
    --create-namespace \

kubectl wait \
    --for=condition=Ready \
    pod \
    -l app.kubernetes.io/instance=jaeger \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

########################################
# Grafana
########################################

info "Installing Grafana"

helm upgrade --install grafana \
    grafana/grafana \
    --namespace "${OBS_NAMESPACE}" \

kubectl rollout status deployment/grafana \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

########################################
# OpenTelemetry Collector
########################################

info "Installing OpenTelemetry Collector"

kubectl apply -f manifests/collector.yaml


########################################
# OpenTelemetry Demo
########################################

info "Installing OpenTelemetry Demo"

helm repo add open-telemetry \
    https://open-telemetry.github.io/opentelemetry-helm-charts

helm repo update

helm upgrade --install otel-demo \
    open-telemetry/opentelemetry-demo \
    --namespace "${DEMO_NAMESPACE}" \
    --create-namespace \
    -f helm/otel-demo/values.yaml

kubectl wait \
    --for=condition=Ready \
    pod \
    -n "${DEMO_NAMESPACE}" \
    --all \
    --timeout=300s

########################################
# Finished
########################################

echo "Installation completed successfully!"


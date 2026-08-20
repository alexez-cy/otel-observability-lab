#!/usr/bin/env bash

set -Eeuo pipefail

########################################
# Configuration
########################################

OBS_NAMESPACE="observability"
DEMO_NAMESPACE="otel-demo"

########################################
# Project paths and versions
########################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/config/versions.env"

########################################
# Helper functions
########################################

info() {
    echo
    echo "==> $1"
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
    --version "${CERT_MANAGER_VERSION}" \
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
# OpenTelemetry Operator
########################################

info "Installing OpenTelemetry Operator"

helm upgrade --install opentelemetry-operator \
    open-telemetry/opentelemetry-operator \
    --namespace "${OBS_NAMESPACE}" \
    --create-namespace \
    --hide-notes \
    --version "${OTEL_OPERATOR_VERSION}" \
    -f helm/opentelemetry-operator/values.yaml

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
    --hide-notes \
    --version "${VICTORIA_METRICS_VERSION}" \
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
    --hide-notes \
    --version "${JAEGER_VERSION}"

kubectl rollout status deployment/jaeger \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

########################################
# Grafana
########################################

info "Installing Grafana"

kubectl create configmap grafana-dashboards \
    --namespace "${OBS_NAMESPACE}" \
    --from-file="${PROJECT_ROOT}/dashboards/" \
    --dry-run=client -o yaml |
    kubectl apply -f -

kubectl label configmap grafana-dashboards \
    -n "${OBS_NAMESPACE}" \
    grafana_dashboard=1 \
    --overwrite

helm upgrade --install grafana \
    grafana/grafana \
    --namespace "${OBS_NAMESPACE}" \
    --create-namespace \
    --hide-notes \
    --version "${GRAFANA_VERSION}" \
    -f "${PROJECT_ROOT}/helm/grafana/values.yaml"

kubectl rollout status deployment/grafana \
    -n "${OBS_NAMESPACE}" \
    --timeout=180s

GRAFANA_PASSWORD=$(kubectl get secret \
    -n "${OBS_NAMESPACE}" \
    grafana \
    -o jsonpath="{.data.admin-password}" | base64 --decode)

info "Grafana credentials"
echo "Username: admin"
echo "Password: ${GRAFANA_PASSWORD}"

########################################
# OpenTelemetry Collector RBAC
########################################

info "Installing Collector RBAC"

kubectl apply -f "${PROJECT_ROOT}/manifests/collector-rbac.yaml"

########################################
# OpenTelemetry Collector
########################################

info "Installing OpenTelemetry Collector"

kubectl apply -f "${PROJECT_ROOT}/manifests/collector.yaml"

########################################
# OpenTelemetry Demo
########################################

info "Installing OpenTelemetry Demo"

helm upgrade --install otel-demo \
    open-telemetry/opentelemetry-demo \
    --namespace "${DEMO_NAMESPACE}" \
    --create-namespace \
    --hide-notes \
    --version "${OTEL_DEMO_VERSION}" \
    -f "${PROJECT_ROOT}/helm/otel-demo/values.yaml"

kubectl wait \
    --for=condition=Ready \
    pod \
    -n "${DEMO_NAMESPACE}" \
    --all \
    --timeout=300s

########################################
# Finished
########################################

echo
echo "Installation completed successfully!"
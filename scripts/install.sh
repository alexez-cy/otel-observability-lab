#!/usr/bin/env bash

set -Eeuo pipefail

########################################
# Configuration
########################################

OBS_NAMESPACE="observability"
DEMO_NAMESPACE="otel-demo"

CERT_MANAGER_VERSION="v1.21.1"
OTEL_OPERATOR_VERSION="0.121.0"
VICTORIA_METRICS_VERSION="0.45.0"
JAEGER_VERSION="4.12.0"
GRAFANA_VERSION="10.5.15"
OTEL_DEMO_VERSION="0.41.0"

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
# Operator
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
    --from-file=dashboards/ \
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
    -f helm/grafana/values.yaml

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

kubectl apply -f manifests/collector-rbac.yaml

########################################
# OpenTelemetry Collector
########################################

info "Installing OpenTelemetry Collector"

kubectl apply -f manifests/collector.yaml

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

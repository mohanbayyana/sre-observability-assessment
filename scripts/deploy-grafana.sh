#!/bin/bash

set -e

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values kubernetes/observability/grafana/values.yaml
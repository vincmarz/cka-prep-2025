#!/bin/bash

echo "🔄 Cancellazione dei namespace dei task CKA in corso..."

namespaces=(
  hpa-ns
  crio-ns
  argocd-ns
  priority-ns
  ingress-ns
  quota-ns
  pvc-ns
  sidecar-ns
  gateway-ns
  cert-ns
  rbac-ns
  scheduling-ns
  config-ns
  ds-ns
  netpol-ns
  storage-ns
  stateful-ns
  batch-ns
  ingress-ns
  helm-ns 
  multi-ns 
  cdr-ns
  debug-ns  
)

for ns in "${namespaces[@]}"; do
  echo "➡️ Eliminazione namespace: $ns"
  kubectl delete ns "$ns" --ignore-not-found
done

echo "✅ Cleanup completato."


#!/bin/bash

echo "🔄 Creazione dei namespace dei task CKA in corso..."

namespaces=(
  hpa-ns
  crio-ns
  argocd-ns
  priority-ns
  ingress-ns
  ingress-tls-ns
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
  helm-ns 
  multi-ns 
  crd-ns 
  debug-ns 
)

for ns in "${namespaces[@]}"; do
  echo "➡️ Creazione namespace: $ns"
  kubectl create ns "$ns"
done

echo "✅ Creazione dei namespace completata."

echo "Preparazione lab"
kubectl apply -f 01.hpa-ns/hpa.yaml
kubectl apply -f 04.priority-ns/priority.yaml
kubectl apply -f 05.ingress-ns/ingress.yaml
kubectl apply -f 06.quota-ns/quota.yaml
kubectl apply -f 07.pvc-ns/pvc.yaml
kubectl apply -f 09.gateway-ns/http-gateway.yaml
kubectl apply -f 12.rbac-ns/rbac-pod.yaml
kubectl apply -f 15.debug-ns/troubleshooting.yaml 
kubectl apply -f 17.netpol-ns/web-pod.yaml
kubectl apply -f 17.netpol-ns/app-pod.yaml
kubectl apply -f 22.ingress-tls-ns
echo "✅ Creazione del lab completata."

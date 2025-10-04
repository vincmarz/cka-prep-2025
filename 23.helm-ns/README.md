Installare nginx con Helm in helm-ns impostando replicaCount=2:

helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
helm -n helm-ns install my-nginx wiremind/nginx --set replicaCount=2 --version 2.1.1

Verificare:

kubectl get pods -n helm-ns

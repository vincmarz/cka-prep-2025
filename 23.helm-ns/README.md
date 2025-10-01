Passaggi:

    Creare il namespace:

kubectl create ns helm-ns

    Installare nginx con Helm in quel namespace, impostando replica=2:

helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
helm -n helm-ns install my-nginx wiremind/nginx --set replicaCount=2 --version 2.1.1

    Verificare:

kubectl get pods -n helm-ns

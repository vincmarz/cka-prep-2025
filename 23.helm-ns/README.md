Passaggi:

    Creare il namespace:

kubectl create ns helm-ns

    Installare nginx con Helm in quel namespace, impostando replica=2:

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx --namespace helm-ns --set replicaCount=2

    Verificare:

kubectl get pods -n helm-ns
## CKA Prep 2025 
**Nota:** _per il setup dell'esame, eseguire cka-setup.sh._
_Il nome del namespace del singolo task è indicato tra parentesi_ 

### 1. HPA Configuration (hpa-ns)
**Obiettivo:**

Creare un HPA per scalare automaticamente un deployment in base all'utilizzo della CPU.
Il deployment hpa-app deve avere un minimo di 1 e un massimo di 5 pod e lavorare con l'utilizzo di CPU al 50%. Impostare inoltre il parametro
stabilizationWindowSecond per lo scaleDown a 30 secondi.

**Risoluzione:**

Creare un horizontalpodautoscalers hpa-app:
```
kubectl autoscale deployment hpa-app --cpu-percent=50 --min=1 --max=5
```

Editare l'HAP per aggiungere il parametro:
```
k -n hpa-ns edit hpa hpa-app 
[...]
spec:
  behavior:                               # ADD
    scaleDown:                            # ADD
      stabilizationWindowSeconds: 30      # ADD
[...]
```
Verifica:
```
kubectl get hpa -n hpa-ns
kubectl describe hpa nginx-hpa -n hpa-ns
```
Possiamo aumentare il carico per osservare come reagisce l'autoscaler all'aumento del workload. 
Per fare ciò, avviare un Pod diverso che funga da client.
Il container all'interno del Pod client viene eseguito in un ciclo infinito, inviando query al servizio Apache.
Eseguirlo in un terminale separato in modo che la generazione del carico continui.

```
kubectl -n hpa-ns run -it load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://hpa-app; done"
```
### 2. Installazione CRI-O (su nodo Linux Ubuntu 22.04)
**Obiettivo:**

Installare CRI-O su un nodo Ubuntu 22. Installare con dpkg il package cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb disponibile ./02.crio-ns. Avviare e abilitare il servizio. 
Dopo l'avviao, configurare i seguenti parametri a livello di sistema operativo: 
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1

Nota:
Scricare il package da:
https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb

Su Ubuntu installare docker-ce:
```
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce -y
```

**Risoluzione:** 

Dopo il login, eseguire sul nodo:

```
sudo dpkg -i cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb
```

Avviare e abilitare il servizio:
```
sudo systemctl start cri-docker
sudo systemctl enable cri-docker 
```

Verifica:
```
sudo systemctl status cri-docker 
```

Configurare systcl:
```
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

Verifica:
```
sudo sysctl --system
```

### 3. ArgoCD via Helm 3 (argocd-ns)
**Obiettivo:**

Installare ArgoCD v.7.8.0 senza CRD. Installare il repository https://argoproj.github.io/argo-helm con il nome argo. Salvare i valori del chart nel file
argo-helm.yaml della versione 7.8.0, utilizzando il template senza installare le CRD. Installare ArgoCD dal file argo-helm.yaml. 

**Risoluzione:** 

Aggiungere il repository richiesto assegnando il nome argo:
```
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```
Verificare la presenza della versione richiesta:

```
helm search repo -l | grep argo-cd
[...]
argo/argo-cd                            	7.8.1        	v2.14.2                                       	A Helm chart for Argo CD, a declarative, GitOps...
argo/argo-cd                            	7.8.0        	v2.14.1                                       	A Helm chart for Argo CD, a declarative, GitOps...
argo/argo-cd                            	7.7.23       	v2.13.4                                       	A Helm chart for Argo CD, a declarative, GitOps...
[...]
```

Verificare quali sono i valori per impostare i CRD nel chart:
```
helm -n argocd-ns show values argo/argo-cd --version 7.8.0 | grep -i crd -A3 -B3
  enabled: false

## Custom resource configuration
crds:
  # -- Install and upgrade CRDs
  install: true
  # -- Keep CRDs on chart uninstall
  keep: true
  # -- Annotations to be added to all CRDs
  annotations: {}
  # -- Addtional labels to be added to all CRDs
  additionalLabels: {}

## Globally shared configuration
```

Salvare i valori di default del chart con un template della versione 7.8.0, senza le CRD:
```
helm -n argocd-ns template argocd argo/argo-cd --version 7.8.0 --set crds.install=false > argo-helm.yaml
```

Installare ArgoCD utilizzando il file argo-helm.yaml:
```
kubectl apply -f argo-helm.yaml
```

Check:
```
k -n argocd-ns get all
NAME                                                            READY   STATUS      RESTARTS   AGE
pod/argo-cd-argocd-application-controller-0                     1/1     Running     0          31s
pod/argo-cd-argocd-applicationset-controller-5f6f6b49d9-pjfqc   1/1     Running     0          35s
pod/argo-cd-argocd-dex-server-f87fd859d-j5pjg                   1/1     Running     0          33s
pod/argo-cd-argocd-notifications-controller-6c8d8b4d7c-lnqf8    1/1     Running     0          35s
pod/argo-cd-argocd-redis-6d8d878d8f-sxq6g                       1/1     Running     0          32s
pod/argo-cd-argocd-redis-secret-init-rzbdt                      0/1     Completed   0          30s
pod/argo-cd-argocd-repo-server-84964656fd-h9kjq                 1/1     Running     0          34s
pod/argo-cd-argocd-server-66476f6cb6-p6gcf                      1/1     Running     0          34s

NAME                                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/argo-cd-argocd-applicationset-controller   ClusterIP   10.110.179.19    <none>        7000/TCP            36s
service/argo-cd-argocd-dex-server                  ClusterIP   10.96.98.146     <none>        5556/TCP,5557/TCP   36s
service/argo-cd-argocd-redis                       ClusterIP   10.99.252.228    <none>        6379/TCP            35s
service/argo-cd-argocd-repo-server                 ClusterIP   10.99.163.169    <none>        8081/TCP            36s
service/argo-cd-argocd-server                      ClusterIP   10.105.193.113   <none>        80/TCP,443/TCP      36s

NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argo-cd-argocd-applicationset-controller   1/1     1            1           35s
deployment.apps/argo-cd-argocd-dex-server                  1/1     1            1           34s
deployment.apps/argo-cd-argocd-notifications-controller    1/1     1            1           35s
deployment.apps/argo-cd-argocd-redis                       1/1     1            1           33s
deployment.apps/argo-cd-argocd-repo-server                 1/1     1            1           35s
deployment.apps/argo-cd-argocd-server                      1/1     1            1           34s

NAME                                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/argo-cd-argocd-applicationset-controller-5f6f6b49d9   1         1         1       35s
replicaset.apps/argo-cd-argocd-dex-server-f87fd859d                   1         1         1       33s
replicaset.apps/argo-cd-argocd-notifications-controller-6c8d8b4d7c    1         1         1       35s
replicaset.apps/argo-cd-argocd-redis-6d8d878d8f                       1         1         1       33s
replicaset.apps/argo-cd-argocd-repo-server-84964656fd                 1         1         1       34s
replicaset.apps/argo-cd-argocd-server-66476f6cb6                      1         1         1       34s

NAME                                                     READY   AGE
statefulset.apps/argo-cd-argocd-application-controller   1/1     32s

NAME                                         STATUS     COMPLETIONS   DURATION   AGE
job.batch/argo-cd-argocd-redis-secret-init   Complete   1/1           14s        30s

```

### 4. PriorityClass (priority-ns)
**Obiettivo:**

Creare la priorityclass con il nome my-priority con la descrizione "My priority pods" ma che non sia la default priority. 
Impostare la priorityclass con un valore che sia appena inferiore alla più grande priority dei pod presenti nel namespace priority-ns. 
Utilizzare la priorityclass my-priority in un pod priority-pod con immagine busybox. Infine salvare in ordine decrescente 
di priority l'elenco dei pod e salvarlo nel file 4.priority.list.

**Risoluzione:**

Creare la priorityclass:

```
k create priorityclass my-priority --value=-1 --global-default=false --description="My priority pods"

k -n priority-ns run priority-pod --image=busybox --dry-run=client -o yaml  -- sh -c 'sleep 3600'  > 4.pod.yaml
```
Editare 4.pod.yaml e aggiungere dopo .spec:
```
priorityClassName: my-priority
```
Creare il pod:
```
k apply -f pod-pc.yaml
```
Check:
```
k -n priority-ns get po --no-headers --sort-by=.spec.priority | tac
web            1/1   Running   0     12m
sleeper        1/1   Running   0     12m
priority-pod   1/1   Running   0     4m56s
```

L'ordine decrescente mostra il pod priority in fondo alla lista.

### 5. Ingress Setup (ingress-ns)
**Obiettivo:**

Creazione di un ingress Nginx. Nel namespace è presente il pod web esposto con il service web: creare un Ingress Nginx con host web.local.

**Prerequisito:** controller Nginx Ingress installato.

**Preparazione:**
```
k apply -f 05.ingress-ns/ingress.yaml 
```
**Risoluzione:**

Creare il file YAML dell'Ingress:

05.ingress.yaml
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: ingress-ns
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: web.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```
Creare l'Ingress:
```
k apply -f 05.ingress.yaml
```
Verifica:
```
kubectl get ingress -n ingress-ns
```

Aggiungere web.local a /etc/hosts

Verifica (valida con plugin CNI Calico) :
```
k -n ingress-ns get po -owide
NAME                   READY   STATUS    RESTARTS   AGE    IP           NODE          NOMINATED NODE   READINESS GATES
web-78df96f968-n8gl8   1/1     Running   0          108m   10.0.3.121   worker2-k8s   <none>           <none>

ping worker2-k8s
PING worker2-k8s (192.168.122.176) 56(84) bytes of data.

/etc/hosts
192.168.122.176 worker2-k8s web.local
```
Verificare su quale porta NodePort risulta associata la porta 80 dell'ingress controller:
```
k -n ingress-nginx get all
NAME                                            READY   STATUS    RESTARTS      AGE
pod/ingress-nginx-controller-58954d6d98-xnsgr   1/1     Running   2 (26m ago)   13h

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.111.171.151   <none>        80:30861/TCP,443:31431/TCP   13h
service/ingress-nginx-controller-admission   ClusterIP   10.108.70.79     <none>        443/TCP                      13h

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           13h

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-58954d6d98   1         1         1       13h
```
Verifica con curl:
```
curl http://web.local:30861
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### 6. Resource Quota + WordPress (quota-ns)
**Obiettivo:**

Creare di una resource quota per un WordPress impostando la request CPU a 500 millicore, la request memory a 512 MB, 1 CPU come limit e 1 GB come limit memory.
Assicurarsi che l'applicazione, in replica 3, abbia un pod di replica su ogni nodo.

**Preparazione:**
```
k apply -f 06.quota-ns/quota.yaml
```
**Risoluzione:**

Ci sono due deployment nel namespace:
```
k -n quota-ns get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
mysql       3/3     3            3           19d
wordpress   3/3     3            3           19d
```
Editare il deployment wordpress:
```
[...]
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - wp
        topologyKey: "kubernetes.io/hostname"
```
Scalare il deployment prima a zero e poi a 3:
```
k -n quota-ns scale deployment wordpress --replicas=0
k -n quota-ns scale deployment wordpress --replicas=3
```

Editare il deployment mysql:
```
[...]
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            -  mysql
        topologyKey: "kubernetes.io/hostname"  
```
Scalare il deployment prima a zero e poi a 3:
```
k -n quota-ns scale deployment mysql --replicas=0
k -n quota-ns scale deployment mysql --replicas=3
```
Impostare i limiti e le requests:

```
kubectl -n quota-ns create quota wordpress-quota --hard=requests.cpu=500m,requests.memory=512Mi,limits.cpu=1,limits.memory=1Gi

kubectl describe quota wordpress-quota -n quota-ns
Name:            wordpress-quota
Namespace:       quota-ns
Resource         Used   Hard
--------         ----   ----
limits.cpu       500m   1
limits.memory    512Mi  1Gi
requests.cpu     250m   500m
requests.memory  256Mi  512Mi
```

Verificare l'allocazione dei pod:

```
k -n quota-ns get po -o wide
NAME                        READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
mysql-64cb4856c8-7657n      1/1     Running   0          3m27s   10.10.195.5    worker1-k8s   <none>           <none>
mysql-64cb4856c8-7pc88      1/1     Running   0          3m27s   10.10.7.235    worker2-k8s   <none>           <none>
mysql-64cb4856c8-xv586      1/1     Running   0          3m27s   10.10.159.37   worker3-k8s   <none>           <none>
wordpress-64c6598f7-gtx6k   1/1     Running   0          8m38s   10.10.7.214    worker2-k8s   <none>           <none>
wordpress-64c6598f7-kkfpt   1/1     Running   0          8m38s   10.10.195.50   worker1-k8s   <none>           <none>
wordpress-64c6598f7-m7g8p   1/1     Running   0          8m38s   10.10.159.22   worker3-k8s   <none>           <none>
```

### 7. PVC + Pod (pvc-ns)
**Obiettivo:**

Creazione di un PVC wp-pvc da 1GiB e associazione ad un pod Nginx. Creare anche un PV corrispondente (di tipo hostPath).

**Risoluzione:**

Creare il PV: 

07.pv.yaml
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wp-pv 
  namespace: pvc-ns
spec:
  capacity:
	storage: 1Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /usr/share/nginx/html  
```

Creare il PVC:
07.pvc.yaml
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pvc
  namespace: pvc-ns
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Create il manifest YAML per il pod:
```
k -n pvc-ns run pvc-pod --image=nginx --dry-run=client > 08.pod.yaml
```
Editare il file 08.pod.yaml aggiungendo le seguenti righe:
```
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
  namespace: pvc-ns
spec:
  containers:
  - name: pvc-pod
    image: nginx
    resources: {}
    volumeMounts:                          # ADD
    - mountPath: "/usr/share/nginx/html"   # ADD
      name: html                           # ADD
  volumes:                                 # ADD
  - name: html                             # ADD
    persistentVolumeClaim:                 # ADD
      claimName: wp-pvc                    # ADD
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```
Verifica:
```
kubectl get pvc -n pvc-ns
kubectl get pod pvc-pod -n pvc-ns
```
### 8. Sidecar Container (sidecar-ns)
**Obiettivo:**

Creazione di un side-container in un pod. Creare un pod sidecar-pod con due container con immagine busybox:1.28: il primo chiamato main-app che esegua il comando
"while true; do echo 'main running' >> /var/log/main-app.log; sleep 10; done" e il secondo sidecar che esegua il comando "tail -n+1 -f /var/log/main-app.log". 

**Risoluzione:**
```
k -n sidecar-ns run sidecar-pod --image=busybox:1.28 --dry-run=client -o yaml > 08.pod.yaml
```
Editare 08.pod.yaml:
```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: sidecar-pod
  name: sidecar-pod
  namespace: sidecar-ns
spec:
  containers:
  - image: busybox:1.28
    name: main-app                     										 								# CHANGE
    command: [ "sh", "-c", "while true; do echo 'main running' >> /var/log/main-app.log; sleep 10; done" ] 	# ADD 
    volumeMounts:                                             # ADD
    - name:                                                   # ADD
      mountPath: /var/log                                     # ADD
  - image: busybox:1.28																						#  ADD
    name: sidecar																							# ADD	
    command: [ "sh", "-c", "tail -n+1 -f /var/log/main-app.log" ]    										# ADD
    resources: {}
    volumeMounts:																							# ADD
    - name: shared-logs																						# ADD
      mountPath: /var/log																					# ADD
  volumes:																									# ADD			
  - name: shared-logs																						# ADD
    emptyDir: {}     																						# ADD
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
Creare il pod:
```
kubectl apply -f 08.pod.yaml
```
Check:
```
kubectl get pods -n sidecar-ns
NAME              READY   STATUS    RESTARTS   AGE
pod/sidecar-pod   2/2     Running   0          5s

k -n sidecar-ns logs pods/sidecar-pod -c sidecar
main running
main running
main running
[...]

k -n sidecar-ns exec -it pod/sidecar-pod -- cat /var/log/main-app.log
Defaulted container "main-app" out of: main-app, sidecar
main running
main running
main running
[...]
```

### 9. HTTP Gateway (gateway-ns)
**Obiettivo:**

Creazione di un HTTPGateway e associazione ad un pod. Nel namespace gateway-ns è presente un deployment nginx-welcome, un service, una configmap e un ingress TLS. Esporre l'applicazione
utilizzando un gateway sulla porta 80 e creare un HTTPGateway. Utilizzare l'hostname mygateway e per la configurazione del TLS utilizzare la stessa dell'ingress.

**Prequisito:** NGINX Gateway Fabric installato sul cluster Kubernetes.

**Risoluzione:**
Per il traffico HTTP ruotato da un service utilizzando un Gateway a una HTTPRoute avremo:
```
client--->(HTTP Request)--->Gateway--->HTTPRoute--->(Routing rule)--->Service|--->POD
									                                         |--->POD
```
Verificare quali sono le CRD gateway installate:
```
k get crd | grep -i gateway
clientsettingspolicies.gateway.nginx.org              2025-09-15T15:36:27Z
gatewayclasses.gateway.networking.k8s.io              2025-09-15T15:36:18Z  
gateways.gateway.networking.k8s.io                    2025-09-15T15:36:18Z 
grpcroutes.gateway.networking.k8s.io                  2025-09-15T15:36:18Z
httproutes.gateway.networking.k8s.io                  2025-09-15T15:36:19Z 
nginxgateways.gateway.nginx.org                       2025-09-15T15:36:27Z
nginxproxies.gateway.nginx.org                        2025-09-15T15:36:27Z
observabilitypolicies.gateway.nginx.org               2025-09-15T15:36:28Z
referencegrants.gateway.networking.k8s.io             2025-09-15T15:36:19Z
snippetsfilters.gateway.nginx.org                     2025-09-15T15:36:28Z
upstreamsettingspolicies.gateway.nginx.org            2025-09-15T15:36:28Z
```
Non occorre creare una gatewayclass in quanto risulta già installata:
```
k get gatewayclasses.gateway.networking.k8s.io -A
NAME               CONTROLLER                                   ACCEPTED   AGE
nginx              gateway.nginx.org/nginx-gateway-controller   True       5d1h
```
Creare un API gateway con un listener sulla porta 80: 

09.gateway.yaml
```
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: gateway-ns
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
      	from: Same
    hostname: mygateway.local
  - name: https
    protocol: HTTPS
    port: 443
    allowedroutes:
      namespaces:
        from: Same 
    tls:
      mode: Terminate
      certificateRefs:
      - name: ingress-web
        kind: Secret
   
```
Creare il Gateway:
```
k apply -f 09.gateway.yaml
```
Creare un HTTPRoute con una route su / per l'applicazione Nginx:

09.httproute.yaml
```
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-httproute
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - "mygateway.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx-welcome
      port: 80

```
Creare l'HTTPRoute:
```
k apply -f 09.httproute.yaml
```
Check:

Verificare su quale porta è in ascolto il service dell'NGINX Gateway:
```
k -n nginx-gateway get all
NAME                                READY   STATUS    RESTARTS       AGE
pod/nginx-gateway-96f76cdcf-9m8pw   2/2     Running   19 (35m ago)   6d

NAME                    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/nginx-gateway   NodePort   10.101.105.162   <none>        80:30525/TCP,443:30683/TCP   6d

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-gateway   1/1     1            1           6d

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-gateway-96f76cdcf   1         1         1       6d
```
Dopo aver aggiunto l'hostname mygateway.local al file /etc/hosts:
```
curl -kL https://mygateway.local:30683
<html>
  <head><title>Welcome</title></head>
  <body>
    <h1>Welcome to Gateway</h1>
  </body>
</html>
```


### 10. Cert-Manager + Self-Signed Cert (cert-ns)
**Obiettivo:**

Installare CertManager alla versione 1.14.4 comprese le CRDs. In seguito:
 * a. Creare un certificato self-signed.
 * b. Creare un certificato firmato da una Root CA.

**Risoluzione:**
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
```
Verificare la presenza della versione richiesta:
```
helm search repo jetstack/cert-manager --versions | grep grep v1.14.4
```
Installare l'Helm Chart:
```
helm install cert-manager jetstack/cert-manager --namespace cert-ns --version v1.14.4 --set installCRDs=true
```
Check:
```
k -n cert-ns get all
NAME                                           READY   STATUS    RESTARTS   AGE
pod/cert-manager-7c4b5b58df-pmjgf              1/1     Running   0          3m21s
pod/cert-manager-cainjector-7bf5c557bb-78clv   1/1     Running   0          3m21s
pod/cert-manager-webhook-596c6cdc7b-gjdjr      1/1     Running   0          3m21s

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/cert-manager           ClusterIP   10.105.153.68   <none>        9402/TCP   3m21s
service/cert-manager-webhook   ClusterIP   10.105.54.83    <none>        443/TCP    3m21s

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cert-manager              1/1     1            1           3m21s
deployment.apps/cert-manager-cainjector   1/1     1            1           3m21s
deployment.apps/cert-manager-webhook      1/1     1            1           3m21s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/cert-manager-7c4b5b58df              1         1         1       3m21s
replicaset.apps/cert-manager-cainjector-7bf5c557bb   1         1         1       3m21s
replicaset.apps/cert-manager-webhook-596c6cdc7b      1         1         1       3m21s
```

Dopo l'installazione sono disponibili le seguenti API resources:
```
k api-resources  | grep cert
challenges                                           acme.cert-manager.io/v1             true         Challenge
orders                                               acme.cert-manager.io/v1             true         Order
certificaterequests                 cr,crs           cert-manager.io/v1                  true         CertificateRequest
certificates                        cert,certs       cert-manager.io/v1                  true         Certificate
clusterissuers                                       cert-manager.io/v1                  false        ClusterIssuer
issuers                                              cert-manager.io/v1                  true         Issuer
certificatesigningrequests          csr              certificates.k8s.io/v1              false        CertificateSigningRequest
```

Per generare un certificato: 
```
k explain cert
GROUP:      cert-manager.io
KIND:       Certificate
VERSION:    v1

DESCRIPTION:
    A Certificate resource should be created to ensure an up to date and signed
    X.509 certificate is stored in the Kubernetes Secret resource named in
    `spec.secretName`.
     The stored certificate will be renewed before it expires (as configured by
    `spec.renewBefore`).

FIELDS:
  apiVersion    <string>
    APIVersion defines the versioned schema of this representation of an object.
    Servers should convert recognized schemas to the latest internal value, and
    may reject unrecognized values. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

  kind  <string>
    Kind is a string value representing the REST resource this object
    represents. Servers may infer this from the endpoint the client submits
    requests to. Cannot be updated. In CamelCase. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

  metadata      <ObjectMeta>
    Standard object's metadata. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata

  spec  <Object>
    Specification of the desired state of the Certificate resource.
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

  status        <Object>
    Status of the Certificate. This is set and managed automatically. Read-only.
    More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
```
*a.*
Creare prima un ClusterIssuer quindi un Certificate self-signed:

10.clusterissuer.yaml
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}


kubectl apply -f 10.clusterissuer.yaml
```

Quindi il certificato:

10.certificate.yaml
```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-cert
  namespace: cert-ns
spec:
  dnsNames:
  - example.com
  secretName: my-cert-tls
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: ClusterIssuer
```

Creare il certificato:

```
kubectl apply -f 10.certificate.yaml
```
Verifica:
```
k -n cert-ns describe certificate my-cert

Name:         my-cert
Namespace:    cert-ns
Labels:       <none>
Annotations:  <none>
API Version:  cert-manager.io/v1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2025-10-11T10:03:48Z
  Generation:          2
  Resource Version:    900628
  UID:                 4bfdbdca-aebf-4c6b-9048-3d41ebdaed50
Spec:
  Dns Names:
    example.com
  Issuer Ref:
    Kind:       ClusterIssuer
    Name:       selfsigned-cluster-issuer
  Secret Name:  my-cert-tls
Status:
  Conditions:
    Last Transition Time:  2025-10-11T10:09:23Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   2
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2026-01-09T10:09:22Z
  Not Before:              2025-10-11T10:09:22Z
  Renewal Time:            2025-12-10T10:09:22Z
  Revision:                1
Events:
  Type    Reason     Age                    From                                       Message
  ----    ------     ----                   ----                                       -------
  Normal  Issuing    7m44s                  cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  7m43s                  cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "my-cert-cbqnn"
  Normal  Requested  2m10s (x2 over 7m43s)  cert-manager-certificates-request-manager  Created new CertificateRequest resource "my-cert-1"
  Normal  Issuing    2m10s                  cert-manager-certificates-issuing          The certificate has been successfully issued

```
```
k -n cert-ns get certificate
NAME      READY   SECRET        AGE
my-cert   True   my-cert-tls   8m36s

k -n cert-ns get secret my-cert-tls -o yaml

apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN4VENDQWEyZ0F3SUJBZ0lRRE5iNTF1RHJyZzFSWUtWUXRtUlVDVEFOQmdrcWhraUc5dzBCQVFzRkFEQUEKTUI0WERUSTFNVEF4TVRFd01Ea3lNbG9YRFRJMk1ERXdPVEV3TURreU1sb3dBRENDQVNJd0RRWUpLb1pJaHZjTgpBUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS3FhbXRLU0dCMU9tVURtM01hcGN6NnlqTk9vL2FzSEtuakF4R0NJCm8xZHlwOU1UcWhrZjFWOGtXMEdjK0JzUloxSGF1ejFQeGI5MVVmSmRiK1NGQmhYd2NpWE5MYzNyeGs4Nk1nSE8KdkVIVUY4Y2VxekREQzlIWWJPVW1lL0p6ZmMwNGszU1dPTDQ0MkxiZjQ0djdJcS9qY2w1RVdIK1Jsc2RiR09TQgpybDBqcWt1VS9XanpyQ1RMTTUyVnZYZHBjbk8xSmdhR3BuOThNNUExN0haUFZ5Z3RMaGZvSm5WM2V2YUtNZjJNCkhuZ2U2T0UydXJSYmExamc5QXNHaUJkam5sSWFiOStXN1dUdTdCUDgvTEdLZlp0STU1QmRQMVNwd21NazBicmEKZmQzdDU5RzFsSnNpQWQ5Tm9uWVQ1ZVhpWkJtT3J0MjZMQTBUdmVhSVlMbTNVeE1DQXdFQUFhTTdNRGt3RGdZRApWUjBQQVFIL0JBUURBZ1dnTUF3R0ExVWRFd0VCL3dRQ01BQXdHUVlEVlIwUkFRSC9CQTh3RFlJTFpYaGhiWEJzClpTNWpiMjB3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUVycFF5QnIxcEM2ZCt5OWJFaHIxS0RiblRNSEIxSlgKdUVnaXhIS0NoTnFFUjlZRTViaDVoZ2t5TDk0bTNhajgxK3ozWmF2ZE9TWE14d0FNWkZncHF1T3lFV1NLTkJNKwpheWlYU2o3VUYxNjBoc0RtV0t5NFpCemQxSTdnckt1TnJzK1AvRDE2eWlkYk5PdnR6ZmdzaFlYTHR0c1QwUk1tCnZhLzBDQzhIL2FVdXBFSEw3Nm1obm1vZmFWd0RkeE5CUk5OMW1uOWxKYXc5ZDd4SjlCYTZDYUliS0FMYnNaYkwKUWt6aXFUZFowdWFlZXhpTFFlckJRYXR0THNFcjNPc2xBdU8yNG5SYng1Y2tuL1hoOUNVYzhEVTdsVTEvbk5aSwp4MXBOZUFpa0pDZmhyczM0Q0c4ckVtZlluMUw5ZmdIcEVKWlhseTgxNG5NQ1lqNWVvd2l2RTNFPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN4VENDQWEyZ0F3SUJBZ0lRRE5iNTF1RHJyZzFSWUtWUXRtUlVDVEFOQmdrcWhraUc5dzBCQVFzRkFEQUEKTUI0WERUSTFNVEF4TVRFd01Ea3lNbG9YRFRJMk1ERXdPVEV3TURreU1sb3dBRENDQVNJd0RRWUpLb1pJaHZjTgpBUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS3FhbXRLU0dCMU9tVURtM01hcGN6NnlqTk9vL2FzSEtuakF4R0NJCm8xZHlwOU1UcWhrZjFWOGtXMEdjK0JzUloxSGF1ejFQeGI5MVVmSmRiK1NGQmhYd2NpWE5MYzNyeGs4Nk1nSE8KdkVIVUY4Y2VxekREQzlIWWJPVW1lL0p6ZmMwNGszU1dPTDQ0MkxiZjQ0djdJcS9qY2w1RVdIK1Jsc2RiR09TQgpybDBqcWt1VS9XanpyQ1RMTTUyVnZYZHBjbk8xSmdhR3BuOThNNUExN0haUFZ5Z3RMaGZvSm5WM2V2YUtNZjJNCkhuZ2U2T0UydXJSYmExamc5QXNHaUJkam5sSWFiOStXN1dUdTdCUDgvTEdLZlp0STU1QmRQMVNwd21NazBicmEKZmQzdDU5RzFsSnNpQWQ5Tm9uWVQ1ZVhpWkJtT3J0MjZMQTBUdmVhSVlMbTNVeE1DQXdFQUFhTTdNRGt3RGdZRApWUjBQQVFIL0JBUURBZ1dnTUF3R0ExVWRFd0VCL3dRQ01BQXdHUVlEVlIwUkFRSC9CQTh3RFlJTFpYaGhiWEJzClpTNWpiMjB3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUVycFF5QnIxcEM2ZCt5OWJFaHIxS0RiblRNSEIxSlgKdUVnaXhIS0NoTnFFUjlZRTViaDVoZ2t5TDk0bTNhajgxK3ozWmF2ZE9TWE14d0FNWkZncHF1T3lFV1NLTkJNKwpheWlYU2o3VUYxNjBoc0RtV0t5NFpCemQxSTdnckt1TnJzK1AvRDE2eWlkYk5PdnR6ZmdzaFlYTHR0c1QwUk1tCnZhLzBDQzhIL2FVdXBFSEw3Nm1obm1vZmFWd0RkeE5CUk5OMW1uOWxKYXc5ZDd4SjlCYTZDYUliS0FMYnNaYkwKUWt6aXFUZFowdWFlZXhpTFFlckJRYXR0THNFcjNPc2xBdU8yNG5SYng1Y2tuL1hoOUNVYzhEVTdsVTEvbk5aSwp4MXBOZUFpa0pDZmhyczM0Q0c4ckVtZlluMUw5ZmdIcEVKWlhseTgxNG5NQ1lqNWVvd2l2RTNFPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBcXBxYTBwSVlIVTZaUU9iY3hxbHpQcktNMDZqOXF3Y3FlTURFWUlpalYzS24weE9xCkdSL1ZYeVJiUVp6NEd4Rm5VZHE3UFUvRnYzVlI4bDF2NUlVR0ZmQnlKYzB0emV2R1R6b3lBYzY4UWRRWHh4NnIKTU1NTDBkaHM1U1o3OG5OOXpUaVRkSlk0dmpqWXR0L2ppL3NpcitOeVhrUllmNUdXeDFzWTVJR3VYU09xUzVUOQphUE9zSk1zem5aVzlkMmx5YzdVbUJvYW1mM3d6a0RYc2RrOVhLQzB1RitnbWRYZDY5b294L1l3ZWVCN280VGE2CnRGdHJXT0QwQ3dhSUYyT2VVaHB2MzVidFpPN3NFL3o4c1lwOW0wam5rRjAvVktuQ1l5VFJ1dHA5M2UzbjBiV1UKbXlJQjMwMmlkaFBsNWVKa0dZNnUzYm9zRFJPOTVvaGd1YmRURXdJREFRQUJBb0lCQUh4SEpiTnhRMm5PQU92NwpnU2FpOTlYYmdhVUtmTWVpNzdpSlRFUzZKS3NtVmNUNGxUZTZMZGdpQnV3MEtiU21KK3JEK1JQLzBhRFlHUHNDClArbHJVZlNYZEwrK3lMZ3lJZ05DOUh6R21mTW1TcS85MGwweUtLRVVGTGVWSWtPTENFQ0FEMEtseis0YVFSeHUKMmpiMW1kNGhSUVlRcVpzOGRtY0JJSkFOTy9TU1B1d0hFb2p3RFVxTUlzYlhFQS9HZHdZZmVqdkRpWWVBbnRrWQp2aFM4WlNoTWpGUUZFZE40L0J3RnY3TVQ1QUtDdHd4TXpXWXN1VkY4WmZSSlBSMlJEckxGNTN4SjVOV3o4NjFTCmFwYkpKSEtuTW9FOUdkQnE1Ymh0dzZ4VHoxeTJNeEpJQUdyeTQxakhrZHdhQWJmNHlDd2NhR1dJN2l1SC9LYlEKM29XekVSRUNnWUVBMkNpTzhNZmR1VVFLWHp5ZjFvTVVPZHZqTWxRS1BlaHUzd0ZncXo0aWxkMElldGl1YWhqLwo3TnpPUzNuemZlRlZ3RFUyaWw0L3lWelpQQ0FnQm5XZXRRS1Q0K2dORnNZN2tSZmNESFdUcVRPbjNRU09MQVBKCk9vVGxFc0tqZkVndTlwYVFWekFDTXd3L3V5M3RBSy9ETmgyZGtESVB0NGMydGhJbWIyd2tDSHNDZ1lFQXlneU8KUmxQQ09mZTVFRFNvaXBBODdQdGZqK2pVRXg3allvQllyQmo2M3RYOWVNb3o0Q3JpRllrSFVuMVYxRDNYNURJVgp4S2dqcFkzOHVwRjNyVWdrc05ZT1oxenlsWS9MYmhGVi81OXpwcnhIbThQRUtiZDVrYkNwYWcxZkxUV2xTbGF2CmlNNk12YVBncGRrTlJTRzdWVndmS3hHRk5kK0E2cVRUdy8vaU9Fa0NnWUJ4M292T1U3dDl5VllkYlhaV0xwOE4KQzhUWDBtWEN6eHI0NTJUaFVNNHZYRTBIU2ZZM2RndjczeVhkcE5TY1Q0UTR5TTkrZkwvbGQ4QUlhSFAyY3llegorek9sTDYwVmZrQUs0eUxNZlhQWUFwby9XQkw5Sk5Gd3ZtbGVSS0tTNmdPemF3V0dxSWZBRklmT054ZE84VWhJCnpia2ZLUUFXa21oRDZiUE5wbzRrMlFLQmdRQ3lVQzVuNXBlczdQRUlXbEM4S050OEVjU2VqczVMS2FGblZ2bnEKdUFqL0REK3NrRmNENlJTcUNNckxoQTF4U0RyMkN6V20zdlRHc081d0FOMXJzaFdmY3VvM1VwSk1hQ0VTdkgzMwpJTlBDUEx1OXZpR3E1MStFc2pKeGcrZVJVSnpWWkhkNTl6L0NSWlNIQ1cxcXE0QldydnhhMkJXR0cvLzhGUWRICkhOYWE4UUtCZ1FDczdySXcwWDNLZjBXS28rN1ZVOHp5M0YwbzA4bjVUcUZOYmtmQTlaMmx0OFR1VjRrVndZTDgKSW5uazd5R1lhVytyamE4TlA1Wlg4RnZCaXhBcnVEMkVmUmZ2MVB3KzFSZWJEcXJVTlVvNXVxdGFnbUZzakRnNAo5NHlORWIrSjFsZzc4ZXRWQ0lOQ3pRT3JFOEV1OHdNWGcrS0U3c0V0NVRIN3dCcjBPZStUOFE9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: example.com
    cert-manager.io/certificate-name: my-cert
    cert-manager.io/common-name: ""
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: ""
    cert-manager.io/issuer-kind: ClusterIssuer
    cert-manager.io/issuer-name: selfsigned-cluster-issuer
    cert-manager.io/uri-sans: ""
  creationTimestamp: "2025-10-11T10:09:22Z"
  labels:
    controller.cert-manager.io/fao: "true"
  name: my-cert-tls
  namespace: cert-ns
  resourceVersion: "900622"
  uid: 77ff1426-4acc-46b7-8e01-a990e9800dcc
type: kubernetes.io/tls


k -n cert-ns get secret my-cert-tls -o jsonpath='{.data.tls\.key}' | base64 -d
-----BEGIN RSA PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDVsky28C/s0rXT
ZlLPjkYjHm/r64nzG+tWxAyDXg/XQ9aPbomnqd7n4+o+0Of8uNtzsOGaeEtpfze1
ExKsN+BSXpWBQ+S91H1fkbi0DsdH6BZ9g5vWWUxzRjaLTSz02EdgavF4erKZN8Ov
dzcrVjbYGe0Nxfq3B02LRZCbGgsx8Vz2VbSeWCk8EKmkkvbFK+kgHr18OHdng7l1
RoD0svCx8Q/9s5PCwVTtc74NnAOxA4dfuG0637MGjy4TtK8muYgyhlSuh2gN5WTt
XBxRvmB7Vk3imsFVFV9S8ZiUjvcCTbe0mhGd2cY1PMQ+5s6DWaUsx5hyI4O1cY6N
5vBjLREnAgMBAAECggEAKv7e1Ifq/JlAoDIcQ0p67iH3nt4bOWDKrwBvDBdm1Ib/
qogxBhz1jm6a+NyLcJu4+8QBAFVnxugjyzj1LtVnOutw5TtF0LPqLcpiAUhf7CXU
MJjESBJbgW4FF24Ft5W0dr/NqdH2EUHZC3rPDNch3cUJnxXQZfcAMR9kAvDwg7GP
5swhd/NWrcsNd1URAu7zKUYPvrZeKIl7s5/MN/DY/lLcJXq/+Hkb17jF3RVuhwH0
at1YiOTUf3kFDrITWfwMHWzeaL58gVn8Q9ukCvaPpD3Yx6cabCYFvJEUJlDXLjLP
TDtQHFal7WfYQ4Ip51JdNtpLG5QC3vFV1DPKamxvEQKBgQDWATgp+hc3lyw7FOjj
LhDiRICyH5KkajOQG9YlkiR2DmRtnOUFY0t/cGlB7ROJ+bV4Gdbf4ijpW5sCFd/i
nXJ0UDQYd9UpMaZxRl/zM74Hdg6MwwBnx0/dyfzLy6KulsBffwBlGr5//sNiIK8Y
SCFPT5n5kjDQetwZKxu59PdsNQKBgQD/oZfs9IlZEBDT77eVFc44l/QR3sMBuN1M
7yJ4C8C+mxZkAxhNnwCkRqEmUVDrKoBavaJtgIawu9CiCZMPefOrwThDBCmLAdya
7lDZRd345zKcjmJvPCTpRlk8n9KWfDXBiEtZWNiFnp49DIDWn+/8iJRJEKgjvKg8
oHY0LJxbawKBgCQ3cpzQASvcPpUFFeCUhDD2rNz4MOX4Px+tRlF3aQo9p0tRmQSP
aFB54qZQi9T22HopzU54RLoxUYtJzmjYgm0iwZ4+cWmWSHe1FDnhUNCMbyvtOF1X
wrFjJJAMt0xaoNXIdXWm0ARzRfeOVnOCiXiVnRY6Yl513Fe6Dugqh9DdAoGBAJ1H
TPQrWD4F1nSvLqJ5chH7290K06xBk1b8Ypa9lG8xeEs8ZD2NsJViJ1AuA71MvwAV
YNRCmZwvUiQABA0nmTZ5gSYqb2zpTlO8gN3NUM8NYGRWblXGCWfFMq5MHwMblO9n
7gQg18cOWolxIevrJ3qWhbWWm/yw3EnA6DkdoW3VAoGBAK/yah1gKIG1E8TrDEem
8Qv0ILAtLH8PPydEJ5AhHKHW2LR7cp3yf4Y4XjHrplVfKhdTPmHa6xUU0Noa/xPX
OE/3jGgZa4TV4Ibj68CTxdNoXM9tu7nXjVpQeWnja4wdUAl30BLRm0OLPWAaferI
KWaFJbwPa+6zsf6i30qTmfNl
-----END RSA PRIVATE KEY-----
```
Verifica sui secret:

```
k -n cert-ns  get secret
NAME                                 TYPE                 DATA   AGE
cert-manager-webhook-ca              Opaque               3      130m
my-cert-tls                          kubernetes.io/tls    3      8m58s
sh.helm.release.v1.cert-manager.v1   helm.sh/release.v1   1      131m

```

*b.* Per avere un certificato firmato da una Root CA self-signed occorrono:
 * 1b. una Root CA self-signed
 * 2b. un Issuer CA che usa la root CA
 * 3b. un certificato firmato dalla CA


1b. Creare una Root CA self-signed:
[https://cert-manager.io/docs/configuration/selfsigned/#bootstrapping-ca-issuers]

10.rootca.yaml
```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: cert-ns
spec:
  isCA: true
  commonName: "root-ca"
  secretName: root-ca-tls
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: ClusterIssuer

k apply -f 10.rootca.yaml
```
2b. Per poter emettere certificati è necessario prima configurare una risorsa Issuer o clusterIssuer.
Creare un issuer che usa la Root CA. 

10.issuerca.yaml
```
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: my-ca-issuer
  namespace: cert-ns
spec:
  ca:
    secretName: root-ca-tls

k apply -f 10.issuerca.yaml
```
3b. Creare un personal certificate firmato dalla Root CA:

10.mycertificate.yaml
```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-certificate
  namespace: cert-ns
spec:
  dnsNames:
  - example.com
  secretName: my-certificate-tls
  issuerRef:
    name: my-ca-issuer
    kind: Issuer

k -n cert-ns get secrets my-certificate-tls -o yaml
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM4VENDQWRtZ0F3SUJBZ0lSQUpsVjdxVEYyT01zVjFoQzRUSlN6S2t3RFFZSktvWklodmNOQVFFTEJRQXcKRWpFUU1BNEdBMVVFQXhNSGNtOXZkQzFqWVRBZUZ3MHlOVEE1TWpJeE5UVXpOVGRhRncweU5URXlNakV4TlRVegpOVGRhTUJJeEVEQU9CZ05WQkFNVEIzSnZiM1F0WTJFd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFEelU2cXVITmRkcEpaMjJQeHdyTkxwU0pQSzRHZzJjWDN4SUppSitLdWx4ck1TK085QzNJUi8KaXFUS1RsbG8zZHRKbHJHSjVYR0lrSHBYMmxaQS9FRDMrNU9Pc1BITXhwQ29DM2dDQzBURnFtQmg1U2Q2U1pBKwpGSWl2Nmo4Vi8zaTVHVVN4STd5MVZKN2lZRnBhUjZoYTdkT3R5VlZ1cCs3M3ZPUzZDOGZ1dkM3QlgrTXJVczRKCnpFSTFVd3pqMC9lQ1JZVDRLV1Y0NitRdDRBc052STNkdHl4SWZRWGkwQ0J0YjRCUkozK2pXUC9UVmdOTjFwSmUKclJqbmdXaG1QK1krNVJoMWE1NmxtckcxVHNBRlEzbm1SdkJrUGZpOElZTUtrQ3RrbE1Oc0NaU0hvRmREYVVvaApNM1JqWkdxZFJmNXVPZ29RWUFiNVdQUlAyZStBZmcyOUFnTUJBQUdqUWpCQU1BNEdBMVVkRHdFQi93UUVBd0lDCnBEQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCUmMyREtkTXUreVZKQnlyNHdpd1kvZUJzUDkKVURBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQXBObVlia2RhekpoYmcvK0R4ZW5SaVpBNHFlS0FPS3pVZjRqcAo0UGk1N0psaStrRmQ1MXV6T3N3M2szNE1MYTdLSkZHY0U2R1BwWkVSNHBHcm9IK2g0Ymh0WFlxRmp4Yks4eEdDCnhBYzRvR2pjaTZ3WThzU2tMT1haZEcrVkduNk11QWFXM1pXSHVLbzczMXgxd1FYc0RHWittb3VTNjRkVlM3elAKcmY2TFVzazFOZ0kxRTRiV2ZsMmljRXg5bnoxVlFuWFJ4V2t2Sk5Bb1FPUXVHVko4SnkxWjQzL0RFUWZ4WjdsWgpaekJLWStyelN0S0J2VGNDNXFKUk13Sy9xVnNwci85ZjVndlNNL2xMdzA4Smg3NTNtcFdtL3J2OWVFWU11R0dmCk9pSDRvVjNwdk1NK2FEMTd3SnVIdGVDNlpwZCtJaWpJb2xTMWJUOFhFS2dxaDFYV2ZRPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMrVENDQWVHZ0F3SUJBZ0lSQUt2UGtnOXRtR2dQWXJ5WWtPVi91Y1F3RFFZSktvWklodmNOQVFFTEJRQXcKRWpFUU1BNEdBMVVFQXhNSGNtOXZkQzFqWVRBZUZ3MHlOVEE1TWpJeE5UVTBOVFJhRncweU5URXlNakV4TlRVMApOVFJhTUFBd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUM3bnkwOWRUQXJpbGVrCkRXK3ZCRWc0c09BVHJMTTc5LzV4Zk51b0I3Mk5GZDU5eXIyUDNsSnhVSTA3bVo3S1N3YmhUY3F4ODNuN01CZXkKM2xmcFRpQWFEbFJMeUYzd0pKdlhaVDU3YUhNdVdpNFgyMU43ZWFTRDZEeUlsV2tXdVlXTUxuOFpuZ3V1REtQdgpIS0JiaGw0MjRlUXRpZ0xYTHYzWDJaRzFPcDJYY2tIRGRTd0U0bFh0UElyMzhyY0xMOHNQRXpiRWRGK012M0xaCjNaZCtxcDJNZmJMTDI4TkNWdEptL0ZMcXhpcVdlSmhYVHZJbFFWOVVMOGt6OE5Sa21FQlVrZUxxYmFRTnJWdVcKbVQ0N0VOUDhoaDc3NVNXRUpnRDAyNG5BR0ZwenpJTVlSWU1HTFFtM0RVQUZWUkNjRE1YWmxQTHAzWVVoZkVqVwp6VjBvczZsdkFnTUJBQUdqWERCYU1BNEdBMVVkRHdFQi93UUVBd0lGb0RBTUJnTlZIUk1CQWY4RUFqQUFNQjhHCkExVWRJd1FZTUJhQUZGellNcDB5NzdKVWtIS3ZqQ0xCajk0R3cvMVFNQmtHQTFVZEVRRUIvd1FQTUEyQ0MyVjQKWVcxd2JHVXVZMjl0TUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDS0FndVl1N2pMR3MwamUySllhVDA3aDNOdwpvTnkxTXBKdWpjZFJHTFk1QTY4OHhlNHdJQzRMWkpUNko1Y0hKdytTbWdJbW5YQ1VadS9BSjdZRnhWV1g4WHBaCjdZT3pFMEhrcTNZcnFIUk5FRHoyakorNVFOMjdxSUh3K1llK1JmTDBMOWYwZ0wxTXRrbDNzN096M0lnak1xR3UKaVJiZWVlODNhY2V0WU9uYmluamk0VHhhSEVEanlicVAyS3NnMzJMNEVpQUFiSzcyU3lmZENPN2s2Q3E3R3BnbwppS2k2emREQmZqMjYrTHdYVlVEWFhUdjloUVlQOHRhTk5YNmlTc0VZR0NCT0dzWkcxTXVBR21WbUp1cDdPU1gvCi9iSDllRzdBa2swbEowMHNQRXpwWnM0MHBoeGNTWUtVUjN1WC9kay8yYWp3MzE1dzgwaXIzQ0pKL0Z1QwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb2dJQkFBS0NBUUVBdTU4dFBYVXdLNHBYcEExdnJ3UklPTERnRTZ5ek8vZitjWHpicUFlOWpSWGVmY3E5Cmo5NVNjVkNOTzVtZXlrc0c0VTNLc2ZONSt6QVhzdDVYNlU0Z0dnNVVTOGhkOENTYjEyVStlMmh6TGxvdUY5dFQKZTNta2crZzhpSlZwRnJtRmpDNS9HWjRMcmd5ajd4eWdXNFplTnVIa0xZb0MxeTc5MTltUnRUcWRsM0pCdzNVcwpCT0pWN1R5SzkvSzNDeS9MRHhNMnhIUmZqTDl5MmQyWGZxcWRqSDJ5eTl2RFFsYlNadnhTNnNZcWxuaVlWMDd5CkpVRmZWQy9KTS9EVVpKaEFWSkhpNm0ya0RhMWJscGsrT3hEVC9JWWUrK1VsaENZQTlOdUp3QmhhYzh5REdFV0QKQmkwSnR3MUFCVlVRbkF6RjJaVHk2ZDJGSVh4STFzMWRLTE9wYndJREFRQUJBb0lCQUNSanVCdU9haHhYeGEzTQo2VmR4cGl4UXFmVkc3ckIzNWdMTzY2K0lhTXcvYkpyTFFyN3ZxTi9QZHNVVGc0Zkt5M2ZSWmJuajlrbXd4emZyCkJmUDdNaUM3bkwvaUNjNDAyNEVJWXZqK2hqQjhUeXBUWUxxM0dpQjNYNTVDRkZMVEFzTHdsYmc3UGhxdzJ1N2EKaDRPWTZSY044dnFlSlBUbGFWaC9HMUtpSHNTcmtHLzA2TGVkWG9hN0tRSFdxRjEvTGgyOE1ucVRrQWl5Kzk0WgphZFgrdnNrRStpdDBpTXlMM01rUXUzTmt6Q3FmeVFKejZQM3lUbU5MZ1QxNEMycFUwRE1IemkxVDIzNFl3cEw4ClVCend4dG96R29ib3VLVWloczRQNmk3SFR3SWxaNy9HbWxFRklJRGcvbUNVaFBoSWR6eEJ2QittaFQ4UTM5MkMKMnhtMnVKa0NnWUVBMmxKVGZ5L1E3WjkxOVkxQmxteTQ4YWxXUmhwNXZ3OWU5bldqNlF6UjFjVUJzRU5tLzlnOQpjT05LMG5udHdOZ0Q0VG5RMzBlVXpjbHNsMEZIcEtsN0N5NFpJeUN2KytXWGhUKy9wVmFhWDBzeXQ4aVU0WkRaCnU0bzAvUzNYMjNKb3RpQkx0SzBGempoOUxJYkpkVFRiUWxLT3I5VklRRXFsTUFnNXJJUTlLalVDZ1lFQTNBQ0EKWVZFV3JtakZDY1FLTStQUXlFS01EbENPY1VhM2EwVlRLTzJkb2k2NkhqSmRDSU5tMzRNUEFHTk9adm51TCs0MApqYmtZQWtZYmRVYk0yMVlxNll3NEUwazAyV1pmazVtdFNZUDBNYm8vcStDeHNSZVdPZ0ZuaHFnRGI1R3FMQXZPCmdNdnNJWWlrbC92clRTbTh4WTFVTWtGMlZmeVpzUG92aXB0SVdaTUNnWUJnWUlWeG1TY3ZMdnpBeUhuU3NPNDMKNkZ3b21GbDBhWkd2VlNGbHFQNGMwMW82ZUpiSWpLb2E0b3ZPUEhzamJYalEvVmZpcVZQY1FIWUtrNHZQK2UxUwpjeWd2cEtkcm1OLzV0N21mZ0lxblZLZndEOEVCanBNL3dmUkFhL05sY2EwZDhVWGFYYU01ZFNCMC9vK0NpVEhkCnBscE03dWQxVWo1MzVMbXBHYnR5blFLQmdGb2lFbmJNWkFCOGlBMWlOZFBnaUE4anhJR3cyMHJwY0FnUTFPczEKdnBsTmo0OERqejRIcDhQMnk5U2EydW94aHpZMzMyd1k0dzg3YmRCMGUwVjVYZ2RsSFN3NWw5OWhvOUt5NlYzdgpJOEtqemFZN1hsRnhtbWlWWHJhNmF2M3dyY2x4NU42N3JUaG41UmNuYk5XbVBlS3A3azdRcHd5L2VyQVpNQlVYClhXTGxBb0dBTFA3Wm5qK1JnL21Yb3E3Tkw4aURWVEdmRmx0TjJ2K1lBWll0TFFrSG5tM2Vldk9wS3M0NjhXRjEKZFZVNkZzaWhDOXhtR1FKcVVmMzlVL0E4eHdWKytncDhvd3JNeHpHSWFSWDM1b2hKS2U1RXovNElON3ovOTZlVwpwM3BjeDhBK1pZYTcwc0IzeUpUN1E0dWFTRERJcUwxY3lpZUJwYzlyTTBjSHV0bGI4ajQ9Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: example.com
    cert-manager.io/certificate-name: my-certificate
    cert-manager.io/common-name: ""
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: ""
    cert-manager.io/issuer-kind: Issuer
    cert-manager.io/issuer-name: my-ca-issuer
    cert-manager.io/uri-sans: ""
  creationTimestamp: "2025-09-22T15:54:54Z"
  labels:
    controller.cert-manager.io/fao: "true"
  name: my-certificate-tls
  namespace: cert-ns
  resourceVersion: "491161"
  uid: 079bf79b-5fa5-4c75-ac22-0724c5ad4188
type: kubernetes.io/tls
```

```
kubectl get secret my-certificate-tls -n cert-ns -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            ab:cf:92:0f:6d:98:68:0f:62:bc:98:90:e5:7f:b9:c4
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = root-ca
        Validity
            Not Before: Sep 22 15:54:54 2025 GMT
            Not After : Dec 21 15:54:54 2025 GMT
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bb:9f:2d:3d:75:30:2b:8a:57:a4:0d:6f:af:04:
                    48:38:b0:e0:13:ac:b3:3b:f7:fe:71:7c:db:a8:07:
                    bd:8d:15:de:7d:ca:bd:8f:de:52:71:50:8d:3b:99:
                    9e:ca:4b:06:e1:4d:ca:b1:f3:79:fb:30:17:b2:de:
                    57:e9:4e:20:1a:0e:54:4b:c8:5d:f0:24:9b:d7:65:
                    3e:7b:68:73:2e:5a:2e:17:db:53:7b:79:a4:83:e8:
                    3c:88:95:69:16:b9:85:8c:2e:7f:19:9e:0b:ae:0c:
                    a3:ef:1c:a0:5b:86:5e:36:e1:e4:2d:8a:02:d7:2e:
                    fd:d7:d9:91:b5:3a:9d:97:72:41:c3:75:2c:04:e2:
                    55:ed:3c:8a:f7:f2:b7:0b:2f:cb:0f:13:36:c4:74:
                    5f:8c:bf:72:d9:dd:97:7e:aa:9d:8c:7d:b2:cb:db:
                    c3:42:56:d2:66:fc:52:ea:c6:2a:96:78:98:57:4e:
                    f2:25:41:5f:54:2f:c9:33:f0:d4:64:98:40:54:91:
                    e2:ea:6d:a4:0d:ad:5b:96:99:3e:3b:10:d3:fc:86:
                    1e:fb:e5:25:84:26:00:f4:db:89:c0:18:5a:73:cc:
                    83:18:45:83:06:2d:09:b7:0d:40:05:55:10:9c:0c:
                    c5:d9:94:f2:e9:dd:85:21:7c:48:d6:cd:5d:28:b3:
                    a9:6f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                5C:D8:32:9D:32:EF:B2:54:90:72:AF:8C:22:C1:8F:DE:06:C3:FD:50
            X509v3 Subject Alternative Name: critical
                DNS:example.com
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        8a:02:0b:98:bb:b8:cb:1a:cd:23:7b:62:58:69:3d:3b:87:73:
        70:a0:dc:b5:32:92:6e:8d:c7:51:18:b6:39:03:af:3c:c5:ee:
        30:20:2e:0b:64:94:fa:27:97:07:27:0f:92:9a:02:26:9d:70:
        94:66:ef:c0:27:b6:05:c5:55:97:f1:7a:59:ed:83:b3:13:41:
        e4:ab:76:2b:a8:74:4d:10:3c:f6:8c:9f:b9:40:dd:bb:a8:81:
        f0:f9:87:be:45:f2:f4:2f:d7:f4:80:bd:4c:b6:49:77:b3:b3:
        b3:dc:88:23:32:a1:ae:89:16:de:79:ef:37:69:c7:ad:60:e9:
        db:8a:78:e2:e1:3c:5a:1c:40:e3:c9:ba:8f:d8:ab:20:df:62:
        f8:12:20:00:6c:ae:f6:4b:27:dd:08:ee:e4:e8:2a:bb:1a:98:
        28:88:a8:ba:cd:d0:c1:7e:3d:ba:f8:bc:17:55:40:d7:5d:3b:
        fd:85:06:0f:f2:d6:8d:35:7e:a2:4a:c1:18:18:20:4e:1a:c6:
        46:d4:cb:80:1a:65:66:26:ea:7b:39:25:ff:fd:b1:fd:78:6e:
        c0:92:4d:25:27:4d:2c:3c:4c:e9:66:ce:34:a6:1c:5c:49:82:
        94:47:7b:97:fd:d9:3f:d9:a8:f0:df:5e:70:f3:48:ab:dc:22:
        49:fc:5b:82

```

### 11. Calico Network Plugin ###

**Obiettivo:**

Installazione del plugin di Network Calico. Installare il CNI Calico utilizzando l'operator Tigera (https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/tigera-operator.yaml).

**Nota:** Solo su cluster non gestito (bare metal, kubeadm). Evitare se CNI già presente.

**Risoluzione:**

Installare l'operator Tigera e le relative CRD:

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/tigera-operator.yaml
```

Installare Calico: 
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/custom-resources.yaml
```

Verifica dei componenti di Calico:
```
watch kubectl get tigerastatus
```

### 12. RBAC (rbac-ns)
**Obiettivo:**

Nel namespace rbac-ns creare una Role pod-reader-role che permetta di leggere i pod con i verbi get,watch e list, un ServiceAccount pod-reader, e legare il tutto con un RoleBinding.

**Risoluzione:**

Creare il serviceaccount:
```
k -n rbac-ns create sa pod-reader
```
Esportare lo YMAL del pod e cambiare il service account:
```
apiVersion: v1
kind: Pod
[...]
spec:
  containers:
  - image: nginx:alpine
    imagePullPolicy: IfNotPresent
    name: rbac
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-hqllv
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: worker1-k8s
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: pod-reader						# CHANGE
  serviceAccountName: pod-reader					# CHANGE
  terminationGracePeriodSeconds: 30
[...]
```
Sostituire il pod in esecuzione:
```
k delete -f prep01/12.pod.yaml
k apply -f prep01/12.pod.yaml
```
```
k -n rbac-ns exec -it pods/rbac -- bin/sh
/ # TOKEN=$( cat /var/run/secrets/kubernetes.io/serviceaccount/token )
/ # curl  -kH "Authorization: Bearer ${TOKEN}" https://kubernetes.default/api/v1/namespaces/rbac-ns/pods
exit

Check:
k -n rbac-ns auth can-i get po --as=system:serviceaccount:rbac-ns:pod-reader
yes
```

### 13. Node Affinity + Tolerations (scheduling-ns)
**Obiettivo:**

Schedulare il pod affinity-pod con immagine busybox che esegua il comando "sleep 3600". Il nodo deve essere schedulato su uno dei nodi a disposizione del cluster
utilizzando l'affinity e le tolerations.

**Risoluzione:**
Aggiungere un taint ai nodi del cluster:
```
k taint node worker1-k8s worker2-k8s worker3-k8s key1=value1:NoSchedule
```

Creare il pod affinity-pod: 

13.pod.yaml
```
apiVersion: v1
kind: Pod
metadata:
  name: affinity-pod
  namespace: scheduling-ns
spec:
  tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "kubernetes.io/hostname"
            operator: In
            values:
            - worker1-k8s
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
```
```
k apply -f 13.pod.yaml
```
Check:

```
k -n scheduling-ns get po -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE          NOMINATED NODE   READINESS GATES
affinity-pod   1/1     Running   0          17s   10.10.159.6   worker3-k8s   <none>           <none>
```

Nota: per poter continuare gli esercizi rimuovere il taint sui nodi del cluster:  
```
k taint node worker1-k8s worker2-k8s worker3-k8s key1=value1:NoSchedule-
```

### 14. ConfigMap & Secret (config-ns)
**Obiettivo:** 

Creare un pod che monta una ConfigMap come file e legge Secret come variabile d’ambiente. 
Creare un pod config-secret-pod che carica la ConfigMap my-config come volume al path /etc/config e che include
il file myconfig.txt con il contenuto: "Questo è il contenuto della config". 
Creare anche un secret my-secret che contenga la key password con valore "password".
Il pod deve avere l'immagine busybox e deve eseguire il comando: "echo Password: $PASSWORD && sleep 3600".

**Preparazione:**
il file myconfig.txt è presente nella directory 14.config-ns

**Risoluzione:**

Creare la configmap:
```
k -n config-ns create cm my-config --from-file=../14.config-ns/myconfig.txt
```
Creare il secret:
```
k -n config-ns create secret generic my-secret --from-literal=password=password
```
Creare il template del pod:
```
k -n config-ns run config-secret-pod --image=busybox --dry-run=client -o yaml > 14.pod.yaml 
```
Editare il file:

14.pod.yaml
```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: config-secret-pod
  name: config-secret-pod
  namespace: config-ns
spec:
  containers:
  - image: busybox
    name: config-secret-pod
    env:																# ADD
    - name: PASSWORD													# ADD
      valueFrom:														# ADD
        secretKeyRef:													# ADD
          key: password													# ADD
          name: my-secret												# ADD
    command: [ 'sh','-c','echo Password: $PASSWORD && sleep 3600' ]		# ADD	
    volumeMounts:														# ADD
    - name: my-config													# ADD
      mountPath: /etc/config											# ADD
  volumes:																# ADD
  - name: my-config														# ADD
    configMap:															# ADD
      name: my-config													# ADD
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
```
k apply -f 14.pod.yaml
```
Check:
```
k -n config-ns exec -it pod/config-secret-pod -- env | grep password
PASSWORD=password

k -n config-ns exec -it pod/config-secret-pod -- cat /etc/config/myconfig.txt
Questo è il contenuto della config

```
### 15 . Troubleshooting (debug-ns)
**Obiettivo:**

Correggere un pod in CrashLoopBackOff (es. container con comando che fallisce).
Nel namespace debug-ns, il pod crash-pod risulta essere in CrashLoopBackOff.
Correggere l'errore e riavviare il pod.

**Risoluzione:**
```
k -n debug-ns get all
NAME            READY   STATUS             RESTARTS       AGE
pod/crash-pod   0/1     CrashLoopBackOff   5 (102s ago)   4m48s
```
```
k -n debug-ns describe pod/crash-pod
Name:             crash-pod
Namespace:        debug-ns
Priority:         0
Service Account:  default
Node:             worker3-k8s/192.168.122.148
Start Time:       Fri, 26 Sep 2025 10:46:38 +0200
Labels:           <none>
Annotations:      cni.projectcalico.org/containerID: 0503616f1e4782eabc4988f5746feded7a4d4df7c3a8b5129806798bf2469e0c
                  cni.projectcalico.org/podIP: 10.10.159.54/32
                  cni.projectcalico.org/podIPs: 10.10.159.54/32
Status:           Running
IP:               10.10.159.54
IPs:
  IP:  10.10.159.54
Containers:
  crash-container:
    Container ID:  containerd://4298bb7631eab23a20076e0f4b5ff34733d708f567eabd16bd13b1307d2fcf8e
    Image:         busybox
    Image ID:      docker.io/library/busybox@sha256:ab33eacc8251e3807b85bb6dba570e4698c3998eca6f0fc2ccb60575a563ea74
    Port:          <none>
    Host Port:     <none>
    Command:
      false
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Fri, 26 Sep 2025 10:52:29 +0200
      Finished:     Fri, 26 Sep 2025 10:52:29 +0200
    Ready:          False
    Restart Count:  6
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-lp6d8 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-lp6d8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  7m5s                   default-scheduler  Successfully assigned debug-ns/crash-pod to worker3-k8s
  Normal   Pulled     7m                     kubelet            Successfully pulled image "busybox" in 3.605s (3.605s including waiting). Image size: 2223685 bytes.
  Normal   Pulled     6m55s                  kubelet            Successfully pulled image "busybox" in 1.731s (1.731s including waiting). Image size: 2223685 bytes.
  Normal   Pulled     6m39s                  kubelet            Successfully pulled image "busybox" in 1.772s (1.772s including waiting). Image size: 2223685 bytes.
  Normal   Pulled     6m7s                   kubelet            Successfully pulled image "busybox" in 1.643s (1.643s including waiting). Image size: 2223685 bytes.
  Normal   Pulled     5m23s                  kubelet            Successfully pulled image "busybox" in 1.556s (1.556s including waiting). Image size: 2223685 bytes.
  Normal   Created    4m (x6 over 6m59s)     kubelet            Created container: crash-container
  Normal   Pulled     4m                     kubelet            Successfully pulled image "busybox" in 1.597s (1.597s including waiting). Image size: 2223685 bytes.
  Normal   Started    3m59s (x6 over 6m59s)  kubelet            Started container crash-container
  Warning  BackOff    88s (x26 over 6m54s)   kubelet            Back-off restarting failed container crash-container in pod crash-pod_debug-ns(ccfdcf95-6bf2-4e15-a074-c62530e9c1b4)
  Normal   Pulling    77s (x7 over 7m3s)     kubelet            Pulling image "busybox"
  Normal   Pulled     75s                    kubelet            Successfully pulled image "busybox" in 1.616s (1.616s including waiting). Image size: 2223685 bytes.
```
```
k -n debug-ns edit pod/crash-pod
[...]
spec:
  containers:
  - command:
    - "false"                            # Comando in errore
    image: busybox
    imagePullPolicy: Always
    name: crash-container
    resources: {}
[...]
```
Esportare lo YAML del pod e corregere il comando:
```
k -n debug-ns get pod/crash-pod -o yaml > 15.pod.yaml

spec:
  containers:
  - command:
    - "sh"										# CHANGE					
    - "-c"										# CHANGE
    - "sleep 1d"                            	# CHANGE
    image: busybox
    imagePullPolicy: Always
    name: crash-container
    resources: {}
[...]
```

### 16. DaemonSet (ds-ns)
**Obiettivo:**

Deploy di un agent su tutti i nodi. Nel namespace ds-ns, creare un daemoset busybox-agent per deployare l'agent su tutti i nodi del cluster.
 
**Risoluzione:**
```
k -n ds-ns create deployment busybox-agent --image=busybox --dry-run=client -o yaml -- sleep 3600 > 16.daemonset.yaml
```
Editare il file:
```
apiVersion: apps/v1
kind: DaemonSet					# CHANGE
metadata:
  creationTimestamp: null
  labels:
    app: busybox-agent
  name: busybox-agent
  namespace: ds-ns
spec:
  replicas: 1					# DELETE
  selector:
    matchLabels:
      app: busybox-agent
  strategy: {} 					# DELETE
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: busybox-agent
    spec:
      containers:
      - command:
        - sleep
        - "3600"
        image: busybox
        name: busybox
        resources: {}
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: "NoSchedule"
status: {}
```

Installare il daemonset:
```
k apply -f 16.daemonset.yaml
```
Verifica:
```
k -n ds-ns get all -o wide

NAME                  READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
busybox-agent-4h4b9   1/1     Running   0          36m   10.10.195.55   worker1-k8s   <none>           <none>
busybox-agent-kb5zq   1/1     Running   0          35m   10.10.7.253    worker2-k8s   <none>           <none>
busybox-agent-qrxj9   1/1     Running   0          36m   10.10.159.27   worker3-k8s   <none>           <none>
busybox-agent-zklpm   1/1     Running   0          37m   10.10.199.44   master-k8s    <none>           <none>

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS   IMAGES    SELECTOR
daemonset.apps/busybox-agent   3         3         3       3            3           <none>          38m   busybox      busybox   app=busybox-agent
```

### 17. NetworkPolicy (netpol-ns)
**Obiettivo:** 

Bloccare tutto il traffico di rete tra pod nel namespace. Nel namespace netpol-ns, ci sono il pod web che espone il service web e il pod app. 
Creare una NetworkPolicy deny-all che blocchi il traffico di rete tra pod nel namespace.

**Risoluzione:**

Verificare che il traffico è consentito tra i pod:
```
k -n netpol-ns exec -it pod/app -- bin/sh
/ # curl http://web
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
Da un altro namespace, accedere al pod web:
```
k -n default run test --image=nginx -it --rm --restart=Never -- curl http://web.netpol-ns
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
pod "test" deleted
```
Creare la network policy:

17.netpol.yaml
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: netpol-ns
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```
```
k apply -f 17.netpol.yaml
```
```
k -n netpol-ns describe networkpolicies. deny-all 
Name:         deny-all
Namespace:    netpol-ns
Created on:   2025-09-26 16:13:26 +0200 CEST
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Allowing egress traffic:
    <none> (Selected pods are isolated for egress connectivity)
  Policy Types: Ingress, Egress
```
Verifica:
```
k -n default run test --image=nginx -it --rm --restart=Never -- curl http://web.netpol-ns
If you don't see a command prompt, try pressing enter.
curl: (28) Failed to connect to web.netpol-ns port 80 after 134877 ms: Couldn't connect to server
pod "test" deleted
pod default/test terminated (Error)
```
```
k -n netpol-ns exec -it pod/app -- bin/sh
/ # 
/ # curl http://web
curl: (6) Could not resolve host: web
```

### 18. Simulazione Node Failure (failure-ns)
**Obiettivo:**

Simulare il failure di un nodo.

**Risoluzione:**

Applicare il seguente taint al nodo:
```
k taint node worker3-k8s key=value:NoSchedule
```
Fare il drain del nodo:
```
k drain worker3-k8s --ignore-daemonsets --delete-emptydir-data --force
```
Verifica:
```
k get no
NAME          STATUS                     ROLES           AGE   VERSION
master-k8s    Ready                      control-plane   18d   v1.32.1
worker1-k8s   Ready                      <none>          18d   v1.32.1
worker2-k8s   Ready                      <none>          18d   v1.32.1
worker3-k8s   Ready,SchedulingDisabled   <none>          18d   v1.32.1
```
Per ripristinare il nodo occorre fare l'uncordon e rimuovere il taint:
```
k uncordon worker3-k8s
k taint nodes worker3-k8s key=value:NoSchedule-
```

### 19. PersistentVolume & PersistentVolumeClaim (storage-ns)
**Obiettivo:**

Creare un PersistentVolume (PV) local-pv da 1GB e un PersistentVolumeClaim (PVC) local-pvc che lo usa.
Utilizzare la storageclass local-path (Nota: la storageclass è già installata). 
Infine, deployare un Pod pv-pod con immagine busybox:1.28 che monta il PVC ed esegue il comando "sleep 3600".

**Prerequisito:** installare sul cluster una storageclass locale, ad esempio local-path

**Risoluzione:**
Creare il PV:

19.pv.yaml
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path
  local:
    path: /mnt
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: 
          - worker3-k8s
```
```
k apply -f 19.pv.yaml
```

Creare il PVC:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
  namespace: storage-ns
spec:
  resources:
    requests: 
      storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path 
```

Creare il pod:
```
k -n storage-ns run pv-pod --image=busybox:1.28 --dry-run=client -o yaml -- sleep 3600 > 19.pod.yaml
```
Editare il file 19.pod.yaml:

```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pv-pod
  name: pv-pod
  namespace: storage-ns
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox:1.28
    name: pv-pod
    resources: {}
    volumeMounts:				# ADD
    - name: local				# ADD	
      mountPath: /mnt  				# ADD
  volumes:					# ADD
  - name: local					# ADD
    persistentVolumeClaim: 			# ADD
      claimName: local-pvc			# ADD	
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```
Avviare il pod:
```
k apply -f 19.pod.yaml
```

Verifica:
```
k -n storage-ns describe po  pv-pod | grep mnt -A1
      /mnt from local (rw)
```

### 20. StatefulSet (stateful-ns)
**Obiettivo:**

Deploy di uno StatefulSet dell'immagine nginx:stable con 3 repliche, che monta un volume PVC www, per ogni replica, per il path /usr/share/nginx/html.
Utilizzare una storageclass locale.

**Prerequisito:** installare sul cluster una storageclass locale, ad esempio local-path. 

**Risoluzione:**
Creare un template dello statefulset a partire dal deployment:
```
k -n stateful-ns create deployment web --image=nginx:stable --port=80 --dry-run=client -o yaml > 20.statefulset.yaml
```
Editare il file 20.statefulset.yaml:
```
apiVersion: apps/v1
kind: StatefulSet					# CHANGE
metadata:
  labels:
    app: web
  name: web
  namespace: stateful-ns
spec:
  replicas: 3						# MODIFY
  selector:
    matchLabels:
      app: web
  strategy: {}						# DELETE
  serviceName: "nginx"					# ADD	
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: web
    spec:
      containers:
      - image: nginx:stable
        name: nginx
        ports:
        - containerPort: 80
          name: web					# ADD
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html    
        resources: {}
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      resources:
      	requests:
          storage: 1Gi
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path    			  				      
status: {}

```
Installare lo YAML:
```
k apply -f 20.statefulset.yaml:   				       		  
```

Verifica:
```
k -n stateful-ns get all,pvc
NAME        READY   STATUS    RESTARTS   AGE
pod/web-0   1/1     Running   0          18m
pod/web-1   1/1     Running   0          17m
pod/web-2   1/1     Running   0          17m

NAME                   READY   AGE
statefulset.apps/web   3/3     18m

NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/www-web-0   Bound    pvc-4807804b-d327-4da0-b642-7ba859adf320   1Gi        RWO            local-path     <unset>                 18m
persistentvolumeclaim/www-web-1   Bound    pvc-89abd00b-434a-46a7-b2f4-cd8ae6579d82   1Gi        RWO            local-path     <unset>                 17m
persistentvolumeclaim/www-web-2   Bound    pvc-26e5bd65-edb1-4b85-bdf9-8de8cf6a16cd   1Gi        RWO            local-path     <unset>                 17m
```

### 21. Job batch (batch-ns)
**Obiettivo:**

Creare un Job che esegue uno script bash che stampa "Hello from Job" attende 2 secondi e poi termina. Il job deve avere 3 tentativi di esecuzione.

**Risoluzione:**
Creare il template del job:
```
k -n batch-ns create job hello --image=busybox:1.28 --dry-run=client -o yaml -- /bin/sh -c "echo 'Hello from Job'; sleep 2" > 21.job.yaml
```
Aggiungere backoffLimit pari a 3:
```
apiVersion: batch/v1
kind: Job
metadata:
  creationTimestamp: null
  name: hello
  namespace: batch-ns
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - echo 'Hello from Job'; sleep 2
        image: busybox:1.28
        name: hello
        resources: {}
      restartPolicy: Never
  backoffLimit: 3					# ADD    
status: {}
```

Creare il job:
```
k apply -f 21.job.yaml
```

Verifica:
```
k -n batch-ns get all
NAME              READY   STATUS      RESTARTS   AGE
pod/hello-krgsf   0/1     Completed   0          6m24s

NAME              STATUS     COMPLETIONS   DURATION   AGE
job.batch/hello   Complete   1/1           7s         6m24s

k -n batch-ns logs pod/hello-krgsf
Hello from Job
```

### 22. Ingress con TLS (ingress-ns)
**Obiettivo:**

Configurare un Ingress con TLS (self-signed) che instrada verso un service Nginx.
Nel namespace ingress-ns è presente il pod web esposto con un ingress web-ingress. Creare un certificato self-signed 
con il tool cfssl e configurate l'ingress TLS con l'host web.local.

**Risoluzione:**

Verifica del namespace:
```
k -n ingress-ns get all,ing
NAME                       READY   STATUS    RESTARTS       AGE
pod/web-78df96f968-dtpn9   1/1     Running   16 (28m ago)   22d

NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.104.142.8   <none>        80/TCP    22d

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   1/1     1            1           22d

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-78df96f968   1         1         1       22d

NAME                                    CLASS   HOSTS       ADDRESS           PORTS   AGE
ingress.networking.k8s.io/web-ingress   nginx   web.local   192.168.122.222   80      22d
```
Creare una directory per gli artifacts e inizializzare cfssl:
```
mkdir cert
cd cert 

cfssl print-defaults > config.json
cat config.json
{
    "signing": {
        "default": {
            "expiry": "168h"
        },
        "profiles": {
            "www": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}

cfssl print-defaults csr > csr.json




```
Modificare il file csr.json:
```
{
    "CN": "web.local",					# CHANGE
    "hosts": [
        "web.local",					# CHANGE					
        "www.web.local"					# CHANGE
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "US",
            "ST": "CA",
            "L": "San Francisco"
        }
    ]
} 
```
Generare la CA:

```
cfssl gencert -initca csr.json | cfssljson -bare ca
2025/09/30 17:19:28 [INFO] generating a new CA key and certificate from CSR
2025/09/30 17:19:28 [INFO] generate received request
2025/09/30 17:19:28 [INFO] received CSR
2025/09/30 17:19:28 [INFO] generating key: ecdsa-256
2025/09/30 17:19:28 [INFO] encoded CSR
2025/09/30 17:19:28 [INFO] signed certificate with serial number 619999696513047655266847844053058379037933336331
```

Verifica:

```
prep01/cert$ ls
ca.csr  ca-key.pem  ca.pem  config.json  csr.json
```

Creare la richiesta per il certificato Ingress ingress-csr.json:
```
cat ingress-csr.json
{
  "CN": "web.local",
  "hosts": [
    "web.local",
    "www.web.local",
    ""
  ],
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [{
    "C": "US",
    "ST": "CA",
    "L": "San Francisco"
  }]
}
```

Creare il certificato:

```
cfssl gencert \
   -ca=ca.pem \ 
   -ca-key=ca-key.pem \
   -config=config.json \
   -profile=www ingress-csr.json | cfssljson -bare ingress 
```

Verifica:

```
prep01/cert$ ls
ca.csr  ca-key.pem  ca.pem  config.json  ingress.csr  ingress-csr.json  ingress-key.pem  ingress.pem
```

Verifica del certificato:

```
openssl x509 -in ingress.pem -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            1c:05:87:36:b5:53:d7:83:2c:26:f0:8d:48:50:6c:47:0f:79:a0:94
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: C = US, ST = CA, L = San Francisco, CN = web.local
        Validity
            Not Before: Sep 30 15:39:00 2025 GMT
            Not After : Sep 30 15:39:00 2026 GMT
        Subject: C = US, ST = CA, L = San Francisco, CN = web.local
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:31:1a:86:08:9b:45:98:e7:9c:89:7f:8a:8d:21:
                    5e:0f:da:50:2c:c2:52:84:5d:5f:29:95:43:aa:d3:
                    ca:6a:69:76:ac:d3:bd:0f:07:de:d2:65:07:16:0c:
                    9f:37:6b:0f:d6:34:67:87:7e:81:c7:78:b5:7d:32:
                    aa:a7:51:0b:be
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                58:07:FD:EE:0E:76:3D:8E:3B:E6:B9:8A:20:42:17:55:95:1C:07:BE
            X509v3 Subject Alternative Name:
                DNS:web.local, DNS:www.web.local
    Signature Algorithm: ecdsa-with-SHA256
    Signature Value:
        30:46:02:21:00:be:14:03:19:55:b3:30:14:ab:23:dc:e3:05:
        f9:be:db:e0:a5:89:cd:de:82:9b:73:f6:cf:6a:7f:69:b1:69:
        71:02:21:00:ea:f7:55:8c:e6:ac:98:93:d8:5c:19:c0:7e:45:
        7f:ac:a5:ea:e1:72:5e:61:0f:86:12:58:28:ee:2b:4b:fb:cf
```

Creare il secret TLS:
```
k -n ingress-ns create secret tls ingress-web --cert=ingress.pem --key=ingress-key.pem
```
Modificare l'ingress web-ingress aggiungendo il secret TLS:
```
k -n ingress-ns edit ingress web-ingress
[...]
spec:
  ingressClassName: nginx
  rules:
  - host: web.local
    http:
      paths:
      - backend:
          service:
            name: web
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:									# ADD
  - hosts:								# ADD
    - web.local							# ADD
    secretName: ingress-web				# ADD	
[...] 

```
Verifica del'ingress in ascolto sulla 443: 
```
k -n ingress-ns get ingress web-ingress
NAME          CLASS   HOSTS       ADDRESS           PORTS     AGE
web-ingress   nginx   web.local   192.168.122.222   80, 443   22d
```

Check con curl in https:

```
 curl https://web.local:31431 -k
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### 23. Deploy con Helm (helm-ns)
**Obiettivo:**

Installare la versione 2.1.1 di nginx/wiremind con Helm nel namespace helm-ns, impostando replica a 2.

**Risoluzione:**

Installare il repo:

```
helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
```

Aggiornare il repo:
```
helm repo update 
```

Verificare le versioni del chart:

```
helm search repo nginx
NAME                       	CHART VERSION	APP VERSION	DESCRIPTION                                       
wiremind/nginx             	2.1.1        	           	An NGINX HTTP server                              

```

Verificare i values del repository remoto:
```
helm show values wiremind/nginx --version v2.1.1 | grep replica
```

Installare Nginx:
```
helm -n helm-ns install my-nginx wiremind/nginx --set replicaCount=2 --version v2.1.1
```

Verifica:
```
helm -n helm-ns status my-nginx 
NAME: my-nginx
LAST DEPLOYED: Wed Oct  1 17:34:39 2025
NAMESPACE: helm-ns
STATUS: deployed
REVISION: 1

```

Verifica:
```
k -n helm-ns get all
NAME                                  READY   STATUS    RESTARTS   AGE
pod/my-nginx-nginx-5454dc9598-7wqs2   1/1     Running   0          52s
pod/my-nginx-nginx-5454dc9598-qp2pn   1/1     Running   0          52s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/my-nginx-nginx   ClusterIP   10.102.77.148   <none>        80/TCP    53s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-nginx-nginx   2/2     2            2           52s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/my-nginx-nginx-5454dc9598   2         2         2       52s

```

### 24. Multi-container Pod (multi-ns)
**Obiettivo:**

Creare un Pod multi-container con 2 container: il container nginx che serve una pagina web e il container writer con immagine busybox 
che scrive ogni 5s in un volume condiviso /data.

**Risoluzione:**

Creare il template del pod:
```
k -n multi-ns run multi-container --image=nginx --dry-run=client -o yaml > 24.pod.yaml

```	
Editare lo YAML:

```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: multi-container
  name: multi-container
  namespace: multi-ns
spec:
  containers:
  - image: nginx
    name: nginx										# CHANGE
    volumeMounts:									# ADD	
    - name: shared									# ADD
      mountPath: /usr/share/nginx/html							# ADD	
  - image: busybox									# ADD
    name: writer									# ADD
    command: ["sh", "-c", "while true; do date >> /data/index.html; sleep 5; done" ]	# ADD
    volumeMounts:									# ADD
    - name: shared									# ADD
      mountPath: /data									# ADD
    resources: {}
  volumes:										# ADD
  - name: shared									# ADD
    emptyDir: {}									# ADD
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
Creare il pod:

```
k apply -f 24.pod.yaml
```

Verifica:
```
k -n multi-ns exec -it multi-container -c nginx  -- cat /usr/share/nginx/html/index.html
Sat Oct  4 07:30:41 UTC 2025
Sat Oct  4 07:30:46 UTC 2025
Sat Oct  4 07:30:51 UTC 2025
Sat Oct  4 07:30:56 UTC 2025
Sat Oct  4 07:31:01 UTC 2025
Sat Oct  4 07:31:06 UTC 2025
Sat Oct  4 07:31:11 UTC 2025
Sat Oct  4 07:31:17 UTC 2025
[...]

k -n multi-ns exec -it multi-container -c writer  -- cat /data/index.html
Sat Oct  4 07:30:41 UTC 2025
Sat Oct  4 07:30:46 UTC 2025
Sat Oct  4 07:30:51 UTC 2025
Sat Oct  4 07:30:56 UTC 2025
Sat Oct  4 07:31:01 UTC 2025
Sat Oct  4 07:31:06 UTC 2025
Sat Oct  4 07:31:11 UTC 2025
Sat Oct  4 07:31:17 UTC 2025
[...]
```

### 25. Custom Resource Definition (CRD) & Custom Resource (cdr-ns) 
**Obiettivo:**

Creare una CRD chiamata MyApp e un oggetto custom di tipo MyApp.

**Risoluzione:**

Creare lo YAML della CRD MyApp:

25.crd.yaml
```
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myapps.example.com
spec:
  group: example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              size:
                type: integer
  scope: Namespaced
  names:
    plural: myapps
    singular: myapp
    kind: MyApp
    shortNames:
    - ma
```
Installare la CRD:

```
k apply -f 25.crd.yaml
```

Creare lo YAML dell'oggetto example-myapp di tipo MyApp:

25.example-myapp.yaml
```
apiVersion: example.com/v1
kind: MyApp
metadata:
  name: example-myapp
  namespace: crd-ns
spec:
  size: 3
```

Creare example-myapp:
```
k apply -f 25.example-myapp.yaml
```

Visualizzare la CRD e l’oggetto:

```
kubectl get crd myapps.example.com
kubectl get myapp -n crd-ns	
```

[vai a inizio pagina](#cka-prep-2025)




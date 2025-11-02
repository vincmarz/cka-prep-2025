## CKA Prep 2025 Exam 
**Nota:** _per il setup dell'esame, eseguire cka-setup.sh._
_Il nome del namespace del singolo task è indicato tra parentesi_ 

### 1. HPA Configuration (hpa-ns)
**Obiettivo:**

Creare un HPA per scalare automaticamente un deployment in base all'utilizzo della CPU.
Il deployment hpa-app deve avere un minimo di 1 e un massimo di 5 pod e lavorare con l'utilizzo di CPU al 50%. Impostare inoltre il parametro
stabilizationWindowSecond per lo scaleDown a 30 secondi.

### 2. Installazione CRI-O (su Linux Ubuntu 22.04)
**Obiettivo:**

Installare CRI-O su un nodo. Installare con dpkg il package cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb disponibile ./02.crio-ns. Avviare e abilitare il servizio.          
Dopo l'avvio, configurare i seguenti parametri a livello di sistema operativo:
- net.bridge.bridge-nf-call-iptables  = 1
- net.ipv4.ip_forward                 = 1
- net.bridge.bridge-nf-call-ip6tables = 1

Nota:
https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb


### 3. ArgoCD via Helm 3 (argocd-ns)
**Obiettivo:**

Installare ArgoCD v.7.8.0 senza CRD. Installare il repository https://argoproj.github.io/argo-helm con il nome argo. Salvare i valori del chart nel file
argo-helm.yaml della versione 7.8.0, utilizzando il template senza installare le CRD. Installare ArgoCD dal file argo-helm.yaml.

### 4. PriorityClass (priority-ns)
**Obiettivo:**

Creare la priorityclass con il nome my-priority con la descrizione "My priority pods" ma che non sia la default priority.
Impostare la priorityclass con un valore che sia appena inferiore alla più grande priority dei pod presenti nel namespace priority-ns. 
Utilizzare la priorityclass my-priority in un pod priority-pod con immagine busybox. 
Infine salvare in ordine decrescente di priority l'elenco dei pod e salvarlo nel file 4.priority.list.

### 5. Ingress Setup (ingress-ns)
**Obiettivo:**

Creazione di un ingress Nginx. Nel namespace è presente il pod web esposto con il service web: creare un Ingress Nginx con host web.local.

**Prerequisito:** controller Nginx Ingress installato.

### 6. Resource Quota + WordPress (quota-ns)
**Obiettivo:**

Creazione di una resource quota per un WordPress impostando la request CPU a 500 millicore, la request memory a 512 MB, 1 CPU come limit e 1 GB come limit memory.  
Assicurarsi che l'applicazione, in replica 3, abbia un pod di replica su ogni nodo.

### 7. PVC + Pod (pvc-ns)
**Obiettivo:**

Creazione di un PVC wp-pvc da 1GiB e associazione ad un pod Nginx. Creare anche un PV corrispondente (di tipo hostPath).

### 8. Sidecar Container (sidecar-ns)
**Obiettivo:**

Creazione di un side-container in un pod. Creare un pod sidecar-pod con due container con immagine busybox:1.28: il primo chiamato main-app che esegua il comando
"while true; do echo 'main running' >> /var/log/main-app.log; sleep 10; done" e il secondo sidecar che esegua il comando "tail -n+1 -f /var/log/main-app.log". 

### 9. HTTP Gateway (gateway-ns)
**Obiettivo:**

Creazione di un HTTPGateway e associazione ad un pod. Nel namespace gateway-ns è presente un deployment nginx-welcome, un service, una configmap e un ingress TLS. Esporre l'applicazione
utilizzando un gateway sulla porta 80 e creare un HTTPGateway. Utilizzare l'hostname mygateway e le stesse configurazioni TLS dell'ingress.

**Prequisito:** NGINX Gateway Fabric installato sul cluster Kubernetes.

### 10. Cert-Manager + Self-Signed Cert (cert-ns)
**Obiettivo:**

Installare CertManager alla versione 1.14.4 comprese le CRDs. In seguito:
  * a. Creare un certificato self-signed.
  * b. Creare un certificato firmato da una Root CA.

### 11. Calico Network Plugin ###

**Obiettivo:**

Installazione del plugin di Network Calico. Installare il CNI Calico utilizzando l'operator Tigera (https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/tigera-operator.yaml).

**Nota:** Solo su cluster non gestito (bare metal, kubeadm). Evitare se CNI già presente.

### 12. RBAC (rbac-ns)
**Obiettivo:**

Nel namespace rbac-ns creare una Role pod-reader-role che permetta di leggere i pod con i verbi get,watch e list, un ServiceAccount pod-reader, e legare il tutto con un RoleBinding.

### 13. Node Affinity + Tolerations (scheduling-ns)
**Obiettivo:**

Schedulare il pod affinity-pod con immagine busybox che esegua il comando "sleep 3600". Il nodo deve essere schedulato su uno dei nodi a disposizione del cluster utilizzando l'affinity e le tolerations. 

### 14. ConfigMap & Secret (config-ns)
**Obiettivo:** 

Creare un pod che monta una ConfigMap come file e legge Secret come variabile d’ambiente. 
Creare un pod config-secret-pod che carica la ConfigMap my-config come volume al path /etc/config e che include
il file myconfig.txt con il contenuto: "Questo è il contenuto della config". 
Creare anche un secret my-secret che contenga la key password con valore "password".
Il pod deve avere l'immagine busybox e deve eseguire il comando: "echo Password: $PASSWORD && sleep 3600".

**Preparazione:**
il file myconfig.txt è presente nella directory 14.config-ns

### 15 . Troubleshooting (debug-ns)
**Obiettivo:**

Correggere un pod in CrashLoopBackOff (es. container con comando che fallisce).
Nel namespace debug-ns, il pod crash-pod risulta essere in CrashLoopBackOff.
Correggere l'errore e riavviare il pod.

### 16. DaemonSet (ds-ns)
**Obiettivo:**

Deploy di un agent su tutti i nodi. Nel namespace ds-ns, creare un daemoset busybox-agent per deployare l'agent su tutti i nodi del cluster.
 
### 17. NetworkPolicy (netpol-ns)
**Obiettivo:** 

Bloccare tutto il traffico di rete tra pod nel namespace. Nel namespace netpol-ns, ci sono il pod web che espone il service web e il pod app. 
Creare una NetworkPolicy deny-all che blocchi il traffico di rete tra pod nel namespace.

### 18. Simulazione Node Failure (failure-ns)
**Obiettivo:**

Simulare il failure di un nodo.

### 19. PersistentVolume & PersistentVolumeClaim (storage-ns)
**Obiettivo:**

Creare un PersistentVolume (PV) local-pv da 1GB e un PersistentVolumeClaim (PVC) local-pvc che lo usa.
Utilizzare la storageclass local-path (Nota: la storageclass è già installata). 
Infine, deployare un Pod pv-pod con immagine busybox:1.28 che monta il PVC ed esegue il comando "sleep 3600".

**Prerequisito:** installare sul cluster una storageclass locale, ad esempio local-path 

### 20. StatefulSet (stateful-ns)
**Obiettivo:**

Deploy di uno StatefulSet dell'immagine nginx:stable con 3 repliche, che monta un volume PVC www,per ogni replica, per il path /usr/share/nginx/html.
Utilizzare una storageclass locale.

**Prerequisito:** installare sul cluster una storageclass locale, ad esempio local-path.

### 21. Job batch (batch-ns)
**Obiettivo:**

Creare un Job che esegue uno script bash che stampa "Hello from Job" attende 2 secondi e poi termina. Il job deve avere 3 tentativi di esecuzione.

### 22. Ingress con TLS (ingress-ns)
**Obiettivo:**

Configurare un Ingress con TLS (self-signed) che instrada verso un service Nginx.
Nel namespace ingress-ns è presente il pod web esposto con un ingress web-ingress. Creare un certificato self-signed 
con il tool cfssl e configurare l'ingress TLS con l'host web.local.

### 23. Deploy con Helm (helm-ns)
**Obiettivo:**

Installare la versione 2.1.1 di nginx/wiremind con Helm nel namespace helm-ns, impostando replica a 2.

### 24. Multi-container Pod (multi-ns)
**Obiettivo:**

Creare un Pod multi-container con 2 container: il container nginx che serve una pagina web e il container writer con immagine busybox 
che scrive ogni 5s in un volume condiviso /data.

### 25. Custom Resource Definition (CRD) & Custom Resource (cdr-ns) 
**Obiettivo:**

Creare una CRD chiamata MyApp e un oggetto custom di tipo MyApp.

[vai a inizio pagina](#cka-prep-2025-exam)

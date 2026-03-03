# Prerequisitos
 - kubectl
 - helm
 - Acceso al cluster de K8s
 - Ejecutar el proyecto Sise.IdentityServer accesible via IP via https y http
 - Asegurese de configurar el registry primero y despues publique las  imagenes de las funciones al registry antes de continuar con los demas pasos

# Deployar container registry

kubectl label nodes master-node deploymentRegistry="true"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout self-signed-tls-docker.key -out self-signed-tls-docker.crt -subj "/CN=local.docker.com/O=local.docker.com" -addext "subjectAltName = DNS:local.docker.com"

kubectl create secret tls local-docker-cert --key registry/self-signed-tls-docker.key --cert registry/self-signed-tls-docker.crt

kubectl create secret generic local-docker-cert-generic -n kube-system --from-file registry/self-signed-tls-docker.crt

kubectl get secret local-docker-cert -o yaml > registry/self-signed-secret-docker.yaml
kubectl get secret local-docker-cert-generic -o yaml > registry/self-signed-secret-docker-generic.yaml

docker run --entrypoint htpasswd httpd:2 -Bbn sisereg Sise2024#
sisereg:$2y$05$qEZwTBKrW/tTIeAXvbqpdOH38rJufdqxHJY3oXr8Oa0J1cFaOvX/O

kubectl create secret docker-registry regcred --docker-server=local.docker.com --docker-username=sisereg --docker-password=Sise2024# --docker-email=tsiseest@sise.com

kubectl get secret regcred -o yaml > registry/regcred.yaml

Antes de aplicar los siguientes archivos, actualizar registry/persistent-volume.yaml con su configuracion propia en el path y ajustar tamaños si es necesario

kubectl apply -n kube-system -f .\registry\registry-ca.yml
kubectl apply -f registry/persistent-volume.yaml
kubectl apply -f .\registry\registry-dployment.yml
kubectl apply -f registry/config.yml

Navegar
C:\ProgramData\docker\config\daemon.json

Configurar
{
  "insecure-registries" : ["local.docker.com"]
}

docker login -u sisereg -p Sise2024# local.docker.com
docker tag local.docker.com/sentencias-funcs:1 containersoga/sentencias-funcs:1
docker push local.docker.com/seguridad-funcs:12

# Cambiar la ip que se muestra 192.168.68.63 por la ip de su equipo
kubectl apply -f .\configs\dev\config-sise-configs.yaml
kubectl apply -f .\configs\dev\secret-sise-secrets.yaml
kubectl apply -f .\configs\dev\config-sise-front-configs.yaml

kubectl apply -f .\configs\secret-func-keys.yaml
kubectl apply -f .\configs\secret-runtime-functions.yaml
kubectl apply -f .\configs\service-account-functions.yaml
kubectl apply -f .\deployments\identity-external-service.yaml

# Ejecutar localmente el poyecto IdentityServer, asegurase que sea accesible via la ip del equipo

kubectl apply -f .\deployments\seguridad-function-deployment.yaml
kubectl apply -f .\deployments\actuaria-function-deployment.yaml
kubectl apply -f .\deployments\agenda-function-deployment.yaml
kubectl apply -f .\deployments\alertas-function-deployment.yaml
kubectl apply -f .\deployments\areas-function-deployment.yaml
kubectl apply -f .\deployments\captura-expediente-function-deployment.yaml
kubectl apply -f .\deployments\catalogos-function-deployment.yaml
kubectl apply -f .\deployments\configurador-sistema-deployment.yaml
kubectl apply -f .\deployments\documentos-function-deployment.yaml
kubectl apply -f .\deployments\expediente-electronico-function-deployment.yaml
kubectl apply -f .\deployments\libreta-oficios-function-deployment.yaml
kubectl apply -f .\deployments\oficialia-function-deployment.yaml
kubectl apply -f .\deployments\perfiles-function-deployment.yaml
kubectl apply -f .\deployments\promovente-function-deployment.yaml
kubectl apply -f .\deployments\proyectos-function-deployment.yaml
kubectl apply -f .\deployments\recordatorios-function-deployment.yaml
kubectl apply -f .\deployments\seguimiento-function-deployment.yaml
kubectl apply -f .\deployments\seguridad-function-deployment.yaml
kubectl apply -f .\deployments\sentencias-function-deployment.yaml
kubectl apply -f .\deployments\tramites-function-deployment.yaml
kubectl apply -f .\deployments\usuarios-function-deployment.yaml
kubectl apply -f .\deployments\frontend-deployment.yaml

# Configurar ingress

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.admissionWebhooks.enabled=false

kubectl --namespace default get services -o wide -w ingress-nginx-controller

Con el siguiente comando asegurese de que se le sea asignada un external ip 
kubectl get service --namespace default ingress-nginx-controller --output wide

Si el cluster no asigna external ip al servicio del ingress controller asigne la ip del master de la siguiente manera (modifique la ip primero)

kubectl patch svc ingress-nginx-controller -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["10.100.8.119"]}}'

# Configurar certificado

Generar certificado de prueba 

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout self-signed-tls.key -out self-signed-tls.crt -subj "/CN=local.sise3.com/O=local.sise3.com" -addext "subjectAltName = DNS:local.sise3.com"

kubectl create secret tls local-sise-cert --key resources/self-signed-tls.key --cert resources/self-signed-tls.crt

kubectl get secret local-sise-cert -o yaml > resources/self-signed-secret.yaml

# Deployar gateway

Para ejecutar en local agregar en el archivo de hosts el mapeo de local.sise3.com 192.168.68.63 (cambiar la IP por la propia) y mediante este dominio se debe acceder al sitio

kubectl apply -f .\resources\self-signed-secret.yaml
kubectl apply -f .\gateway\ingress.yml


# Logging

kubectl apply -f .\logging\logging-namespace.yml
kubectl apply -f .\logging\persistent-volume.yaml
kubectl apply -f .\logging\elastic-deployment.yaml 

 # Test
 ps aux | grep 'elastic'
 kill -9 <PID_OF_RUNNING_ELASTIC>
 kubectl port-forward es-cluster-0 9200:9200 --namespace=kube-logging
 curl http://localhost:9200/_cluster/state?pretty

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout self-signed-tls-kibana.key -out self-signed-tls-kibana.crt -subj "/CN=local.kibana.com/O=local.kibana.com" -addext "subjectAltName = DNS:local.kibana.com"

kubectl create secret tls local-kibana-cert --namespace kube-logging --key logging/self-signed-tls-kibana.key --cert logging/self-signed-tls-kibana.crt

kubectl get secret local-kibana-cert -o yaml > logging/self-signed-secret-kibana.yaml

kubectl apply -f .\logging\kibana-gateway.yaml

Navegar a https://local.kibana.com/

# APM Server

kubectl apply -f ./logging/apm-server.yml
kubectl port-forward apm-server-5c4b6d5659-sg6sv 8200:8200 --namespace=kube-logging

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace kube-system
kubectl apply -f ./logging/metricbeat-kubernetes.yml

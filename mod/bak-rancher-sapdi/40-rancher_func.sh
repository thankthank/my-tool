SystemConfiguration () {

Debug_print  $'echo "net.bridge.bridge-nf-call-iptables=1" > /etc/sysctl.d/bridge.conf'
echo "net.bridge.bridge-nf-call-iptables=1" > /etc/sysctl.d/bridge.conf
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

}

RancherDeployment () {

Debug zypper in -y docker;
Debug systemctl enable docker;
Debug systemctl start docker;
Debug docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher rancher/rancher:v2.5.7

}

DMasterDeployment () {

Debug curl -sfL https://get.rke2.io --output install.sh
Debug chmod 0700 install.sh
Debug mkdir -p /etc/rancher/rke2

#cat <<EOF | tee /etc/rancher/rke2/config.yaml
#disable: rke2-ingress-nginx
#EOF

#Debug export INSTALL_RKE2_VERSION=v1.19.8+rke2r1
INSTALL_RKE2_VERSION=v1.19.8+rke2r1 /root/install.sh
Debug systemctl enable rke2-server.service
Debug systemctl start rke2-server.service

}

CopytokentoAll () {

Debug scp ${D_MASTER_IP[0]}:/var/lib/rancher/rke2/server/token /tmp/token
Debug cm-scp /tmp/token /tmp

}

DWorkerDeployment () {

curl -sfL https://get.rke2.io --output install.sh
chmod 0700 install.sh
mkdir -p /etc/rancher/rke2

local MTOKEN=$(cat /tmp/token)
cat <<EOF | tee /etc/rancher/rke2/config.yaml
server: https://${D_MASTER_IP[0]}:9345
token: $MTOKEN 
EOF


INSTALL_RKE2_VERSION=v1.19.8+rke2r1 INSTALL_RKE2_TYPE="agent" /root/install.sh
systemctl enable rke2-agent.service
systemctl start rke2-agent.service


}

Developing () {

echo ""

}

Kubectlsetting () {

#mkdir -p /root/.kube
#scp ${D_MASTER_IP[0]}:/etc/rancher/rke2/rke2.yaml /root/.kube/config
#sed -i "s/127.0.0.1/${D_MASTER_IP[0]}/g" /root/.kube/config
#Debug echo "test"
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.8/bin/linux/amd64/kubectl
mv kubectl /usr/bin/kubectl
chmod 755 /usr/bin/kubectl

# Helm deployment
wget -O helm.tar.gz https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
tar zxvf helm.tar.gz
mv linux-amd64/helm /usr/local/bin/
chmod +x /usr/local/bin/helm
helm repo add stable https://charts.helm.sh/stable

helm ls --all-namespaces

}

IngressController () {


local INGRESS_NS="nginx-ingress"
cat << EOF > /tmp/nginx-ingress-config-values.yaml
# Enable the creation of pod security policy
podSecurityPolicy:
  enabled: false

# Create a specific service account
serviceAccount:
  create: true
  name: nginx-ingress

# Publish services on port HTTPS/30443
# These services are exposed on each node
controller:
  service:
   # enableHttp: false
    enableHttp: true
    type: NodePort
    nodePorts:
      https: 30443
      http: 30080

EOF

#Debug helm upgrade nginx-ingress localcharts/nginx-ingress --namespace nginx-ingress --values /tmp/nginx-ingress-config-values.yaml

kubectl create ns ${INGRESS_NS}
helm install --namespace ${INGRESS_NS} stable/nginx-ingress --version 1.41.0  --set controller.scope.enabled=true --values /tmp/nginx-ingress-config-values.yaml --generate-name

#helm install --namespace ${INGRESS_NS} stable/nginx-ingress --version 1.41.0  --set controller.service.type=NodePort --set controller.scope.enabled=true --generate-name


}

MinioPostDeployment () {

ACCESS_KEY=$(kubectl get secret --namespace minio minio -o jsonpath="{.data.access-key}" | base64 --decode)
SECRET_KEY=$(kubectl get secret --namespace minio minio -o jsonpath="{.data.secret-key}" | base64 --decode)
echo ACCESS_KEY : $ACCESS_KEY
echo SECRET_KEY : $SECRET_KEY

#kubectl port-forward --namespace minio --address 0.0.0.0 svc/minio 9000:9000

local FQDN="minio.sapdemo.lab"
local NS="minio"

#openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /tmp/s3_tls.key -out /tmp/s3_tls.crt -subj "/CN=$FQDN"

#kubectl -n $NS create secret tls minio-tls-certs --key /etc/docker_registry/certs/s3_key.pem --cert /etc/docker_registry/certs/s3_crt.pem
#kubectl -n $NS create secret tls minio-tls-certs --key /tmp/s3_tls.key --cert /tmp/s3_tls.crt
#read;
kubectl -n $NS apply -f - << EOF
apiVersion: extensions/v1beta1
#apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 10240m
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  name: minio
  namespace: $NS
spec:
  rules:
    - host: $FQDN
      http:
        paths:
          - backend:
              serviceName: minio
              servicePort: 9000
            path: /
  # This section is only required if TLS is to be enabled for the Ingress
  tls:
    - hosts:
      - $FQDN
      secretName: minio-tls-certs
EOF

echo Try acesss S3 interface with $FQDN:30443
echo Admin UI is https://$FQDN:30443/minio

}

MinioHttpService () {
local NS=minio
local FQDN="minio.sapdemo.lab"
kubectl -n $NS apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: miniohttp
spec:
  ports:
  - name: minio
    port: 9000
    nodePort: 30900
    protocol: TCP
    targetPort: minio
  selector:
    app.kubernetes.io/instance: minio
    app.kubernetes.io/name: minio
  type: NodePort
EOF

}

SAPConfig () {
local NS=di313

kubectl create ns $NS

#Debug cp /etc/docker_registry/certs/s3_crt.pem /etc/docker_registry/certs/cert_with_carriage_return_s3
#tr -d '\r' < /etc/docker_registry/certs/cert_with_carriage_return_s3 > /etc/docker_registry/certs/cert_s3

Debug cp $froLOCAL_REPO_DIR/cert/natgw_cert/cacert.pem /etc/docker_registry/certs/cert_with_carriage_return
tr -d '\r' < /etc/docker_registry/certs/cert_with_carriage_return > /etc/docker_registry/certs/cert
kubectl create secret generic cmcertificates --from-file=/etc/docker_registry/certs/cert -n $NS



}


SAPpostinstallation () {
local NS=di313
local VSYSTEM="di.pntdemo.kr"
#openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=$VSYSTEM"
#kubectl -n $NS create secret tls vsystem-tls-certs --key /tmp/tls.key --cert /tmp/tls.crt

kubectl -n $NS apply -f - << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/secure-backends: "true"
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-buffer-size: 16k
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "1800"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "1800"
  name: vsystem
spec:
  rules:
  - host: "$VSYSTEM"
    http:
      paths:
        - backend:
            serviceName: vsystem
            servicePort: 8797
          path: /
  tls:
  - hosts:
    - "$VSYSTEM"
    secretName: vsystem-tls-certs
EOF


}

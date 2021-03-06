#!/bin/bash


CreateUserWithKeyAccess () {

fnUSER="sles"

Debug useradd -m $fnUSER
cat /etc/sudoers | grep "$fnUSER ALL=(ALL) NOPASSWD: ALL" || echo "$fnUSER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# SSH key setting
mkdir -p /home/$fnUSER/.ssh;
chmod 700 /home/$fnUSER/.ssh;
chown $fnUSER:users /home/$fnUSER/.ssh;

echo "$froPUBLIC_KEY" > /home/$fnUSER/.ssh/id_rsa.pub;
echo "$froPRIVATE_KEY" > /home/$fnUSER/.ssh/id_rsa;
echo "$froPUBLIC_KEY" > /home/$fnUSER/.ssh/authorized_keys;

chmod 644 /home/$fnUSER/.ssh/authorized_keys
chmod 600 /home/$fnUSER/.ssh/id_rsa
chmod 644 /home/$fnUSER/.ssh/id_rsa.pub

chown  $fnUSER:users /home/$fnUSER/.ssh/authorized_keys
chown  $fnUSER:users /home/$fnUSER/.ssh/id_rsa
chown  $fnUSER:users /home/$fnUSER/.ssh/id_rsa.pub

}


Initialize_the_cluster() {
Debug zypper --non-interactive in -t pattern SUSE-CaaSP-Management

## SAP. CaaSP 4.0 needs to be installed for SAP.
Debug zypper --non-interactive in -f skuba-1.1.2-3.6.1

## Manually configure LB ip in master1 if there is no LB

## skuba cluster init --control-plane <LB IP/FQDN> <cluster name>
Debug skuba cluster init --control-plane $LB_IP my-cluster
}

Bootstrap_the_cluster () {
cd ~/my-cluster;eval "$(ssh-agent)";ssh-add /home/sles/.ssh/id_rsa;
Debug skuba -v 5 node bootstrap --user sles --sudo --target ${MASTER[0]}.$DOMAIN ${MASTER[0]}
}

Setup_kubectl () {
Debug zypper --non-interactive in kubernetes-client;
mkdir -p ~/.kube;
Debug ln -s -f ~/my-cluster/admin.conf ~/.kube/config
}


Addtional_node() {

local ROLE=$1;
if [[ $ROLE != "master" && $ROLE != "worker" ]];then Debug echo "Input role as master or worker";return 1;fi;
local HOST=$2
if [[ $HOST == "" ]];then Debug echo "HOST :  $HOST";Debug echo "Input parameter";return 1;fi;

echo Addtional Node
cd ~/my-cluster;eval "$(ssh-agent)";ssh-add /home/sles/.ssh/id_rsa;

## Addtional Master or Worker nodes using skuba
Debug skuba -v 5 node join --role $ROLE --user sles --sudo --target $HOST.$DOMAIN $HOST

}

Helm_Deployment () {
# Create service account and Role Binding
Debug kubectl create serviceaccount --namespace kube-system tiller
Debug kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

#Debug helm init --service-account tiller --tiller-image $MGMT_FQDN/caasp/v4/helm-tiller:2.16.1
Debug helm init --upgrade --service-account tiller --tiller-image $MGMT_FQDN/caasp/v4/helm-tiller:2.16.1
#Add SUSE chart Repo
#Debug helm repo add suse-charts https://kubernetes-charts.suse.com
#Debug helm repo add stable https://kubernetes-charts.storage.googleapis.com
}


Kubernetes_UI () {

kubectl create namespace kubernetes-dashboard

Debug_print echo "Create /tmp/dashboard_t.yaml"
cat << EOF > /tmp/dashboard_t.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard

---

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - nodePort: 30001
      port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-csrf
  namespace: kubernetes-dashboard
type: Opaque
data:
  csrf: ""

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-key-holder
  namespace: kubernetes-dashboard
type: Opaque

---

kind: ConfigMap
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-settings
  namespace: kubernetes-dashboard

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
rules:
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
    verbs: ["get", "update", "delete"]
    # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["kubernetes-dashboard-settings"]
    verbs: ["get", "update"]
    # Allow Dashboard to get metrics.
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["heapster", "dashboard-metrics-scraper"]
    verbs: ["proxy"]
  - apiGroups: [""]
    resources: ["services/proxy"]
    resourceNames: ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
    verbs: ["get"]

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
rules:
  # Allow Metrics Scraper to get metrics from the Metrics server
  - apiGroups: ["metrics.k8s.io"]
    resources: ["pods", "nodes"]
    verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
        - name: kubernetes-dashboard
          image: $MGMT_FQDN/kubernetesui/dashboard:v2.0.0-rc3
          imagePullPolicy: Always
          ports:
            - containerPort: 8443
              protocol: TCP
          args:
            - --auto-generate-certificates
            - --namespace=kubernetes-dashboard
            - --enable-skip-login
            - --enable-insecure-login
            - --disable-settings-authorizer
            # Uncomment the following line to manually specify Kubernetes API server Host
            # If not specified, Dashboard will attempt to auto discover the API server and connect
            # to it. Uncomment only if the default does not work.
            # - --apiserver-host=http://my-address:port
          volumeMounts:
            - name: kubernetes-dashboard-certs
              mountPath: /certs
              # Create on-disk volume to store exec logs
            - mountPath: /tmp
              name: tmp-volume
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /
              port: 8443
            initialDelaySeconds: 30
            timeoutSeconds: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      volumes:
        - name: kubernetes-dashboard-certs
          secret:
            secretName: kubernetes-dashboard-certs
        - name: tmp-volume
          emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "beta.kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 8000
      targetPort: 8000
  selector:
    k8s-app: dashboard-metrics-scraper

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: dashboard-metrics-scraper
  template:
    metadata:
      labels:
        k8s-app: dashboard-metrics-scraper
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'runtime/default'
    spec:
      containers:
        - name: dashboard-metrics-scraper
          image: $MGMT_FQDN/kubernetesui/metrics-scraper:v1.0.1
          ports:
            - containerPort: 8000
              protocol: TCP
          livenessProbe:
            httpGet:
              scheme: HTTP
              path: /
              port: 8000
            initialDelaySeconds: 30
            timeoutSeconds: 30
          volumeMounts:
          - mountPath: /tmp
            name: tmp-volume
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "beta.kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      #tolerations:
      #  - key: node-role.kubernetes.io/master
      #    effect: NoSchedule
      volumes:
        - name: tmp-volume
          emptyDir: {}
EOF

Debug kubectl apply -f /tmp/dashboard_t.yaml

## Dashboard token 
Secret=$(kubectl -n kubernetes-dashboard get secret | grep dashboard-token | awk '{print $1}')
kubectl -n kubernetes-dashboard describe secret $Secret | grep ^token | awk '{ print $2 }' > ~/dashboard.token

echo;
echo "------- K8S Dashboard Information --------"
echo "Configure /etc/hosts as follows"
for i in ${WORKER_IP[@]};do
echo "echo $i dashboard.$DOMAIN >> /etc/hosts"
done
echo "Access URL : https://dashboard.$DOMAIN:30001"
echo;
echo 'Login with the created token, ~/dashboard.token'
echo "Please use firefox as Web Browser not Chrome. Chrome will not allow access"
echo "------------------------------------------";echo;

}

AccessProxy () {
zypper --non-interactive in screen; 
Debug screen -dm kubectl proxy --address 0.0.0.0 --accept-hosts '.*'

## How to access service using the proxy
# http://<Proxy IP address>/api/v1/namespaces/<namespace_name>/services/<[https:]service_name[:port_name]>/proxy
# e.g.
# http://192.168.37.71:8001/api/v1/namespaces/monitoring/services/http:mynginx-service:80/proxy
# caasp-lb:~ # kubectl -n monitoring get service | grep mynginx
# mynginx-service                 ClusterIP   10.96.192.39     <none>        80/TCP          76m


}

Create_ManagementCertificate() {

CADIR=demoCA
rm -rf ~/cmd_cert
mkdir -p ~/cmd_cert
cd ~/cmd_cert
mkdir $CADIR
cd $CADIR
mkdir certs crl newcerts certificate crlnumber private requests
chmod 700 private

# Copy CA key and cert
cp $froLOCAL_REPO_DIR/cert/natgw_cert/cacert.pem ~/cmd_cert/$CADIR/cacert.pem
cp $froLOCAL_REPO_DIR/cert/natgw_cert/cakey.pem ~/cmd_cert/$CADIR/private/cakey.pem

## create configuration file
##/etc/ssl/openssl.cnf is the default
cat << EOF > ~/cmd_cert/reg.cnf
HOME                    = .
RANDFILE                = $ENV::HOME/.rnd
[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]
dir             = ./demoCA              # Where everything is kept
certs           = ./demoCA/certs            # Where the issued certs are kept
crl_dir         = ./demoCA/crl              # Where the issued crl are kept
database        = ./demoCA/index.txt        # database index file.
new_certs_dir   = ./demoCA/newcerts         # default place for new certs.
certificate     = ./demoCA/cacert.pem       # The CA certificate
serial          = ./demoCA/serial           # The current serial number
crlnumber       = ./demoCA/crlnumber        # the current crl number
crl             = ./demoCA/crl.pem          # The current CRL
private_key     = ./demoCA/private/cakey.pem# The private key
RANDFILE        = ./demoCA/private/.rand    # private random number file
x509_extensions = usr_cert              # The extensions to add to the cert
name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

default_days    = 3650                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = default               # use public key default MD
preserve        = no                    # keep passed DN ordering
policy          = policy_anything

[ usr_cert ]
nsComment                       = "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits       = 2048
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
countryName            = "KR"                     # C=
stateOrProvinceName    = "Seoul"                 # ST=
localityName           = "Seoul"                 # L=
postalCode             = "11111"                 # L/postalcode=
streetAddress          = "Samsumg-ro"            # L/street=
organizationName       = "SUSE"        # O=
organizationalUnitName = "SE"          # OU=
commonName             = "$MGMT_FQDN"            # CN=
emailAddress           = "chris.chon@suse.com"  # CN/emailAddress=

[ v3_req ]
subjectAltName  = DNS:prometheus.$DOMAIN,DNS:prometheus-alertmanager.$DOMAIN,DNS:grafana.$DOMAIN # multidomain certificate

EOF

# Create private key and public key(request to be signed by CA)
cd ~/cmd_cert
openssl req -config reg.cnf -new -keyout $CADIR/private/server_key.pem -out $CADIR/requests/server_req.pem -newkey rsa:2048

touch $CADIR/index.txt
echo 01 > $CADIR/serial

# Create server certificate
openssl ca -config reg.cnf -policy policy_anything -days 3650 -out $CADIR/certs/server_crt.pem -infiles $CADIR/requests/server_req.pem


}

Create_Certificate() {

CADIR=demoCA
rm -rf ~/cmd_cert
mkdir -p ~/cmd_cert
cd ~/cmd_cert
mkdir $CADIR
cd $CADIR
mkdir certs crl newcerts certificate crlnumber private requests
chmod 700 private

# Copy CA key and cert
Debug cp $froLOCAL_REPO_DIR/cert/natgw_cert/cacert.pem ~/cmd_cert/$CADIR/cacert.pem
Debug cp $froLOCAL_REPO_DIR/cert/natgw_cert/cakey.pem ~/cmd_cert/$CADIR/private/cakey.pem

## create configuration file
##/etc/ssl/openssl.cnf is the default
cat << EOF > ~/cmd_cert/reg.cnf
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = KR
ST = KR
L = Seoul
O = suse
OU = su
CN = $MGMT.$DOMAIN
emailAddress = chris.chon@suse.com

[v3_req]
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = prometheus-alertmanager.$DOMAIN
DNS.2 = prometheus.$DOMAIN
DNS.3 = dashboard.$DOMAIN
DNS.4 = grafana.$DOMAIN
DNS.5 = $MGMT.$DOMAIN


EOF

# Create private key and public key(request to be signed by CA)
cd ~/cmd_cert
Debug openssl genrsa -out $CADIR/private/monitoring_key.pem 2048
Debug openssl req -key $CADIR/private/monitoring_key.pem -new -sha256 -out $CADIR/requests/monitoring_req.pem -config reg.cnf

touch $CADIR/index.txt
echo 01 > $CADIR/serial

# Create server certificate
Debug openssl x509 -req -CA ./demoCA/cacert.pem -CAcreateserial -CAkey ./demoCA/private/cakey.pem -in demoCA/requests/monitoring_req.pem  -out demoCA/certs/monitoring_crt.pem -days 3650 -extensions v3_req -extfile reg.cnf

}



Create_DashboardCertificate() {

CADIR=demoCA
rm -rf ~/cmd_cert
mkdir -p ~/cmd_cert
cd ~/cmd_cert
mkdir $CADIR
cd $CADIR
mkdir certs crl newcerts certificate crlnumber private requests
chmod 700 private

# Copy CA key and cert
cp $froLOCAL_REPO_DIR/cert/natgw_cert/cacert.pem ~/cmd_cert/$CADIR/cacert.pem
cp $froLOCAL_REPO_DIR/cert/natgw_cert/cakey.pem ~/cmd_cert/$CADIR/private/cakey.pem

## create configuration file
##/etc/ssl/openssl.cnf is the default
cat << EOF > ~/cmd_cert/reg.cnf
HOME                    = .
RANDFILE                = $ENV::HOME/.rnd
[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]
dir             = ./demoCA              # Where everything is kept
certs           = ./demoCA/certs            # Where the issued certs are kept
crl_dir         = ./demoCA/crl              # Where the issued crl are kept
database        = ./demoCA/index.txt        # database index file.
new_certs_dir   = ./demoCA/newcerts         # default place for new certs.
certificate     = ./demoCA/cacert.pem       # The CA certificate
serial          = ./demoCA/serial           # The current serial number
crlnumber       = ./demoCA/crlnumber        # the current crl number
crl             = ./demoCA/crl.pem          # The current CRL
private_key     = ./demoCA/private/cakey.pem# The private key
RANDFILE        = ./demoCA/private/.rand    # private random number file
x509_extensions = usr_cert              # The extensions to add to the cert
name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

default_days    = 3650                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = default               # use public key default MD
preserve        = no                    # keep passed DN ordering
policy          = policy_anything

[ usr_cert ]
nsComment                       = "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits       = 2048
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
countryName            = "KR"                     # C=
stateOrProvinceName    = "Seoul"                 # ST=
localityName           = "Seoul"                 # L=
postalCode             = "11111"                 # L/postalcode=
streetAddress          = "Samsumg-ro"            # L/street=
organizationName       = "SUSE"        # O=
organizationalUnitName = "SE"          # OU=
commonName             = dashboard.$DOMAIN           # CN=
emailAddress           = "chris.chon@suse.com"  # CN/emailAddress=

[ v3_req ]
subjectAltName  = @alt_names

[ alt_names ]
DNS.1 = prometheus-alertmanager.$DOMAIN
DNS.2 = prometheus.$DOMAIN
DNS.4 = grafana.$DOMAIN

EOF

# Create private key and public key(request to be signed by CA)
cd ~/cmd_cert
openssl req -config reg.cnf -new -keyout $CADIR/private/dashboard_key.pem -out $CADIR/requests/dashboard_req.pem -newkey rsa:2048

touch $CADIR/index.txt
echo 01 > $CADIR/serial

# Create server certificate
openssl ca -config reg.cnf -policy policy_anything -days 3650 -out $CADIR/certs/dashboard_crt.pem -infiles $CADIR/requests/dashboard_req.pem


}



Local_registry_deployment () {

Debug zypper --non-interactive in docker;
Debug systemctl enable docker;
Debug systemctl start docker;

	
Debug mkdir -p /etc/docker_registry/certs
Debug cp -v ~/cmd_cert/demoCA/certs/monitoring_crt.pem /etc/docker_registry/certs/
Debug cp -v ~/cmd_cert/demoCA/private/monitoring_key.pem /etc/docker_registry/certs/
cat << EOF > /etc/docker_registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /etc/docker/registry/certs/monitoring_crt.pem
    key: /etc/docker/registry/certs/monitoring_key.pem
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF
Debug mkdir -p /var/lib/docker/registry

Debug docker load -i $froLOCAL_REPO_DIR/docker_images_file/registry.2.6.2.tar
Debug docker container run -d -p 443:5000 --restart=always --name suse-registry -v /etc/docker_registry:/etc/docker/registry -v /var/lib/docker/registry:/var/lib/registry registry.suse.com/sles12/registry:2.6.2

#Debug docker container run -d --restart=always -p 5000:443 --name registry -v /var/lib/docker/registry:/var/lib/registry -v /var/lib/docker/certs:/certs -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/monitoring_crt.pem -e REGISTRY_HTTP_TLS_key=/crts/monitoring_key.pem registry.suse.com/sles12/registry:2.6.2
}

Local_registry_load_images ()
{
local REGISTRIES=(registry.suse.com k8s.gcr.io gcr.io quay.io);

#clean up images which are loaded on this machine.
#docker images | grep -v REPOSITORY| awk '{print "docker image rm -f "$3   }' | bash

#load and push
for i in $(ls $froLOCAL_REPO_DIR/docker_images_file/);do

#Debug_print 'Result=$(docker load -i $froLOCAL_REPO_DIR/docker_images_file/$i)'
Result=$(docker load -i $froLOCAL_REPO_DIR/docker_images_file/$i |egrep '^Loaded image:')

ImgnamewithTar=$(echo $i | sed 's/\./\:/')
ImgnamewithTag=$(echo $ImgnamewithTar | sed 's/\.tar//g' )
ImgnameTagOnly=${ImgnamewithTag##*:}
ImgnameTagnumberOnly=$( echo $ImgnameTagOnly | sed 's/v//g' )
#Below is imagename with Registry
ImgnameLoaded=$(echo $Result| awk -F: '{  print $2 }' | sed 's/ //g' )

for im in "${REGISTRIES[@]}";do
	if [[ ${ImgnameLoaded%%/*} == $im  ]];then
		echo "========== the detected registry name: " $im
		ImgnameOnly=$(echo $ImgnameLoaded | sed "s/$im//" | sed 's+/++')
		break;

	else
		echo "=========== Registry not detected. The searched registry name " $im;
		ImgnameOnly=$ImgnameLoaded
	fi 
done;

echo Info: 1-ImgnamewithTar  :: 2-ImgnamewithTag  :: 3-ImgnameOnly :: 4-ImgnameTagOnly :: 5-ImgnameLoaded :: 6-ImgnameTagnumberOnly
echo Info: 1-$ImgnamewithTar  :: 2-$ImgnamewithTag  :: 3-$ImgnameOnly :: 4-$ImgnameTagOnly :: 5-$ImgnameLoaded :: 6-$ImgnameTagnumberOnly

# Some version number start with 'v' and some version number just start with number. So I upload both if version number in upstream start with 'v'.
docker tag $ImgnameLoaded:$ImgnameTagOnly localhost/$ImgnameOnly:$ImgnameTagOnly
docker tag $ImgnameLoaded:$ImgnameTagOnly localhost/$ImgnameOnly:latest
docker tag $ImgnameLoaded:$ImgnameTagOnly localhost/$ImgnameOnly:$ImgnameTagnumberOnly
docker push localhost/$ImgnameOnly:$ImgnameTagOnly
docker push localhost/$ImgnameOnly:latest
docker push localhost/$ImgnameOnly:$ImgnameTagnumberOnly

docker image rm localhost/$ImgnameOnly:$ImgnameTagOnly
docker image rm localhost/$ImgnameOnly:latest
docker image rm $ImgnameLoaded:$ImgnameTagOnly
docker image rm localhost/$ImgnameOnly:$ImgnameTagnumberOnly

done

}

Local_registry_remove () {

docker container rm -f suse-registry;
rm -rf /etc/docker_registry
rm -rf /var/lib/docker/registry

#clean up images which are loaded on this machine.
#docker images | grep -v REPOSITORY| awk '{print "docker image rm "$3   }' | bash
}

ChangeMy-clusterToLocalRegistry () {

Debug_print $'find ~/my-cluster -type f  | xargs grep -i registry | awk -F: $\'{ print " sed -i \\'s+registry.suse.com+$MGMT_FQDN+g\\' "$1"  "  }\' | bash'
find ~/my-cluster -type f  | xargs grep -i registry | awk -F: $'{ print " sed -i \'s+registry.suse.com+$MGMT_FQDN+g\' "$1"  "  }' | bash

}

HelmLocalChartRepoDeployment() {

local LOCALCHARTS="localcharts"

zypper --non-interactive in helm

cd $froLOCAL_REPO_DIR/helm_local_repo;
echo "pwd : $PWD"
## Don't have to change registry information because crio container registry proxy.
#for i in $(ls $froLOCAL_REPO_DIR/helm_local_repo | egrep 'tgz$');do
#	tar xvfz $i -C $froLOCAL_REPO_DIR/helm_local_repo --overwrite
#	CHART=${i%-*}
#	sed -i 's/www.changeme.com/$MGMT_FQDN/g' $froLOCAL_REPO_DIR/helm_local_repo/$CHART/values.yaml
#	tar cvfz $i $CHART --overwrite
#	rm -rf $froLOCAL_REPO_DIR/helm_local_repo/$CHART
#done

# helm init --client-only
helm init --client-only

cat << EOF > /root/.helm/repository/repositories.yaml
apiVersion: v1
generated: "2019-10-01T13:14:33.041010765+09:00"
repositories:
EOF

# helm repo index creation
helm repo index $froLOCAL_REPO_DIR/helm_local_repo --url http://$MGMT_FQDN:9001;

# Create web server for helm chart repo and register this in repo list
# Add localcharts if localcharts doesn't exists
Debug_print $'RESULT=$(helm repo list | awk -v V1=\^$LOCALCHARTS\' \'{if($1~V1) print $1 }\')'
RESULT=$(helm repo list | awk -v V1="^$LOCALCHARTS" '{if($1~V1) print $1 }')
echo $RESULT

if [[ ! $RESULT =~ $LOCALCHARTS ]]; then
	screen -dm helm serve --repo-path $froLOCAL_REPO_DIR/helm_local_repo --address $MGMT_FQDN:9001
	echo "sleep 10 sec until webserver up..."
	for i in {10..1};do sleep 1; echo -n $i..;done;echo;
	helm repo add $LOCALCHARTS http://$MGMT_FQDN:9001
else 
	echo "localcharts already exists. Start helm serve, if there is no 9001 listening port";
	#Debug_print $'ss -pltne | grep \':9001\' || screen -dm helm serve --repo-path $froLOCAL_REPO_DIR/helm_local_repo --address $MGMT_FQDN:9001'
	ss -pltne | grep ':9001' || screen -dm helm serve --repo-path $froLOCAL_REPO_DIR/helm_local_repo --address $MGMT_FQDN:9001
fi

Debug helm repo update

}


StorageclassPVCwithCephRBD() {

Debug kubectl create namespace monitoring

#Deploy ceph-common
Debug zypper --non-interactive in ceph-common

#Locate ceph keyring and ceph.conf file in $froLOCAL_REPO_DIR/ceph_conf
mkdir -p $froLOCAL_REPO_DIR/ceph_conf
Debug scp -o StrictHostKeyChecking=no -r $CEPH_ADMIN_IP:/etc/ceph/ceph* $froLOCAL_REPO_DIR/ceph_conf/
Debug cm-scp $froLOCAL_REPO_DIR/ceph_conf/ceph* /etc/ceph/;

CEPH_SECRET=$(ceph auth get-key client.admin)
Debug_print kubectl -n kube-system apply for ceph-secret-admin
kubectl -n kube-system apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-admin
type: "kubernetes.io/rbd"
data:
  key: "$(echo $CEPH_SECRET | base64)"
EOF
Debug_print kubectl -n monitoring apply for ceph-secret-admin
kubectl -n monitoring apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-admin
type: "kubernetes.io/rbd"
data:
  key: "$(echo $CEPH_SECRET | base64)"
EOF
Debug_print kubectl apply for ceph-secret-admin
kubectl apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-admin
type: "kubernetes.io/rbd"
data:
  key: "$(echo $CEPH_SECRET | base64)"
EOF

local CEPH_POOL="caasp-demo"
local CEPH_USER="caaspuserdemo"
ceph osd pool create $CEPH_POOL 128 128
## Replication size to 1. No redundancy. Not recommened for production.
ceph osd pool set $CEPH_POOL min_size 1
ceph osd pool set $CEPH_POOL size 1
ceph auth get-or-create client.$CEPH_USER mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=$CEPH_POOL" -o ceph.client.user.keyring

local USER_SECRET=$(ceph auth get-key client.$CEPH_USER)
Debug_print kubectl -n kube-system apply for ceph-secret-user
kubectl -n kube-system apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-user
type: "kubernetes.io/rbd"
data:
  key: "$(echo $USER_SECRET | base64)"
EOF
Debug_print kubectl -n monitoring apply for ceph-secret-user
kubectl -n monitoring apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-user
type: "kubernetes.io/rbd"
data:
  key: "$(echo $USER_SECRET | base64)"
EOF
Debug_print kubectl apply for ceph-secret-user
kubectl apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-user
type: "kubernetes.io/rbd"
data:
  key: "$(echo $USER_SECRET | base64)"
EOF


# SotrageClass will be shared across all namespace
Debug_print kubectl apply for $STORAGECLASS storageclass
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: $STORAGECLASS
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/rbd
parameters:
  monitors: $CEPH_MONITOR_IP_PORT1, $CEPH_MONITOR_IP_PORT2, $CEPH_MONITOR_IP_PORT3
  adminId: admin
  adminSecretName: ceph-secret-admin
  adminSecretNamespace: default
  pool: $CEPH_POOL
  userId: $CEPH_USER
  userSecretName: ceph-secret-user
EOF


#kubectl -n monitoring apply -f - << EOF
#kind: PersistentVolumeClaim
#apiVersion: v1
#metadata:
#  name: cephtest-pvc
#spec:
#  accessModes:
#  - ReadWriteOnce
#  resources:
#    requests:
#      storage: 2Gi
#EOF



#kubectl -n monitoring apply -f - << EOF
#apiVersion: v1
#kind: Pod
#metadata:
#  name: storageclass-pod
#spec:
#  containers:
#  - name: nginx-storageclass
#    image: caasp-lb.suse.su/nginx
#    volumeMounts:
#    - name: rbdvol
#      mountPath: /mnt
#      readOnly: false
#  volumes:
#  - name: rbdvol
#    persistentVolumeClaim:
#      claimName: cephtest-pvc
#
#EOF

}


StratosDeployment () {

Debug helm install localcharts/console --name stratos-console --namespace monitoring --values $froLOCAL_REPO_DIR/helm_conf/stratos-values.yaml

}

LoadbalancerDeploymentforS3 () {

local S3FQDN="s3gw.sapdemo.lab"
local LB_IP="192.168.200.123"	

## Self signed certificate
Debug openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/s3tls.key -out /tmp/s3tls.crt -subj "/CN=$S3FQDN"
cat /tmp/s3tls.crt /tmp/s3tls.key | tee /tmp/s3tls.pem 
# Remove DOS-type carraige return
tr -d '\r' < /tmp/s3tls.crt > /tmp/s3tls.pem
Debug echo "Upload the cert, /tmp/s3tls.pem, for s3 gateway to DI connection management!!"

Debug cp /tmp/s3tls.pem /etc/docker_haproxy/

#Debug docker container rm -f haproxy;

mkdir -p /etc/docker_haproxy
cat << EOF > /etc/docker_haproxy/haproxy.cfg
global
#Disable log below after you debug haproxy
#  log /dev/log local0 info
  daemon

defaults
  log     global
  mode    tcp
  option  tcplog
  option  redispatch
  option  tcpka
  option  dontlognull
  retries 2
  maxconn 2000
  timeout connect   5s
  timeout client    5s
  timeout server    5s
  timeout tunnel    86400s

frontend s3gateway
    bind :7490 ssl crt /etc/haproxy/s3tls.pem
    mode http
    timeout client 5s
    default_backend s3gateway

backend s3gateway
    mode http
    balance roundrobin
    option forwardfor
    option httpchk HEAD / HTTP/1.1\r\nHost:localhost
    server ses1 192.168.200.111:7480 check
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request add-header X-Forwarded-Proto https if { ssl_fc }
    

EOF

docker load -i $froLOCAL_REPO_DIR/docker_images_file/haproxy.1.8.tar
docker run -d -p 7490:7490  --name haproxy -v /etc/docker_haproxy/s3tls.pem:/etc/haproxy/s3tls.pem  -v /etc/docker_haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg haproxy:1.8 -f /etc/haproxy/haproxy.cfg

ip addr add $LB_IP/24 dev br0 brd +

}



LoadbalancerDeployment () {

#zypper --non-interactive in docker;
#systemctl start docker; systemctl enable docker;
Debug docker container rm -f haproxy;

mkdir -p /etc/docker_haproxy
cat << EOF > /etc/docker_haproxy/haproxy.cfg
global
#Disable log below after you debug haproxy
#  log /dev/log local0 info
  daemon

defaults
  log     global
  mode    tcp
  option  tcplog
  option  redispatch
  option  tcpka
  option  dontlognull
  retries 2
  maxconn 2000
  timeout connect   5s
  timeout client    5s
  timeout server    5s
  timeout tunnel    86400s

frontend k8s-api
    bind :6443
    timeout client 5s
    default_backend k8s-api

backend k8s-api
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:6443 check
#        server ${MASTER[1]} ${MASTER_IP[1]}:6443 check
#        server ${MASTER[2]} ${MASTER_IP[2]}:6443 check

frontend dex
    bind :32000
    timeout client 5s
    default_backend dex

backend dex
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:32000 check
#        server ${MASTER[1]} ${MASTER_IP[1]}:32000 check
#        server ${MASTER[2]} ${MASTER_IP[2]}:32000 check

frontend gangway
    bind :32001
    timeout client 5s
    default_backend dex

backend gangway
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:32001 check
#        server ${MASTER[1]} ${MASTER_IP[1]}:32001 check
#        server ${MASTER[2]} ${MASTER_IP[2]}:32001 check

EOF

docker load -i $froLOCAL_REPO_DIR/docker_images_file/haproxy.1.8.tar
docker run -d -p 6443:6443 -p 32000:32000 -p 32001:32001 --name haproxy -v /etc/docker_haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg haproxy:1.8 -f /etc/haproxy/haproxy.cfg

ip addr add $LB_IP/24 dev eth0 brd +

}

LoadbalancerDeploymentwithThreeMaster () {

#zypper --non-interactive in docker;
#systemctl start docker; systemctl enable docker;
Debug docker container rm -f haproxy;

mkdir -p /etc/docker_haproxy
cat << EOF > /etc/docker_haproxy/haproxy.cfg
global
#Disable log below after you debug haproxy
#  log /dev/log local0 info
  daemon

defaults
  log     global
  mode    tcp
  option  tcplog
  option  redispatch
  option  tcpka
  option  dontlognull
  retries 2
  maxconn 2000
  timeout connect   5s
  timeout client    5s
  timeout server    5s
  timeout tunnel    86400s

frontend k8s-api
    bind :6443
    timeout client 5s
    default_backend k8s-api

backend k8s-api
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:6443 check
        server ${MASTER[1]} ${MASTER_IP[1]}:6443 check
        server ${MASTER[2]} ${MASTER_IP[2]}:6443 check

frontend dex
    bind :32000
    timeout client 5s
    default_backend dex

backend dex
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:32000 check
        server ${MASTER[1]} ${MASTER_IP[1]}:32000 check
        server ${MASTER[2]} ${MASTER_IP[2]}:32000 check

frontend gangway
    bind :32001
    timeout client 5s
    default_backend dex

backend gangway
    option tcp-check
        timeout server 5s
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

	server ${MASTER[0]} ${MASTER_IP[0]}:32001 check
        server ${MASTER[1]} ${MASTER_IP[1]}:32001 check
        server ${MASTER[2]} ${MASTER_IP[2]}:32001 check

EOF

docker load -i $froLOCAL_REPO_DIR/docker_images_file/haproxy.1.8.tar
docker run -d -p 6443:6443 -p 32000:32000 -p 32001:32001 --name haproxy -v /etc/docker_haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg haproxy:1.8 -f /etc/haproxy/haproxy.cfg

ip addr add $LB_IP/24 dev eth0 brd +

}


NginxIngressControllerDeployment () {


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
    enableHttp: false
   # enableHttp: true
    type: NodePort
    nodePorts:
      https: 30443

EOF

Debug kubectl create namespace nginx-ingress
Debug helm install --name nginx-ingress localcharts/nginx-ingress --namespace nginx-ingress --values /tmp/nginx-ingress-config-values.yaml
#Debug helm upgrade nginx-ingress localcharts/nginx-ingress --namespace nginx-ingress --values /tmp/nginx-ingress-config-values.yaml

}

MonitoringStackDeployment() {

local MON_CONFIG_DIR="/etc/caasp_monitoring"
Debug kubectl create namespace monitoring


## Prometheus deployment
mkdir -p  $MON_CONFIG_DIR
cp ~/cmd_cert/demoCA/private/monitoring_key.pem $MON_CONFIG_DIR/
cp ~/cmd_cert/demoCA/certs/monitoring_crt.pem $MON_CONFIG_DIR/

Debug kubectl create -n monitoring secret tls monitoring-tls --key $MON_CONFIG_DIR/monitoring_key.pem --cert $MON_CONFIG_DIR/monitoring_crt.pem

Debug zypper --non-interactive in apache2-utils
echo;
echo "Create password for admin login"
Debug htpasswd -c $MON_CONFIG_DIR/auth admin

Debug kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=$MON_CONFIG_DIR/auth

## Create secret for ETCD monitoring
mkdir -p $MON_CONFIG_DIR/etcd;
Debug scp ${MASTER_IP[0]}:/etc/kubernetes/pki/etcd/* $MON_CONFIG_DIR/etcd/;

Debug kubectl -n monitoring create secret generic etcd-certs --from-file=$MON_CONFIG_DIR/etcd/ca.crt --from-file=$MON_CONFIG_DIR/etcd/healthcheck-client.crt --from-file=$MON_CONFIG_DIR/etcd/healthcheck-client.key

cat << EOF > $MON_CONFIG_DIR/prometheus-config-values.yaml
# Alertmanager configuration
alertmanager:
  enabled: true
  ingress:
    enabled: true
    hosts:
    -  prometheus-alertmanager.$DOMAIN
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: prometheus-basic-auth
      nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
     # nginx.ingress.kubernetes.io/server-alias: prometheus-alertmanager.$DOMAIN
    tls:
      - hosts:
        - prometheus-alertmanager.$DOMAIN
        secretName: monitoring-tls
  persistentVolume:
    enabled: true
    ## Use a StorageClass
    storageClass: $STORAGECLASS
    ## Create a PersistentVolumeClaim of 2Gi
    size: 2Gi
    ## Use an existing PersistentVolumeClaim (my-pvc)
    #existingClaim: my-pvc

## Alertmanager is configured through alertmanager.yml. This file and any others
## listed in alertmanagerFiles will be mounted into the alertmanager pod.
## See configuration options https://prometheus.io/docs/alerting/configuration/
#alertmanagerFiles:
#  alertmanager.yml:

# Create a specific service account
serviceAccounts:
  nodeExporter:
    name: prometheus-node-exporter

# Allow scheduling of node-exporter on master nodes
nodeExporter:
  hostNetwork: false
  hostPID: false
  podSecurityPolicy:
    enabled: true
    annotations:
      apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
      apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
      seccomp.security.alpha.kubernetes.io/allowedProfileNames: runtime/default
      seccomp.security.alpha.kubernetes.io/defaultProfileName: runtime/default
  tolerations:
    - key: node-role.kubernetes.io/master
      operator: Exists
      effect: NoSchedule

# Disable Pushgateway
pushgateway:
  enabled: false

# Prometheus configuration
server:
  ingress:
    enabled: true
    hosts:
    - prometheus.$DOMAIN
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: prometheus-basic-auth
      nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
     # nginx.ingress.kubernetes.io/server-alias: prometheus-server.$DOMAIN
     # nginx.ingress.kubernetes.io/auth-realm: prom.$DOMAIN
    tls:
      - hosts:
        - prometheus.$DOMAIN
        secretName: monitoring-tls
  persistentVolume:
    enabled: true
    ## Use a StorageClass
    storageClass: $STORAGECLASS
    ## Create a PersistentVolumeClaim of 8Gi
    size: 8Gi
    ## Use an existing PersistentVolumeClaim (my-pvc)
    #existingClaim: my-pvc
  ## Additional Prometheus server Secret mounts
  # Defines additional mounts with secrets. Secrets must be manually created in the namespace.
  extraSecretMounts:
  - name: etcd-certs
    mountPath: /etc/secrets
    secretName: etcd-certs
    readOnly: true

## Prometheus is configured through prometheus.yml. This file and any others
## listed in serverFiles will be mounted into the server pod.
## See configuration options
## https://prometheus.io/docs/prometheus/latest/configuration/configuration/
#serverFiles:
#  prometheus.yml:

## The Alertmanager configuration
alertmanagerFiles:
  alertmanager.yml:
    global:
      # The smarthost and SMTP sender used for mail notifications.
      smtp_from: alertmanager@$DOMAIN
      smtp_smarthost: smtp.$DOMAIN:587
      smtp_auth_username: admin@$DOMAIN
      smtp_auth_password: <PASSWORD>
      smtp_require_tls: true

    route:
      # The labels by which incoming alerts are grouped together.
      group_by: ['node']

      # When a new group of alerts is created by an incoming alert, wait at
      # least 'group_wait' to send the initial notification.
      # This way ensures that you get multiple alerts for the same group that start
      # firing shortly after another are batched together on the first
      # notification.
      group_wait: 30s

      # When the first notification was sent, wait 'group_interval' to send a batch
      # of new alerts that started firing for that group.
      group_interval: 5m

      # If an alert has successfully been sent, wait 'repeat_interval' to
      # resend them.
      repeat_interval: 3h

      # A default receiver
      receiver: admin-example

    receivers:
    - name: 'admin-example'
      email_configs:
      - to: 'admin@$DOMAIN'
serverFiles:
  alerts: {}
  rules:
    groups:
    - name: caasp.node.rules
      rules:
      - alert: NodeIsNotReady
        expr: kube_node_status_condition{condition="Ready",status="false"} == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          description: '{{ $labels.node }} is not ready'
      - alert: NodeIsOutOfDisk
        expr: kube_node_status_condition{condition="OutOfDisk",status="true"} == 1
        labels:
          severity: critical
        annotations:
          description: '{{ $labels.node }} has insufficient free disk space'
      - alert: NodeHasDiskPressure
        expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
        labels:
          severity: warning
        annotations:
          description: '{{ $labels.node }} has insufficient available disk space'
      - alert: NodeHasInsufficientMemory
        expr: kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
        labels:
          severity: warning
        annotations:
          description: '{{ $labels.node }} has insufficient available memory'

EOF

Debug helm install --name prometheus localcharts/prometheus --namespace monitoring --values $MON_CONFIG_DIR/prometheus-config-values.yaml

## Grafana deployment
cat << EOF > $MON_CONFIG_DIR/grafana-datasources.yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: grafana-datasources
  namespace: monitoring
  labels:
     grafana_datasource: "1"
data:
  datasource.yaml: |-
    apiVersion: 1
    deleteDatasources:
      - name: Prometheus
        orgId: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.monitoring.svc.cluster.local:80
      access: proxy
      orgId: 1
      isDefault: true
EOF

Debug kubectl -n monitoring create -f $MON_CONFIG_DIR/grafana-datasources.yaml

cat << EOF > $MON_CONFIG_DIR/grafana-config-values.yaml
# Configure admin password
adminPassword: changeme

# Ingress configuration
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
#    kubernetes.io/ingress.class: nginx
  hosts:
    - grafana.$DOMAIN
  tls:
    - hosts:
      - grafana.$DOMAIN
      secretName: monitoring-tls

# Configure persistent storage
persistence:
  enabled: true
  accessModes:
    - ReadWriteOnce
  ## Use a StorageClass
  storageClassName: $STORAGECLASS
  ## Create a PersistentVolumeClaim of 10Gi
  size: 10Gi
  ## Use an existing PersistentVolumeClaim (my-pvc)
  #existingClaim: my-pvc

# Enable sidecar for provisioning
sidecar:
  datasources:
    enabled: true
    label: grafana_datasource
  dashboards:
    enabled: true
    label: grafana_dashboard

EOF

Debug helm install --name grafana localcharts/grafana --namespace monitoring --values $MON_CONFIG_DIR/grafana-config-values.yaml

## grafana dashboard configmap copied from https://github.com/SUSE/caasp-monitoring
Debug cp $froLOCAL_REPO_DIR/my-tool/k8s/grafana/*.yaml $MON_CONFIG_DIR/

Debug kubectl -n monitoring apply -f $MON_CONFIG_DIR/grafana-dashboards-caasp-cluster.yaml
Debug kubectl -n monitoring apply -f $MON_CONFIG_DIR/grafana-dashboards-caasp-etcd-cluster.yaml
Debug kubectl -n monitoring apply -f $MON_CONFIG_DIR/grafana-dashboards-caasp-namespaces.yaml
Debug kubectl -n monitoring apply -f $MON_CONFIG_DIR/grafana-dashboards-caasp-nodes.yaml
Debug kubectl -n monitoring apply -f $MON_CONFIG_DIR/grafana-dashboards-caasp-pods.yaml


echo;echo;
echo 'Prometheus Expression browser/API : (NodePort)https://prometheus.$DOMAIN:30443'
echo 'Alertmanager : https://prometheus-alertmanager.$DOMAIN:30443'
echo 'Grafana : https://grafana.$DOMAIN:30443'
}

MonitoringETCDCluster() {


echo "Check the private IP address"
Debug kubectl get pods -n kube-system -l component=etcd -o wide

echo "Configure with 'kubectl edit -n monitoring configmap prometheus-server' as follows "
cat << EOF >&1
# Put under scrape_configs
#   scrape_configs:
    - job_name: etcd
      static_configs:
      - targets: ['${MASTER_IP[0]}:2379','${MASTER_IP[1]}:2379','${MASTER_IP[2]}:2379']
      scheme: https
      tls_config:
        ca_file: /etc/secrets/ca.crt
        cert_file: /etc/secrets/healthcheck-client.crt
        key_file: /etc/secrets/healthcheck-client.key
EOF


}


SMTPsender() {

Debug zypper --non-interactive in postfix
Debug sed -i "s+#mynetworks = 168.100.189.0/28, 127.0.0.0/8+mynetworks = 192.168.0.0/16, 127.0.0.0/8+g" /etc/postfix/main.cf
Debug sed -i "s+inet_interfaces = localhost+inet_interfaces = all+g" /etc/postfix/main.cf
Debug systemctl enable postfix
Debug systemctl restart postfix

echo "Port 25 opened for SMTP sender"

}

RsyslogserverDeployment () {

mkdir -p /var/lib/docker/rsyslog
touch /var/lib/docker/rsyslog/syslog

Debug docker image pull $MGMT_FQDN/robbert229/rsyslog:latest
Debug docker run -d -p 514:514/udp -p 514:514 --name rsyslogserver -v /root/local_repo:/root/local_repo -v /var/lib/docker/rsyslog/syslog:/var/log/syslog $MGMT_FQDN/robbert229/rsyslog:latest

echo;echo;echo;echo;
echo "########################################################################################"
echo "Syslogs sented to this rsyslog server will be stored at /var/lib/docker/rsyslog/syslog"
echo "Watch log by 'tail -f /var/lib/docker/rsyslog/syslog', once this syslog servers get syslogs from others"
}

CentralizedLoggingAgent () {

Debug kubectl create namespace clogging

Debug helm install --namespace=clogging localcharts/log-agent-rsyslog --name rsyslog-agent --set server.host=$MGMT_IP --set server.port=514 --set server.protocol=UDP	

}

PreparationBeforeDemo () {

#Debug scp -r 192.168.37.15:/root/my-tool/cm-* /usr/bin/
echo "Change haproxy.cfg with one master node and Run below"
read

LoadbalancerDeployment on_GRP1 

echo 'ip addr add $LB_IP/24 dev eth0 brd +' >> /root/admin/start_service.sh
Debug bash /root/admin/start_service.sh
Debug ssh -o StrictHostKeyChecking=no 192.168.37.75 ceph osd pool delete caasp-demo caasp-demo --yes-i-really-really-mean-it
Debug rm -rf /root/my-cluster

echo "Increase Worker memory to 3072"

cat << EOF > /root/admin/nginx-deployment-service.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: $MGMT.$DOMAIN/nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: 30999
  selector:
      app: nginx
EOF

}


UpdateNodes () {

#Debug zypper --non-interactive up skuba;
cd /root/my-cluster;eval "$(ssh-agent)";ssh-add /home/sles/.ssh/id_rsa;


## Node Updates have to be applied separately to each node, starting with the control plane all the way down to the worker nodes.
## During the upgrade all the pods in the worker node will be restarted so it is recommended to drain the pods if your application requires high availability. In most cases, the restart is handled by replicaSet.
#Debug skuba cluster upgrade plan;
#Debug skuba -v 5 node upgrade apply --target ${MASTER_IP[0]} --user sles --sudo
#Debug skuba node upgrade apply --target ${WORKER_IP[0]} --user sles --sudo

# Addon Updates
Debug skuba addon upgrade plan;
#ChangeMy-clusterToLocalRegistry
Debug skuba -v 5 addon upgrade apply 



}

Registry_proxy () {

Debug mkdir -p /etc/containers	
Debug_print Add proxy configuraion in /etc/containers/registries.conf 
cat << EOF > /etc/containers/registries.conf
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "registry.suse.com"
location = "$MGMT_FQDN"
[[registry]]
prefix = "docker.io"
location = "$MGMT_FQDN"
[[registry]]
prefix = "docker.io/library"
location = "$MGMT_FQDN"
[[registry]]
prefix = "quay.io"
location = "$MGMT_FQDN"
[[registry]]
prefix = "k8s.gcr.io"
location = "$MGMT_FQDN"
[[registry]]
prefix = "registry.opensuse.org/kubic"
location = "$MGMT_FQDN/caasp/v4"

#[[registry]]
#prefix = "registry.suse.com"
#location = "registry01.mydomain.local:5000/registry.suse.com"
#[[registry]]
#prefix = "docker.io"
#location = "registry01.mydomain.local:5000/docker.io"
#[[registry]]
#prefix = "docker.io/library"
#location = "registry01.mydomain.local:5000/docker.io"
#[[registry]]
#prefix = "quay.io"
#location = "registry01.mydomain.local:5000/quay.io"
#[[registry]]
#prefix = "k8s.gcr.io"
#location = "registry01.mydomain.local:5000/k8s.gcr.io"
#[[registry]]
#prefix = "gcr.io"
#location = "registry01.mydomain.local:5000/gcr.io"
EOF

if [[ $(systemctl list-unit-files | grep crio.service) =~ "crio" ]]; then 
	Debug	systemctl restart crio.service
fi;

}

start_ManagementComponentsAfterReboot () {

# Start docker service
Debug systemctl start docker

# Start registry
Debug docker start suse-registry

# Add VIP
Debug ip addr add $LB_IP/24 dev eth0 brd +

# Start load Balancer
Debug docker start haproxy

# Start helm serve
Debug screen -dm helm serve --repo-path $froLOCAL_REPO_DIR/helm_local_repo --address $MGMT_FQDN:9001
}


## SAP related
SAPDHConfiguration1 () {
# Packages for storage
Debug zypper --non-interactive in xfsprogs ceph-common

# Pids_limit = 8192 on CaaSP
Debug sed -i 's/pids_limit = 1024/pids_limit = 8192/g' /etc/crio/crio.conf

# Edit registry.conf on CaaSP
Debug_print 'Modify /etc/containers/registries.conf'
cat << EOF >> /etc/containers/registries.conf
[["$MGMT_FQDN:5000"]]
insecure = false
prefix = "$MGMT_FQDN:5000"
location = "$MGMT_FQDN"
EOF

Debug systemctl restart crio

}

SAPDHConfiguration2 () {

# zypper in python2-pyOpenSSL on Management
Debug zypper --non-interactive in docker python2-PyYAML python2-pyOpenSSL

# create namespace for datahub27 on Management
Debug kubectl create namespace $SAPDHNAMESPACE

# Pod Security Policy on Management
#sed -i 's+pathPrefix: /opt/kubernetes-hostpath-volumes+pathPrefix: /+g' ~/my-cluster/addons/psp/psp.yaml
#Debug kubectl apply -f ~/my-cluster/addons/psp/psp.yaml

Debug_print "Add texts at the end below of 'kubectl edit psp suse.caasp.psp.privileged'" 

cat << EOF >&1
  allowedHostPaths:
  - pathPrefix: /
EOF

local INGRESS_NAMESPACE=$(kubectl get pods -o wide --all-namespaces | awk '{if($2~/^nginx-ingress/) NAMESPACE=$1  } END{ print NAMESPACE }')
local INGRESS_SA=$(kubectl get -n nginx-ingress  serviceaccounts -lapp=nginx-ingress -o name | awk -F/ '{print $2}')

# Role binding with service account
Debug_print "Clusterrole binding with new psp"
kubectl -n kube-system apply -f - << EOF 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: suse:caasp:psp:priviliged:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: suse:caasp:psp:privileged
subjects:
- kind: ServiceAccount
  name: default
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: vora-vsystem-$SAPDHNAMESPACE
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: vora-vsystem-$SAPDHNAMESPACE-vrep
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: $SAPDHNAMESPACE-elasticsearch
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: $SAPDHNAMESPACE-fluentd
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: $SAPDHNAMESPACE-nodeexporter
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: vora-vflow-server
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: mlf-deployment-api
  namespace: $SAPDHNAMESPACE
- kind: ServiceAccount
  name: $INGRESS_SA
  namespace: $INGRESS_NAMESPACE
EOF


Debug_print "Add texts below at the end of 'kubectl edit clusterrolebinding system:node' "

cat << EOF >&1
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
EOF

## This can be done if new ingress controller deployed after SAP DH deployment
# psp rolebinding for ingress controller 
#local INGRESS_NAMESPACE=$(kubectl get pods -o wide --all-namespaces | awk '{if($2~/^nginx-ingress/) NAMESPACE=$1  } END{ print NAMESPACE }')
#local INGRESS_SA=$(kubectl get -n nginx-ingress  serviceaccounts -lapp=nginx-ingress -o name | awk -F/ '{print $2}')

#Debug_print "Add texts below at the end of 'kubectl edit clusterrolebinding  suse:caasp:psp:priviliged:default'"
#cat << EOF >&1
#- kind: ServiceAccount
#  name: $INGRESS_SA
#  namespace: $INGRESS_NAMESPACE
#EOF



}

SAPDHConfiguration3 () {

## Configure for private registry certificates
Debug cp /etc/docker_registry/certs/monitoring_crt2.pem /etc/docker_registry/certs/cert_with_carriage_return
tr -d '\r' < /etc/docker_registry/certs/cert_with_carriage_return > /etc/docker_registry/certs/cert
kubectl create secret generic cmcertificates --from-file=/etc/docker_registry/certs/cert -n $SAPDHNAMESPACE

## This can be done if new ingress controller deployed after SAP DH deployment
# psp rolebinding for ingress controller 
local INGRESS_NAMESPACE=$(kubectl get pods -o wide --all-namespaces | awk '{if($2~/^nginx-ingress/) NAMESPACE=$1  } END{ print NAMESPACE }')
local INGRESS_SA=$(kubectl get -n nginx-ingress  serviceaccounts -lapp=nginx-ingress -o name | awk -F/ '{print $2}')

Debug_print "Add texts below at the end of 'kubectl edit clusterrolebinding  suse:caasp:psp:priviliged:default'"
cat << EOF >&1
- kind: ServiceAccount
  name: $INGRESS_SA
  namespace: $INGRESS_NAMESPACE
EOF

local CEPH_SECRET=$(ceph auth get-key client.admin)
Debug_print kubectl -n $SAPDHNAMESPACE apply for ceph-secret-admin
kubectl -n $SAPDHNAMESPACE apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-admin
  namespace: $SAPDAHNAMESPACE
type: "kubernetes.io/rbd"
data:
  key: "$(echo $CEPH_SECRET | base64)"
EOF

local CEPH_USER="caaspuserdemo"
local USER_SECRET=$(ceph auth get-key client.$CEPH_USER)
## user for DI30
Debug_print kubectl -n $SAPDHNAMESPACE apply for ceph-secret-user
kubectl -n  $SAPDHNAMESPACE apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret-user
  namespace: $SAPDAHNAMESPACE
type: "kubernetes.io/rbd"
data:
  key: "$(echo $USER_SECRET | base64)"
EOF

}

Ingress_vsystem() {
## Prerequesite
## Ingress controller is already deployed and working
local DIFQDN="di.pntdemo.kr"
local SAPDHNAMESPACE="di30"
## Self signed certificate
#Debug openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=$DIFQDN"

## create secret for the certificate
#Debug kubectl -n $SAPDHNAMESPACE create secret tls vsystem-tls-certs --key /tmp/tls.key --cert /tmp/tls.crt


## Create ingress
Debug_print "kubectl apply"
kubectl -n $SAPDHNAMESPACE apply -f - << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: vsystem
 annotations:
   kubernetes.io/ingress.class: nginx
   nginx.ingress.kubernetes.io/secure-backends: "true"
   nginx.ingress.kubernetes.io/backend-protocol: HTTPS
   nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
   nginx.ingress.kubernetes.io/proxy-body-size: "500m"
   nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
   nginx.ingress.kubernetes.io/proxy-read-timeout: "1800"
   nginx.ingress.kubernetes.io/proxy-send-timeout: "1800"
   nginx.ingress.kubernetes.io/proxy-buffer-size: "16k"
   nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
 tls:
 - hosts:
   - $DIFQDN
   secretName: vsystem-tls-certs
 rules:
 - host: $DIFQDN
   http:
     paths:
     - path: /
       backend:
         serviceName: vsystem
         servicePort: 8797

EOF

Debug "echo Try to access vsystem service at https://$DIFQDN:30443"

}



Test () {
Debug echo "test"
}


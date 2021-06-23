#!/bin/bash

echo ""

SshKnownhost () {


j=${#HOSTNAME_TOTAL[@]};
#for i in {0..$j} ;
for (( i=0; i < $j; i++ ));
do
	#Debug_print $'ssh-keyscan -t ecdsa-sha2-nistp256 $IP_TOTAL[$i] >> ~/.ssh/known_hosts'
	ssh-keyscan -t ecdsa-sha2-nistp256 ${IP_TOTAL[$i]} >> ~/.ssh/known_hosts

done;


}


RegisterRepositories () {

scp -o StrictHostKeyChecking=no $MGMT_IP:$froLOCAL_REPO_DIR/register_client.sh ~/
scp -o StrictHostKeyChecking=no $MGMT_IP:$froLOCAL_REPO_DIR/created_repo_list* ~/
Debug ./register_client.sh $MGMT_IP



}

RegistertoSMT () {

#echo '192.168.37.17 smt.suse smt' >> /etc/hosts	
#Debug SUSEConnect --url http://smt.suse
#Debug SUSEConnect --url http://smt.suse -p ses/7/x86_64
#Debug SUSEConnect --url http://smt.suse -p sle-ha/15.2/x86_64
Debug SUSEConnect --url http://smt.suse -p sle-module-containers/15.2/x86_64
Debug SUSEConnect --url http://smt.suse -p sle-module-desktop-applications/15.2/x86_64


}



MyToolDeployment () {

if [[ -a $fre_MY_TOOL_INSTALLED_DIR/cm- ]]
then
	Debug echo "my-tool deployed"
else
	for i in cm- cm-scp;
	do ln -sf $froLOCAL_REPO_DIR/my-tool/$i $fre_MY_TOOL_INSTALLED_DIR/$i
	done;
fi
## Hostlist generation
echo "## Others Nodes" > ~/hostlist;
for i in ${GRP2[@]};
do
	echo $i >> ~/hostlist	
done;
echo "## MGMT Nodes" >> ~/hostlist;
echo ${GRP1[0]} >> ~/hostlist;

}

## SCP_RUN Framework Ends    ##

## workload function started from here

EtcHosts () {

j=0;for i in "${HOSTNAME_TOTAL[@]}"; do

#hostnames match but ip address is different
cat /etc/hosts | awk -v V1="${IP_TOTAL[$j]}" -v V2="${HOSTNAME_TOTAL[$j]}" $'{
split($2,a,".")
if(a[1]==V2 && $1!=V1) print "sed -i \'s/"$0"/#"$0"/g\' /etc/hosts"
}'|bash 
#if there is no hostname
cat /etc/hosts | grep -v ^# |  grep -w ${HOSTNAME_TOTAL[$j]} ||echo "${IP_TOTAL[$j]} $i.$DOMAIN $i" >> /etc/hosts

(( j=j+1 ));done

}

BasicNetwork () {
##disable ipv6 for all
echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/ipv6.conf

##resolv.conf for all
Debug sed -i "s/NETCONFIG_DNS_STATIC_SEARCHLIST=\"\"/NETCONFIG_DNS_STATIC_SEARCHLIST=\"$DOMAIN\"/g" /etc/sysconfig/network/config
Debug sed -i "s/NETCONFIG_DNS_STATIC_SERVERS=\"\"/NETCONFIG_DNS_STATIC_SERVERS=\"$DNS_SERVER\"/g" /etc/sysconfig/network/config

## Default route
Debug_print "echo \"default $GATEWAY - -\" > /etc/sysconfig/network/routes"
echo "default $GATEWAY - -" > /etc/sysconfig/network/routes
}


BasicPackageInstallation () {
## Install packages for all
Debug zypper --non-interactive in -t pattern enhanced_base 
Debug zypper --non-interactive in sudo wget
#Debug zypper --non-interactive up --no-recommends kernel-default
## Install the package below depending on situation
#Debug zypper --non-interactive in -t pattern  yast2_basis
}

CAConfiguration () {
## Insert CA cert
#Debug echo $CACERT
local CACERT=$(cat /tmp/cacert.pem)
Debug echo $CACERT
cat << EOF  >  /etc/pki/trust/anchors/cacert.pem
$CACERT
EOF
# The command below will update /etc/ssl/ca-bundle.pem
Debug update-ca-certificates;
# Need to reboot or similar job for k8s to recognize Cert
sync;
}

SystemdAccounging () {
## CPU and Memory account in systemd for all
cat /etc/systemd/system.conf | grep ^'DefaultCPUAccounting=yes' || echo 'DefaultCPUAccounting=yes' >> /etc/systemd/system.conf
cat /etc/systemd/system.conf | grep ^'DefaultMemoryAccounting=yes' || echo 'DefaultMemoryAccounting=yes' >> /etc/systemd/system.conf 
sync;
}

SwapOff () {
## Swap off for all
systemctl stop dev-$SWAP_DEV.swap; systemctl mask dev-$SWAP_DEV.swap;
swapoff -a;systemctl stop swap.target;systemctl disable swap.target;
cat /etc/fstab | grep swap > swap.tt && sed -i "s~$(cat swap.tt)~#$(cat swap.tt)~g" /etc/fstab
sync;
}

RefreshMachineID () {
## Uniqueue Machine ID for all
Debug rm -f /etc/machine-id
Debug dbus-uuidgen --ensure
Debug systemd-machine-id-setup
Debug systemctl restart systemd-journald
sync;
}


NetworkInterfaceAndHostname () {

# Configure hostname
IP_HERE=$(ip addr show dev $ETH_INTERFACE | grep global | head -1 | awk -F/ '{print $1}' | awk '{print $2}')

## The first hostname set
j=${#IP_TOTAL[@]}
for ((i=j; i >= 0 ; i--  ))
do
        #echo IP_TOTAL[] : ${IP_TOTAL[$i]};echo IP_HERE : $IP_HERE;
        if [[ $IP_HERE == ${IP_TOTAL[$i]}  ]];then
        #Debug_print $'echo ${HOSTNAME_TOTAL[$i]} > /etc/hostname'
        echo ${HOSTNAME_TOTAL[$i]} > /etc/hostname
        hostname ${HOSTNAME_TOTAL[$i]}
        fi;
done


# Configure IP
cat << EOF > /etc/sysconfig/network/ifcfg-$ETH_INTERFACE
BOOTPROTO='static'
BROADCAST=''
ETHTOOL_OPTIONS=''
IPADDR='$IP_HERE/24'
MTU=''
NAME=''
NETMASK=''
NETWORK=''
REMOTE_IPADDR=''
STARTMODE='auto'
EOF
Debug systemctl restart network

}

Chrony_for_ntp_server () {


RESULT=$(rpm -qa | grep chrony)

if [[ $RESULT == "" ]]; then Debug zypper in -y chrony; 
else Debug echo "chrony is already installed" 
fi;

## Local ntp server without internet
Debug sed -i "s/! pool pool.ntp.org iburst/#! pool pool.ntp.org iburst/g" /etc/chrony.conf
Debug sed -i "s/#local stratum 10/local stratum 10/g" /etc/chrony.conf
Debug_print $'echo "allow $NTP_CLIENT_NET" >> /etc/chrony.conf'
echo "allow $NTP_CLIENT_NET" >> /etc/chrony.conf
Debug systemctl restart chronyd
Debug systemctl enable chronyd

## Local ntp server with internet
#Debug_print $'echo "allow $NTP_CLIENT_NET" >> /etc/chrony.conf'
#echo "allow $NTP_CLIENT_NET" >> /etc/chrony.conf
#Debug systemctl restart chronyd
#Debug systemctl enable chronyd




}

Chrony_for_ntp_client () {
Debug sed -i 's/! pool pool.ntp.org iburst/#! pool pool.ntp.org iburst/g' /etc/chrony.conf
cat /etc/chrony.conf | grep "server $MGMT_FQDN iburst" || echo "server $MGMT_FQDN iburst" >> /etc/chrony.conf
Debug systemctl restart chronyd
Debug systemctl enable chronyd
}

RefreshRepo () {

Debug zypper --non-interactive ref;
}

UpdateNodes () {
	Debug zypper --non-interactive up
	Debug zypper --non-interactive up
}

# This function needs to run on management
FileCopyToAll () {

	Debug cm-scp $froLOCAL_REPO_DIR/cert/natgw_cert/cacert.pem /tmp

}

# This function needs to run on management
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
DNS.1 = ${HOSTNAME_TOTAL[1]}.$DOMAIN
DNS.2 = ${HOSTNAME_TOTAL[2]}.$DOMAIN
DNS.3 = $MGMT.$DOMAIN


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

# This should be run on Management
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

#Debug docker load -i $froLOCAL_REPO_DIR/docker_images_file/registry.2.6.2.tar
Debug docker container run -d -p 5000:5000 --restart=always --name suse-registry -v /etc/docker_registry:/etc/docker/registry -v /var/lib/docker/registry:/var/lib/registry registry.suse.com/sles12/registry:2.6.2

#Debug docker container run -d --restart=always -p 5000:443 --name registry -v /var/lib/docker/registry:/var/lib/registry -v /var/lib/docker/certs:/certs -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/monitoring_crt.pem -e REGISTRY_HTTP_TLS_key=/crts/monitoring_key.pem registry.suse.com/sles12/registry:2.6.2

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



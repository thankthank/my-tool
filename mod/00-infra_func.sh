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

echo '192.168.37.17 smt.suse smt' >> /etc/hosts	
Debug SUSEConnect --url http://smt.suse
#Debug SUSEConnect --url http://smt.suse -p ses/7/x86_64
Debug SUSEConnect --url http://smt.suse -p sle-ha/15.2/x86_64

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
cat << EOF  >  /etc/pki/trust/anchors/cacert.pem
$CACERT
EOF
# The command below will update /etc/ssl/ca-buldle.pem
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
#Debug sed -i "s/! pool pool.ntp.org iburst/#! pool pool.ntp.org iburst/g" /etc/chrony.conf
#Debug sed -i "s+#allow 192.168.0.0/16+allow $NTP_CLIENT_NET+g" /etc/chrony.conf
#Debug sed -i "s/#local stratum 10/local stratum 10/g" /etc/chrony.conf
#Debug systemctl restart chronyd
#Debug systemctl enable chronyd

## Local ntp server with internet
#Debug sed -i "s/! pool pool.ntp.org iburst/#! pool pool.ntp.org iburst/g" /etc/chrony.conf
Debug sed -i "s+#allow 192.168.0.0/16+allow $NTP_CLIENT_NET+g" /etc/chrony.conf
#Debug sed -i "s/#local stratum 10/local stratum 10/g" /etc/chrony.conf
Debug systemctl restart chronyd
Debug systemctl enable chronyd




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

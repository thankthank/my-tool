#!/bin/bash

StaticHostname () {

sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg

# Configure hostname
IP_HERE=$(ip addr show dev ${ETH_INTERFACE} | grep global | head -1 | awk -F/ '{print $1}' | awk '{print $2}')

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

Debug systemctl restart network


}

ConfigureCliRegion () {

AZ=$1

mkdir -p /root/.aws
cat << EOF | tee /root/.aws/config
[default]
region = ${AZ}
[profile $AwsCli_Profile]
region = ${AZ}
output = text
EOF

}

TaggingEC2instances () {

Debug aws ec2 create-tags --resources  $(ec2metadata --instance-id) --tags Key=$InstanceTagKey,Value=$(uname -n)


}

AddRolsandPolicies () {

echo "AWS Data Provider for SAP Policy"
echo "Only one SAP Data Provider policy  per account"
cat << EOF | tee /tmp/sap_data_provider.policy
{
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "EC2:DescribeInstances",
                "EC2:DescribeVolumes"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "cloudwatch:GetMetricStatistics",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::aws-sap-data-provider/config.properties"
        }
    ]
}
EOF
Debug echo "Policy file generated : /tmp/sap_data_provider.policy"


echo "EC2 STONITH policy"
local ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
local INSTANCEIDPRIMARY=$(ec2metadata --instance-id)
local INSTANCEIDSECONDARY=$(ssh ${SECONDARY[0]} ec2metadata --instance-id)

cat << EOF | tee /tmp/ec2_stonith.policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1424870324000",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Stmt1424870324001",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": [
                "arn:aws:ec2:$REGION:$ACCOUNTID:instance/$INSTANCEIDPRIMARY",
                "arn:aws:ec2:$REGION:$ACCOUNTID:instance/$INSTANCEIDSECONDARY"

            ]
        }
    ]
}
EOF
Debug echo "Policy file generated : /tmp/ec2_stonith.policy"

echo "Overlay IP Resource Agent policy"

cat << EOF | tee /tmp/overlay_ip.policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:ReplaceRoute",
            "Resource": "arn:aws:ec2:$REGION:$ACCOUNTID:route-table/$ROUTING_TABLE_ID"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ec2:DescribeRouteTables",
            "Resource": "*"
        }
    ]
}
EOF

echo "Disable source/destination ceck policy"

cat << EOF | tee /tmp/source_destination.policy
{
   "Version": "2012-10-17",
   "Statement": [
   {
      "Sid": "Stmt1424870324000",
      "Effect": "Allow",
      "Action": [ "ec2:ModifyInstanceAttribute" ],
      "Resource": [
      "arn:aws:ec2:$REGION:$ACCOUNTID:instance/$INSTANCEIDPRIMARY",
      "arn:aws:ec2:$REGION:$ACCOUNTID:instance/$INSTANCEIDSECONDARY"
      ]
   }
   ]
}
EOF

echo "Route 53 Updates"
local HOSTED_ZONE_ID=""
local FULL_NAME="" 
cat << EOF | tee /tmp/route53.policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1471878724000",
            "Effect": "Allow",
            "Action": "route53:GetChange",
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Sid": "Stmt1471878724001",
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Resource": "arn:aws:route53:::hostedzone/$HOSTED_ZONE_ID/$FULL_NAME"
        },
        {
            "Sid": "Stmt1471878724002",
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/$HOSTED_ZONE_ID"
        }
    ]
}
EOF


}

AddOverlayIPAddress () {

cat << EOF 
To add the Overlay IP address:

* Use the AWS console and search for “VPC”.

* Select the correct VPC ID.

* Click “Route Tables” in the left column.

* Select the route table used by the subnets from one of your SAP EC2 instances and their application servers.

* Click the tabulator “Routes”.

* Click “Edit”.

* Scroll to the end of the list and click “Add another route”.

* Add the Overlay IP address of the SAP HANA database. Use as filter /32 (example: 192.168.10.1/32). Add the Elastic Network Interface (ENI) name to one of your existing instance. The resource agent will modify this later automatically.

* Save your changes by clicking “Save”.

EOF

}

ConfigureEC2 () {

#Debug zypper install -y rsyslog;
#Debug systemctl enable --now logd;

Debug zypper --non-interactive remove SAPHanaSR SAPHanaSR-doc yast2-sap-ha
Debug zypper --non-interactive in SAPHanaSR-ScaleOut SAPHanaSR-ScaleOut-doc

Debug saptune solution apply $SAPTUNE_PROFILE
Debug saptune daemon start
Debug saptune solution list


}

AvoidDeletionOverlayIPNoSource () {

local INSTANCEID=$(ec2metadata --instance-id)
Debug aws ec2 modify-instance-attribute --instance-id $INSTANCEID --no-source-dest-check


Debug_print $'sed -i "s+CLOUD_NETCONFIG_MANAGE='yes'+CLOUD_NETCONFIG_MANAGE='no'+g" /etc/sysconfig/network/ifcfg-eth0'
sed -i "s+CLOUD_NETCONFIG_MANAGE='yes'+CLOUD_NETCONFIG_MANAGE='no'+g" /etc/sysconfig/network/ifcfg-eth0



}

ConfigureNetwork () {

echo "Add Second IP using console UI"
cat << EOF 
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/MultipleIP.html#assignIP-existing

To assign a secondary private IPv4 address to a network interface

* Open the Amazon EC2 console at https://console.aws.amazon.com/ec2/.

* In the navigation pane, choose Network Interfaces, and then select the network interface attached to the instance.

* Choose Actions, Manage IP Addresses.

* Under IPv4 Addresses, choose Assign new IP.

* Enter a specific IPv4 address that's within the subnet range for the instance, or leave the field blank to let Amazon select an IP address for you.

* (Optional) Choose Allow reassignment to allow the secondary private IP address to be reassigned if it is already assigned to another network interface.

* Choose Yes, Update.
EOF
Debug echo "Add Second IP using UI"
echo -n "Please enter the second ip addres(e.g. 192.168.0.11/24) : "
read  SECOND_IP

Debug_print $'sed -i "s+IPADDR_1=\"\"+IPADDR_1=\"$SECOND_IP\"+g" /etc/sysconfig/network/ifcfg-eth0'
sed -i "s+IPADDR_1=\"\"+IPADDR_1=\"$SECOND_IP\"+g" /etc/sysconfig/network/ifcfg-eth0

Debug ip addr add $SECOND_IP dev eth0 

}

sapHANA_hook_script ()
{
cat << EOF
suse01~ # mkdir -p /hana/shared/myHooks
suse01~ # cp /usr/share/SAPHanaSR-ScaleOut/SAPHanaSR.py /hana/shared/myHooks
suse01~ # chown -R <sid>adm:sapsys /hana/shared/myHooks
EOF

}


sapHANA_HA_DR_profider () {

mkdir -p /hana/shared/myHooks
cp /usr/share/SAPHanaSR-ScaleOut/SAPHanaSR.py /hana/shared/myHooks
chown -R ${SID}adm:sapsys /hana/shared/myHooks

Debug echo "Stop SAP HANA manually by # sapcontrol -nr <instanceNumber> -function StopSystem" 

#Debug su - ${SID}adm -c HDB stop

## Implementing the python hook SAPHanaSR
echo add below to the GLOBAL.INI file
cat << EOF | tee -a /hana/shared/HDB/global/hdb/custom/config/global.ini
[ha_dr_provider_SAPHanaSR]
provider = SAPHanaSR
path = /usr/share/SAPHanaSR
execution_order = 1

[trace]
ha_dr_saphanasr = info
EOF
Debug echo "check integration of the hook during start-up"

## Configuring System Replication Operation Mode
echo apply the configuration below to the GLOBAL.INI file
cat << EOF | tee -a /hana/shared/HDB/global/hdb/custom/config/global.ini
[system_replication]
operation_mode = logreplay
EOF
Debug echo "check the replication operation mode"

## Allowing <sidadm> to Access the Cluster
cat << EOF >> /etc/sudoers
${SID}adm ALL=(ALL) NOPASSWD: ALL
EOF


}

DisklessSBD () {
echo softdog > /etc/modules-load.d/watchdog.conf
systemctl restart systemd-modules-load

cat << EOF | tee /etc/sysconfig/sbd
#SBD_DEVICE=""
SBD_PACEMAKER=yes
SBD_STARTMODE=always
SBD_DELAY_START=no
SBD_WATCHDOG_DEV=/dev/watchdog
SBD_WATCHDOG_TIMEOUT=5
SBD_TIMEOUT_ACTION=flush,reboot
SBD_OPTS=
EOF
Debug systemctl enable sbd

}

Corosynckey () {

Debug corosync-keygen

Debug scp /etc/corosync/authkey ${SECONDARY[0]}:/etc/corosync/
Debug scp /etc/corosync/authkey ${SECONDARY[1]}:/etc/corosync/
Debug scp /etc/corosync/authkey ${SECONDARY[2]}:/etc/corosync/
Debug scp /etc/corosync/authkey ${SECONDARY[3]}:/etc/corosync/
}

BootstrapCluster () {
local IP_LOCAL_NODE=$(ip addr show eth0 | grep inet | head -1 | awk '{gsub("/24","",$2);print $2}')


cat << EOF | tee /etc/corosync/corosync.conf
# Read the corosync.conf.5 manual page
totem {
   version: 2
   token: 30000
   consensus: 32000
   token_retransmits_before_loss_const: 6
   secauth: on
   crypto_hash: sha1
   crypto_cipher: aes256
   clear_node_high_bit: yes
   interface {
      ringnumber: 0
      bindnetaddr: $IP_LOCAL_NODE
      mcastport: 5405
      ttl: 1
   }
   transport: udpu
}
logging {
   fileline: off
   to_logfile: yes
   to_syslog: yes
   logfile: /var/log/cluster/corosync.log
   debug: off
   timestamp: on
   logger_subsys {
      subsys: QUORUM
      debug: off
   }
}
nodelist {
   node {
      ring0_addr: ${SECONDARY_IP[0]}
      nodeid: 1
   }
   node {
      ring0_addr: ${SECONDARY_IP[1]}
      nodeid: 2
   }
   node {
      ring0_addr: ${SECONDARY_IP[2]}
      nodeid: 3
   }
   node {
      ring0_addr: ${SECONDARY_IP[3]}
      nodeid: 4
   }
   node {
      ring0_addr: ${PRIMARY_IP[0]}
      nodeid: 5
   }
}
quorum {
# Enable and configure quorum subsystem (default: off)
# see also corosync.conf.5 and votequorum.5
   provider: corosync_votequorum
}
EOF

#Debug systemctl start pacemaker

}

PacemakerStart () {

Debug systemctl start pacemaker

}

ConfigureProperty_Stonith () {

cat << EOF | tee /tmp/crm-bs.txt
property \$id="cib-bootstrap-options" \
            no-quorum-policy="freeze" \
            stonith-enabled="true" \
            stonith-action="reboot" \
            stonith-watchdog-timeout="10" 

op_defaults \$id="op-options" \
            timeout="600"

rsc_defaults rsc-options: \
            resource-stickiness="1000" \
            migration-threshold="5"
EOF
Debug crm configure load update /tmp/crm-bs.txt


cat << EOF | tee /tmp/aws-move-ip.txt
primitive res_AWS_IP ocf:suse:aws-vpc-move-ip \
   params ip=$OVERLAY_IP routing_table=$ROUTING_TABLE_ID interface=$ETH_INTERFACE profile=$AwsCli_Profile \
   op start interval=0 timeout=180 \
   op stop interval=0 timeout=180 \
   op monitor interval=60 timeout=60
EOF
Debug crm configure load update /tmp/aws-move-ip.txt

Debug systemctl status sbd
}

setMaintenanceMode ()
{
crm configure property maintenance-mode=true

}
sapHANA_crm_configuration () {

cat << EOF | tee /tmp/crm-saphanatop.txt
primitive rsc_SAPHanaTop_${SID_UPPER}_HDB${HANA_INS_NR} ocf:suse:SAPHanaTopology \
        op monitor interval="10" timeout="600" \
        op start interval="0" timeout="600" \
        op stop interval="0" timeout="300" \
        params SID="${SID_UPPER}" InstanceNumber="${HANA_INS_NR}"

clone cln_SAPHanaTop_${SID_UPPER}_HDB${HANA_INS_NR} rsc_SAPHanaTop_${SID_UPPER}_HDB${HANA_INS_NR} \
        meta clone-node-max="1" interleave="true"

EOF
Debug crm configure load update /tmp/crm-saphanatop.txt


cat << EOF | tee /tmp/crm-saphanacon.txt
primitive rsc_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR} ocf:suse:SAPHanaController \
        op start interval="0" timeout="3600" \
        op stop interval="0" timeout="3600" \
        op promote interval="0" timeout="3600" \
        op monitor interval="60" role="Master" timeout="700" \
        op monitor interval="61" role="Slave" timeout="700" \
        params SID="${SID_UPPER}" InstanceNumber="${HANA_INS_NR}" \
        PREFER_SITE_TAKEOVER="true" \
        DUPLICATE_PRIMARY_TIMEOUT="7200" AUTOMATED_REGISTER="false"

ms msl_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR} rsc_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR} \
        meta clone-node-max="1" master-max="1" interleave="true"
EOF
Debug crm configure load update /tmp/crm-saphanacon.txt

cat << EOF | tee /tmp/crm-cs.txt
colocation col_saphana_ip_${SID_UPPER}_HDB${HANA_INS_NR} 2000: res_AWS_IP:Started \
 msl_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR}:Master
order ord_SAPHana_${SID_UPPER}_HDB${HANA_INS_NR} Optional: cln_SAPHanaTop_${SID_UPPER}_HDB${HANA_INS_NR} \
 msl_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR}
location OIP_not_on_majority_maker res_AWS_IP -inf: ${MAJOR_NODE}
location SAPHanaCon_not_on_majority_maker msl_SAPHanaCon_${SID_UPPER}_HDB${HANA_INS_NR} -inf: ${MAJOR_NODE}
location SAPHanaTop_not_on_majority_maker cln_SAPHanaTop_${SID_UPPER}_HDB${HANA_INS_NR} -inf: ${MAJOR_NODE}
EOF
Debug crm configure load update /tmp/crm-cs.txt

}

sapSR_check ()
{
	Debug SAPHanaSR-showAttr
	Debug HDBSettings.sh landscapeHostConfiguration.py
	Debug HDBSettings.sh systemReplicationStatus.py

}

sapHANA_crm_read-enabled () {
## Active-active read-enabled scenario

local RE_IP="10.0.0.2"
local RE_RTB="rtb-changeme"
cat << EOF | tee /tmp/crm-re.txt
primitive res_AWS_IP_readenabled ocf:suse:aws-vpc-move-ip \
   params ip=${RE_IP} routing_table=${RE_RTB} interface=${ETH_INTERFACE} profile=${AwsCli_Profile} \
   op start interval=0 timeout=180 \
   op stop interval=0 timeout=180 \
   op monitor interval=60 timeout=60
colocation col_saphana_ip_${SID_UPPER}_HDB${HANA_INS_NR}_readenabled 2000: \
    res_AWS_IP_readenabled:Started msl_SAPHana_${SID_UPPER}_HDB${HANA_INS_NR}:Slave
EOF
Debug crm configure load update /tmp/crm-re.txt
}

HA_test () {
echo ""

}



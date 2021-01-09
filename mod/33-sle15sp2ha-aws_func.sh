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

Debug zypper install -y rsyslog;
Debug systemctl enable --now logd;

Debug saptune solution apply $SAPTUNE_PROFILE
Debug saptune daemon start
Debug saptune solution list


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

local INSTANCEID=$(ec2metadata --instance-id)
Debug aws ec2 modify-instance-attribute --instance-id $INSTANCEID --no-source-dest-check


Debug_print $'sed -i "s+CLOUD_NETCONFIG_MANAGE='yes'+CLOUD_NETCONFIG_MANAGE='no'+g" /etc/sysconfig/network/ifcfg-eth0'
sed -i "s+CLOUD_NETCONFIG_MANAGE='yes'+CLOUD_NETCONFIG_MANAGE='no'+g" /etc/sysconfig/network/ifcfg-eth0

}

sapHANA_HA_DR_profider () {

Debug echo "Stop SAP HANA manually by # sapcontrol -nr <instanceNumber> -function StopSystem" 

## Implementing the python hook SAPHanaSR
echo add below to the GLOBAL.INI file
cat << EOF | tee /tmp/SAPHanaSR.golbal.ini
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
cat << EOF | tee /tmp/ReplicationOperationmode.global.ini
[system_replication]
operation_mode = logreplay
EOF
Debug echo "check the replication operation mode"

## Allowing <sidadm> to Access the Cluster
cat << EOF >> /etc/sudoers
${SID}adm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_${SID}_site_srHook_*
EOF


}

Corosynckey () {

Debug corosync-keygen

Debug scp /etc/corosync/authkey ${SECONDARY[0]}:/etc/corosync/
}

BootstrapCluster () {
local IP_LOCAL_NODE=$(ip addr show eth0 | grep inet | head -1 | awk '{gsub("/20","",$2);print $2}')


cat << EOF | tee /etc/corosync/corosync.conf
# Read the corosync.conf.5 manual page
totem {
   version: 2
   rrp_mode: passive
   token: 30000
   consensus: 36000
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
     ring0_addr: ${PRIMARY_IP[0]}
#     ring1_addr: ip-node-1-b # redundant ring
     nodeid: 1
   }
   node {
     ring0_addr: ${SECONDARY_IP[0]}
#     ring1_addr: ip-node-2-b # redundant ring
     nodeid: 2
   }
}
quorum {
# Enable and configure quorum subsystem (default: off)
# see also corosync.conf.5 and votequorum.5
   provider: corosync_votequorum
   expected_votes: 2
   two_node: 1
}
EOF

Debug systemctl start pacemaker

}

ConfigureProperty_Stonith () {

cat << EOF | tee /tmp/crm-bs.txt
property \$id="cib-bootstrap-options" \
   stonith-enabled="true" \
   stonith-action="off" \
   stonith-timeout="600s"
rsc_defaults \$id="rsc-options" \
   resource-stickiness="1000" \
   migration-threshold="5000"
op_defaults \$id="op-options" \
   timeout="600"
EOF
Debug crm configure load update /tmp/crm-bs.txt

cat << EOF | tee /tmp/aws-stonith.txt
primitive res_AWS_STONITH stonith:external/ec2 \
    op start interval=0 timeout=180 \
    op stop interval=0 timeout=180 \
    op monitor interval=300 timeout=60 \
    meta target-role=Started \
    params tag=$InstanceTagKey profile=$AwsCli_Profile pcmk_delay_max=15
EOF
Debug crm configure load update /tmp/aws-stonith.txt

cat << EOF | tee /tmp/aws-move-ip.txt
primitive res_AWS_IP ocf:suse:aws-vpc-move-ip \
   params ip=$OVERLAY_IP routing_table=$ROUTING_TABLE_ID interface=$ETH_INTERFACE profile=$AwsCli_Profile \
   op start interval=0 timeout=180 \
   op stop interval=0 timeout=180 \
   op monitor interval=60 timeout=60
EOF
Debug crm configure load update /tmp/aws-move-ip.txt

}



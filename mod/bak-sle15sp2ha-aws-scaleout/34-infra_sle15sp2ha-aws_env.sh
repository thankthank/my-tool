#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP="10.0.6.60" #Mapped to GRP1
OTHERS_IP=(10.0.2.20 10.0.2.21 10.0.4.40 10.0.4.41) #Mapped to GRP2
PRIMARY_IP=(10.0.6.60) #Mapped to GRP3
SECONDARY_IP=(10.0.2.20 10.0.2.21 10.0.4.40 10.0.4.41) #Mapped to GRP4

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
DOMAIN="awscloud.net" # DOMAIN name for this lab. 
MGMT="majorhana"
MGMT_FQDN=$MGMT.$DOMAIN
OTHERS=(prihanamaster prihanawork01 sechanamaster sechanawork01)
PRIMARY=(majorhana)
SECONDARY=(prihanamaster prihanawork01 sechanamaster sechanawork01)

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
#HOSTNAME_TOTAL[0]=$MGMT
j=${#HOSTNAME_TOTAL[@]};for i in "${PRIMARY[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${SECONDARY[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
IP_TOTAL=()
#IP_TOTAL[0]=$MGMT_IP
j=${#IP_TOTAL[@]};for i in "${PRIMARY_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${SECONDARY_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;

#### Infra Functionis Configuration variables : Variables which are used by functions
#DNS_SERVER="168.126.63.1"
#GATEWAY="192.168.37.254"
NTP_CLIENT_NET="172.31.0.0/16"


##### HA on AWS ENV
ETH_INTERFACE="eth0"

# for aws cli
REGION="ap-northeast-2"
AwsCli_Profile="cluster" # Use this default value
InstanceTagKey="pacemaker" # Use this default value

ROUTING_TABLE_ID="rtb-09151e6b1e55cbe31"
# Saptune profile among HANA, NETWEAVER, S4HANA-APPSERVER, S4HANA-DBSERVER
SAPTUNE_PROFILE="S4HANA-DBSERVER"

# HANA
SID="hdb"
SID_UPPER=$(echo $SID|sed 's/./\U&/g')
HANA_INS_NR="00"
OVERLAY_IP="192.168.10.1"
MAJOR_NODE="majorhana"

# ASCS-ERS
OVERLAY_IP_ASCS="10.0.0.2"
OVERLAY_IP_ERS="10.0.0.3"




#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP=(192.168.37.71) #Mapped to GRP1
MASTER_IP=(192.168.37.31) #Mapped to GRP3
WORKER_IP=(192.168.37.32 192.168.37.33) #Mapped to GRP4

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
MGMT="caasp-lb"
DOMAIN="example.com" # DOMAIN name for this lab. 
MGMT_FQDN="$MGMT.$DOMAIN" #This is also FQDN of registry
MASTER=(caasp-master1)
WORKER=(caasp-worker1 caasp-worker2)
## Hostnames and IPs which will be used monitoring stack. You don't want to change the value below.
MONITORING_IP=(${WORKER_IP[0]} ${WORKER_IP[0]} ${WORKER_IP[0]} ${WORKER_IP[0]})
MONITORING=(monitoring prometheus prometheus-alertmanager grafana)

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=$MGMT
j=${#HOSTNAME_TOTAL[@]};for i in "${MASTER[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${WORKER[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${MONITORING[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
IP_TOTAL=()
IP_TOTAL[0]=$MGMT_IP
j=${#IP_TOTAL[@]};for i in "${MASTER_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${WORKER_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${MONITORING_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
CAASP_TOTAL=()
j=${#CAASP_TOTAL[@]};for i in "${MASTER[@]}";do CAASP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#CAASP_TOTAL[@]};for i in "${WORKER[@]}";do CAASP_TOTAL[$j]=$i; ((j=j+1));done;
CAASP_IP_TOTAL=()
j=${#CAASP_IP_TOTAL[@]};for i in "${MASTER_IP[@]}";do CAASP_IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#CAASP_IP_TOTAL[@]};for i in "${WORKER_IP[@]}";do CAASP_IP_TOTAL[$j]=$i; ((j=j+1));done;
HOSTS=();
#echo "HOSTNAME_TOTAL : " ${#HOSTNAME_TOTAL[@]}" :" ${HOSTNAME_TOTAL[@]}

#### Infra Functionis Configuration variables : Variables which are used by functions
DNS_SERVER="168.126.63.1"
GATEWAY="192.168.37.254"
NTP_CLIENT_NET="192.168.0.0/16"
SWAP_DEV="sda2" #If you have SWAP partition with this device, it will be removed. If you don't have SWAP partition ignore it.

#### Temporary configuration
HOSTS_TEMP=(ses-admin) # Array for temporary run





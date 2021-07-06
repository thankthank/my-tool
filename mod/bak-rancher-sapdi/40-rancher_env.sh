#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP=(192.168.200.111) #Mapped to GRP1
RMS_IP=(192.168.200.112) #Mapped to GRP5
D_MASTER_IP=(192.168.200.104) #Mapped to GRP3
D_WORKER_IP=(192.168.200.105 192.168.200.106 192.168.200.107 192.168.200.103) #Mapped to GRP4

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
MGMT="mgmt"
DOMAIN="sapdemo.lab" # DOMAIN name for this lab. 
MGMT_FQDN="$MGMT.$DOMAIN" #This is also FQDN of registry
RMS=(rms)
D_MASTER=(master1)
D_WORKER=(worker1 worker2 worker3 worker4)

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=$MGMT
j=${#HOSTNAME_TOTAL[@]};for i in "${RMS[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${D_MASTER[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${D_WORKER[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
IP_TOTAL=()
IP_TOTAL[0]=$MGMT_IP
j=${#IP_TOTAL[@]};for i in "${RMS_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${D_MASTER_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${D_WORKER_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
HOSTS=();
#echo "HOSTNAME_TOTAL : " ${#HOSTNAME_TOTAL[@]}" :" ${HOSTNAME_TOTAL[@]}

#### Infra Functionis Configuration variables : Variables which are used by functions
DNS_SERVER="192.168.200.111"
GATEWAY="192.168.200.1"
NTP_CLIENT_NET="192.168.0.0/16"
ETH_INTERFACE="eth0"

#### Temporary configuration
HOSTS_TEMP=(ses-admin) # Array for temporary run





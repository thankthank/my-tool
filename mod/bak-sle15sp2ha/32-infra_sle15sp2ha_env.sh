#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP=(192.168.37.130) #Mapped to GRP1
OTHERS_IP=(192.168.37.131 192.168.37.132) #Mapped to GRP2
PRIMARY_IP=(192.168.37.131) #MApped to GRP3
SECONDS_IP=(192.168.37.132) #mapped to GRP4

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
MGMT="ha-admin"
DOMAIN="example.com" # DOMAIN name for this lab. 
MGMT_FQDN="$MGMT.$DOMAIN" #This is also FQDN of registry
OTHERS=(ha-1 ha-2)
PRIMARY=(ha-1)
SECONDS=(ha-2)
ETH_INTERFACE="eth0"

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=$MGMT
j=${#HOSTNAME_TOTAL[@]};for i in "${OTHERS[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
IP_TOTAL=()
IP_TOTAL[0]=$MGMT_IP
j=${#IP_TOTAL[@]};for i in "${OTHERS_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
OTHERS_TOTAL=()
j=${#OTHERS_TOTAL[@]};for i in "${OTHERS[@]}";do OTHERS_TOTAL[$j]=$i; ((j=j+1));done;
OTHERS_IP_TOTAL=()
j=${#OTHERS_IP_TOTAL[@]};for i in "${OTHERS_IP[@]}";do OTHERS_IP_TOTAL[$j]=$i; ((j=j+1));done;
HOSTS=();
#echo "HOSTNAME_TOTAL : " ${#HOSTNAME_TOTAL[@]}" :" ${HOSTNAME_TOTAL[@]}

#### Infra Functionis Configuration variables : Variables which are used by functions
DNS_SERVER="192.168.37.130"
GATEWAY="192.168.37.254"
NTP_CLIENT_NET="192.168.0.0/16"
SWAP_DEV="sda2" #If you have SWAP partition with this device, it will be removed. If you don't have SWAP partition ignore it.

#### Temporary configuration
HOSTS_TEMP=(ses-admin) # Array for temporary run





#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP=(192.168.37.17) #Mapped to GRP1

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
MGMT="smt"
DOMAIN="suse.su" # DOMAIN name for this lab. 
MGMT_FQDN="$MGMT.$DOMAIN" #This is also FQDN of registry

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=$MGMT
IP_TOTAL=()
IP_TOTAL[0]=$MGMT_IP
HOSTS=();
#echo "HOSTNAME_TOTAL : " ${#HOSTNAME_TOTAL[@]}" :" ${HOSTNAME_TOTAL[@]}

#### Infra Functionis Configuration variables : Variables which are used by functions
DNS_SERVER="168.126.63.1"
GATEWAY="192.168.37.1"
NTP_CLIENT_NET="192.168.0.0/16"
SWAP_DEV="sda2" #If you have SWAP partition with this device, it will be removed. If you don't have SWAP partition ignore it.






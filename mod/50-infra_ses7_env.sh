#!/bin/bash

#### IP and Hostname configuration
## IP addresses which are configured on target nodes. 
MGMT_IP=(192.168.37.60) #Mapped to GRP1
MON_IP=(192.168.37.61 192.168.37.62 192.168.37.63) #Mapped to GRP2
OSD_IP=(192.168.37.61 192.168.37.62 192.168.37.63 192.168.37.64) #Mapped to GRP3
NEW_IP=(192.168.37.64) #Mapped to GRP5
SMB_IP=(192.168.37.63) #Mapped to GRP6
ISCSI_IP=(192.168.37.62 192.168.37.64) #Mapped to GRP7
RGW=(192.168.37.63) #Mapped to GRP8

## Network configuration variables. Hostnames you want to configure on target nodes. Even if you already configured hostname, put the configured hostnames here and skip the hostname configuration function.
MGMT="ses-admin"
DOMAIN="example.com" # DOMAIN name for this lab. 
MGMT_FQDN="$MGMT.$DOMAIN" #This is also FQDN of registry
MON=(ses-1 ses-2 ses-3)
OSD=(ses-1 ses-2 ses-3 ses-new)
NEW=(ses-new)
SMB=(ses-3)
ISCSI=(ses-2 ses-new)
RGW=(ses-3)
ETH_INTERFACE="eth0"

## Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=$MGMT
j=${#HOSTNAME_TOTAL[@]};for i in "${MON[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
j=${#HOSTNAME_TOTAL[@]};for i in "${OSD[@]}";do HOSTNAME_TOTAL[$j]=$i; ((j=j+1));done;
IP_TOTAL=()
IP_TOTAL[0]=$MGMT_IP
j=${#IP_TOTAL[@]};for i in "${MON_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
j=${#IP_TOTAL[@]};for i in "${OSD_IP[@]}";do IP_TOTAL[$j]=$i; ((j=j+1));done;
SES=()
j=${#SES[@]};for i in "${MON[@]}";do SES[$j]=$i; ((j=j+1));done;
j=${#SES[@]};for i in "${OSD[@]}";do SES[$j]=$i; ((j=j+1));done;
SES_IP=() #mapped to GRP4
j=${#SES_IP[@]};for i in "${MON_IP[@]}";do SES_IP[$j]=$i; ((j=j+1));done;
j=${#SES_IP[@]};for i in "${OSD_IP[@]}";do SES_IP[$j]=$i; ((j=j+1));done;
HOSTS=();
#echo "HOSTNAME_TOTAL : " ${#HOSTNAME_TOTAL[@]}" :" ${HOSTNAME_TOTAL[@]}

#### Infra Functionis Configuration variables : Variables which are used by functions
DNS_SERVER="192.168.37.17"
GATEWAY="192.168.37.1"
NTP_CLIENT_NET="192.168.0.0/16"
SWAP_DEV="sda2" #If you have SWAP partition with this device, it will be removed. If you don't have SWAP partition ignore it.

#### Temporary configuration
HOSTS_TEMP=(ses-admin) # Array for temporary run





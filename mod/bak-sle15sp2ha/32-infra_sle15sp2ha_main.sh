#!/bin/bash

######################
## USER jobs 
# declare -A GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT_IP" ["on_GRP2"]="OTHERS_IP" ["on_GRP3"]="PRIMARY_IP" ["on_GRP4"]="SECONDS_IP" ["on_GRP5"]="NONE") #CHANGEME

#TempSshPrivateKeyForDeployment on_GRP1
#TempSshPublicKeyForDeployment on_GRP0

## IP and Hostname configuation
##
## If you use the network interface, eth0, you can run the function below to configure static network and hostname instead of manual network configuration.
#BasicNetwork on_GRP0
#NetworkInterfaceAndHostname on_GRP0

# Manual repository setup with a deployment image using Yast
#RegisterRepositories on_GRP2 
#RegistertoSMT on_GRP2

#SshKnownhost on_GRP1
#MyToolDeployment on_GRP1

## Network and System Configuation functions
#EtcHosts on_GRP0
#BasicPackageInstallation on_GRP2
#CAConfiguration on_GRP0
#SystemdAccounging on_GRP0
#SwapOff on_GRP0

#Chrony_for_ntp_server on_GRP1
#Chrony_for_ntp_client on_GRP2

## Temporary admin task
#RefreshRepo on_GRP0





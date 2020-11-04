#!/bin/bash

######################
## USER jobs 


## Run the function below when ssh access with key is not implemented. 
#TempSshPrivateKeyForDeployment on_GRP1
#TempSshPublicKeyForDeployment on_GRP0

#RegisterRepositories on_GRP2 
#SshKnownhost on_GRP1
#MyToolDeployment on_GRP1

## Network and System Configuation functions
#EtcHosts on_GRP0
BasicNetwork on_GRP3
#BasicPackageInstallation on_GRP0
#CAConfiguration on_GRP0
#SystemdAccounging on_GRP0
#SwapOff on_GRP0

## 2. Reboot all nodes
##
## If you use the network interface, eth0, you can run the function below to configure static network and hostname instead of manual network configuration.
#NetworkInterfaceAndHostname on_GRP0

#ChronyForNtpServer on_GRP1
#ChronyForNtpClient on_GRP2

## Temporary admin task
#RefreshRepo on_GRP0





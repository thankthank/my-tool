#!/bin/bash

######################
## USER jobs 
#GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT" ["on_GRP2"]="RANCHER" ["on_GRP3"]="D_MASTER" ["on_GRP4"]="D_WORKER" ["on_GRP5"]="RMS" ["on_GRP6"]="none" ["on_GRP7"]="none" ["on_GRP8"]="none" ["on_GRP9"]="none" ) 

## Run the function below when ssh access with key is not implemented. 
#TempSshPrivateKeyForDeployment on_GRP1
#TempSshPublicKeyForDeployment on_GRP0
#MyToolDeployment on_GRP1

#RegisterRepositories on_GRP0
#RegistertoSMT on_GRP0
#SshKnownhost on_GRP0

## Network and System Configuation functions
#EtcHosts on_GRP0
#BasicNetwork on_GRP2
#BasicPackageInstallation on_GRP0
#FileCopyToAll on_GRP1
#CAConfiguration on_GRP0
#SystemdAccounging on_GRP0
#SwapOff on_GRP0

## 2. Reboot all nodes
##
## If you use the network interface, eth0, you can run the function below to configure static network and hostname instead of manual network configuration.
#NetworkInterfaceAndHostname on_GRP0

#Chrony_for_ntp_server on_GRP1
#Chrony_for_ntp_client on_GRP2

#! DNSserverDeployment on Management server

#Create_Certificate on_GRP1
#Local_registry_deployment on_GRP1

#LoadbalancerDeployment on_GRP1

## Temporary admin task
#RefreshRepo on_GRP0

################
# Rancher deployment
#GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT" ["on_GRP2"]="RANCHER" ["on_GRP3"]="D_MASTER" ["on_GRP4"]="D_WORKER" ["on_GRP5"]="RMS" ["on_GRP6"]="none" ["on_GRP7"]="none" ["on_GRP8"]="none" ["on_GRP9"]="none" ) 

#SystemConfiguration on_GRP2

## Rancher deployment on RMS
#RancherDeployment on_GRP5

## Downstream Cluster deployment
#DMasterDeployment on_GRP3
#CopytokentoAll on_GRP1
#DWorkerDeployment on_GRP4
#Kubectlsetting on_GRP1
#! Import_downstream_Cluster 

## Longhorn deployment
#! Make partition for Longhorn
#! Deploy Longhorn using Apps & Marketplace
  #Change Default storage location and replica size before deployment
  #add Disk manually

## ingress Congroller deployment
#! IngressController 
  #Deploy ingress controller from bitnami chart repo with values below
    #service:
    #type: NodePort
    #nodePorts:
    #  https: 30443
    #  http: 30080

## Minio deployment
#! Add bitnami helm chart : https://charts.bitnami.com/bitnami
  #Edit helm value yaml : 
  	#volume size 
  #namespace : minio, name : minio
#MinioPostDeployment on_GRP1

## SAP Configuration
#SAPConfig on_GRP1
#SAPpostinstallation on_GRP1

#Developing on_GRP4


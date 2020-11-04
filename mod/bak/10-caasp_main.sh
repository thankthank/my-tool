#!/bin/bash

######################
### CaaSP deployment

## sles user creation for skuba
#CreateUserWithKeyAccess on_GRP1

#Registry_proxy on_GRP2

#Create_Certificate on_GRP1
#Local_registry_deployment on_GRP1
#Local_registry_load_images on_GRP1
#HelmLocalChartRepoDeployment on_GRP1
#LoadbalancerDeployment  on_GRP1

## K8s cluster deployment
#Initialize_the_cluster on_GRP1

## From here, tasks need to be done one by one slowly!!!!!!!!!!!!!!!
## Watch pod deployment status with 'kubectl -n kube-system get pods -o wide -w --all-namespaces'. Once pods deployment on each node is finished, proceed next step.
#Bootstrap_the_cluster on_GRP1
#Setup_kubectl on_GRP1

## Add the second master node
#Addtional_node master ${MASTER[1]} on_GRP1
## Add the third master node 
#Addtional_node master ${MASTER[2]} on_GRP1
## Add the first worker node
#Addtional_node worker ${WORKER[0]} on_GRP1
## Add the second worker node
#Addtional_node worker ${WORKER[1]} on_GRP1
## Add the third worker node
#Addtional_node worker ${WORKER[2]} on_GRP1

## If you deployed three masters, run the function.
#LoadbalancerDeploymentwithThreeMaster on_GRP1

#Helm_Deployment on_GRP1

#Kubernetes_UI on_GRP1

## Centralized Logging
#RsyslogserverDeployment on_GRP1
#CentralizedLoggingAgent on_GRP1

## Storageclass creation and secret creation in monitoring, kube-system and default namespace
##########################
## Manual task below
## 1. Configure root ssh access with key to Ceph Admin node.
## 2. And then run the function below.
#StorageclassPVCwithCephRBD on_GRP1

## Monitoring Deployment. 
#NginxIngressControllerDeployment on_GRP1
#SMTPsender on_GRP1
#MonitoringStackDeployment on_GRP1
#MonitoringETCDCluster on_GRP1

## ETC
#Local_registry_remove on_GRP1
#start_ManagementComponentsAfterReboot on_GRP1
#Test  123 223 on_GRP2
#TarBallDecompress 123 on_GRP1
#AccessProxy on_GRP1
#PreparationBeforeDemo on_GRP1
## Deployment tool preparation functions
#AirgappedTarBallDeployment on_GRP1
#DeployRepositories on_GRP1

### Configuration for SAP DH/DI : SAP note 2898735
#SAPDHConfiguration1 on_GRP2
#SAPDHConfiguration2 on_GRP1
#SAPDHConfiguration3 on_GRP1
#Ingress_vsystem
#LoadbalancerDeploymentforS3  on_GRP1



## The functions in WIP
## Update nodes
## 0. OS manual update configuration
## 1. Copy the airgap tar file and overwrite into the same directory
## 2. Deploy Repo on Management and refersh repo by 'zypper ref' on Management
#RereshRepo on_GRP2
#Local_registry_load_images on_GRP1
#HelmLocalChartRepoDeployment on_GRP1
## OS update
#UpdateNodes on_GRP1




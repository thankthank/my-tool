#!/bin/bash

######################
### SES deployment

## Salt configuration
#SaltMaster on_GRP1
#SaltMinion on_GRP0
#SaltMinion on_GRP5
#AcceptMinion on_GRP1

## Ceph deployment
## do not deploy the Ceph OSD, Metadata Server, or Ceph Monitor role to the Admin Node.
## Check minion status with "salt-run manage.status"
#CephSaltDeployment on_GRP1

## Ceph-salt configuration
## The /etc/ceph/ceph.conf file is managed by the new ceph config command from cephadm
# Initial deployment
#CephSaltBootstrap on_GRP1
#CephAdmCoreDeployment on_GRP1

# Addtional node
#AddnodeInCephsalt on_GRP1


## Node management 
# Removal
#RemoveOsd on_GRP1
#RemoveOSDManual on_GRP1
#RemoveNode on_GRP1

# Replacement
#ReplaceOSD

## Service Deployment
#CreateCephFS on_GRP1
#GaneshaDeployment on_GRP1

# SMB
#SambaGWDeployment_1 on_GRP6
#SambaGWDeployment_2 on_GRP1
# Mount cephfs which will be used by SambaGW
#SambaGWDeployment_3 on_GRP6

# iSCSI
#iSCSIGWdeployment on_GRP1
#iSCSITargetDeployment on_GRP7

# Monitoring
#MonitoringStackDeployment on_GRP1

# RGW
#RGWdeployment on_GRP1
#cephtemp on_GRP1

## Operation
# Shutdown
#ShutdownSES 64195818-28de-11eb-8a00-525400e2f09b on_GRP1
#StartupSES on_GRP1

#PoolRbdmanagement on_GRP1
#RadosGWManagement on_GRP1
#CephFSManagement on_GRP6
#RadosManagement on_GRP1
#CrushmapGet on_GRP1

#cephtemp on_GRP7








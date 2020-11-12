#!/bin/bash

######################
### SES deployment

## Salt configuration
#SaltMaster on_GRP1
#SaltMinion on_GRP0
#AcceptMinion on_GRP1

## Ceph deployment
## do not deploy the Ceph OSD, Metadata Server, or Ceph Monitor role to the Admin Node.
## Check minion status with "salt-run manage.status"
#CephSaltDeployment on_GRP1

## Ceph-salt configuration
## The /etc/ceph/ceph.conf file is managed by the new ceph config command from cephadm
## "ceph-salt config" to get in interactive shell
## "ceph-salt config ls" to list all values
#CephSaltBootstrap on_GRP1

#CephAdmCoreDeployment on_GRP1

cephtemp on_GRP1









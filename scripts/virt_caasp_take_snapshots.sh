#!/bin/bash

NAME="BeforeK8SDeployment"
DESCRIPTION="Before K8S Deployment"
TARGET=(caasp-lb caasp-master1 caasp-worker1 caasp-worker2 caasp-worker3)

for i in "${TARGET[@]}";do

virsh destroy $i;
sleep 1;
virsh snapshot-create-as --domain $i --name "$NAME" --description "$DESCRIPTION"
sleep 1;
#virsh start $i;

done

#!/bin/bash

NAME="BeforeSES7Deployment"
DESCRIPTION="Before SES7 Deployment"
TARGET=(ses1_admin ses2 ses3 ses4)

for i in "${TARGET[@]}";do

virsh destroy $i;
sleep 1;
virsh snapshot-create-as $i --name "$NAME" --description "$DESCRIPTION"
#virsh snapshot-create --domain $i --name "$NAME" --description "$DESCRIPTION"
sleep 1;
virsh start $i;

done

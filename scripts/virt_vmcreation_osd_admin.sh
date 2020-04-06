#!/bin/bash

if [[ $1 == "" ]];then echo "no parameter";exit 1;fi
VMNAME=$1
VMLOCATION="/home/vms"

OSTEMPLATE="/home/vms/template/jeos15sp1-tem-50G.qcow2"

OSD_SIZE="20G"
NUM_VCPU=2
NUM_MEM=2048

## Create directory
mkdir -p $VMLOCATION/$VMNAME

## Create data qcow2 disk
#for i in {1..8};do
for i in {1..2};do
	qemu-img create -f qcow2 $VMLOCATION/$VMNAME/osd${i}.qcow2 $OSD_SIZE
done

## Copy OS image
cp $OSTEMPLATE $VMLOCATION/$VMNAME/os.qcow2

## Create VMs
virt-install --name=$VMNAME \
	--vcpus=$NUM_VCPU \
	--memory=$NUM_MEM \
	--os-variant=sles12sp4 \
	--disk $VMLOCATION/$VMNAME/os.qcow2 \
       	--disk $VMLOCATION/$VMNAME/osd1.qcow2 \
       	--disk $VMLOCATION/$VMNAME/osd2.qcow2 \
	--import \
	--network type=direct,source=eth0,source_mode=bridge,model=virtio


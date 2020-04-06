#!/bin/bash

for i in master1 worker1 worker2 worker3;do
virt-clone --original caasp-template --name caasp-$i --file /home/vmvms/caasp-$i/os.qcow2;
done;

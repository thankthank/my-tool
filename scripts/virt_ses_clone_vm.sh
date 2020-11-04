#!/bin/bash

for i in ses2 ses3 ses4 ;do
virt-clone --original ses1_admin --name $i \
	--file /home/vms/$i/os.qcow2
	--file /home/vms/$i/osd1.qcow2
	--file /home/vms/$i/osd2.qcow2
;
done;

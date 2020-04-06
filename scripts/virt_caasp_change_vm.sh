#!/bin/bash

for i in master1;do 
	virsh setmaxmem caasp-$i --size 6G --config; 
	virsh setmem caasp-$i --size 6G --config;
done;

for i in worker1 worker2 worker3;do 
	virsh setmaxmem caasp-$i --size 3G --config; 
	virsh setmem caasp-$i --size 3G --config;
done;

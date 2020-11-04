#!/bin/bash


if [[ $1 == "" ]];then 
	echo Please Enter parameter $1;
	exit 1;
fi

PRODUCT=$1

INFRAORG=(main target_mapping env )
for i in ${INFRAORG[@]};
do
	cp 99-infra_$i 00-infra_${PRODUCT}_$i.sh
done

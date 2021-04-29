#!/bin/bash


if (( ${#@} != 2 )); then
	echo Please Enter two parameters;
	exit 1
fi

PRODUCT=$1
SCRIPTNUM=$2

INFRAORG=(main target_mapping env func )
for i in ${INFRAORG[@]};
do
	cp 99-infra_$i $2-${PRODUCT}_$i.sh
done

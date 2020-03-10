#!/bin/bash
## Function names must start with this library file name. 
## e.g. This library file name is my_lib so function names start with mylib_<function name> ()
## And the function name itself start with Capital character. So if the function name is 'wait', the total function name is mylib_Wait ()


mylib_Wait () {
	local DEFAULT_SEC="10"
	if [[ $1 == "" ]];then DEFAULT_SEC="10";
	else DEFAULT_SEC=$1
	fi

	echo "sleep $DEFAULT_SEC seconds"
	for (( i=$DEFAULT_SEC ; i >0 ; i--   ))
	do
		sleep 1 ;echo -n "$i..";
	done
	echo;


}

mylib_Scp_run() {
##########
# $@ : remote host
# usage 
#	# Scp_run 192.168.0.11 192.168.0.12

local RANDOM_FILE=''
local RANDOM_FILE=lab_$RANDOM

cat << EOT > $RANDOM_FILE
##########
##########
#Put your script here

echo "remote run test2" > /root/test1

#The end of Script
##########
EOT
chmod 755 $RANDOM_FILE


for host in "$@"
do
        scp $RANDOM_FILE ${host}:~/
        ssh $host ./$RANDOM_FILE
        ssh $host rm -f ./$RANDOM_FILE
done

rm -f $RANDOM_FILE

}

mylib_Check_parameter() {

#Check parameter
if [[ $1 == "" ]]
then
	echo "No repository ip address"
	exit 1;
fi

}

mylib_Debug () {
	echo _Debug_CMD:$(date +%y%m%d_%H:%M:%S): "$@"
	echo OUTPUT-Started:
	"$@"
	echo OUTPUT-Done
}

mylib_Debug_print () {
	#Only print Command and no results. It will be used commands which include terminator such as ;, >, ||
	# Use single quote in Single quote
	# e.g. Debug_print $'echo \'ls -al\' | grep tt '

	echo _Debug_CMD:$(date +%y%m%d_%H:%M:%S): "$@"
}

#!/bin/bash

#GLOBAL1="Global value before Test_Func"

source ./test_func.sh

#GLOBAL2="Global value after Test_Func"
#########Main##############

RUN_FUNC=$(cat test_func.sh  | grep run_ | grep \(\) | cut -d"(" -f1)

for i in $RUN_FUNC;
do
	$i "$@"
done;

#GLOBAL3="Global value after RUN_FUNC"
# bash  positional parameter test
#echo '$* test with for'
#for i in $*;do echo $i;done;
#echo

#echo '"$*" test with for'
#for i in "$*";do echo $i;done;
#echo

#echo '$@ test with for'
#for i in $@;do echo $i;done;
#echo

#echo '"$@" test with for'
#for i in "$@";do echo $i;done;
#echo

#echo '$# test with for'
#for i in $#;do echo $i;done;
#echo

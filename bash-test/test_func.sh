#!/bin/bash

source_test() {

if [[ ! -e /root/source_test_dir ]]; 
then
	mkdir source_test_dir
else 
	echo Directory exists
	cd /root/source_test_dir
	echo "/dk & (this: ) } { * " 
fi


}

TERM=$(tty)
Debug () {

echo _Debug_CMD:$(date +%y%m%d_%H:%M:%S): "$@"
echo OUTPUT-Started:
"$@"
echo OUTPUT-Done

#Debug ls -al|tee $TERM |grep -v _Debug_CMD > test_file
#Output is mixed so it is hard to figure it out.
#Debug ls -al|tee $TERM |grep -v _Debug_CMD | Debug grep registry


## 2019.09.25 : Commented the lines below because, it fork another process to run script and lose environment.
#echo "\$@" > \$CMDFILE
#CMDFILE=/root/cmd_tmp_\$(date +%y%m%d%H%M%S).sh
#bash \$CMDFILE 2>&1 | tee -a $Logfile
#rm -f \$CMDFILE

## For single guote in single quote, you can do it as follows.
##e.g. Debug $'ls -al \'ttt\'  '
## When I run echo "$@", the escape of single quote is removed. However, When I just execute "$@", the escape of single quote is excuted together as follows.
##I also tried to run after 'echo' the "$@" such as echo "$@" | bash. But it doesn't work in some case. So I just write a file and run it.
##e.g. + sed -i ''\''s/NETCONFIG_DNS_STATIC_SEARCHLIST=""/NETCONFIG_DNS_STATIC_SEARCHLIST="suse.su"/g'\''' /etc/sysconfig/network/config
}

Debug_print () {
#Only print Command and no OUTPUT. It will be used commands which include terminator such as ;, >, ||
# Use single quote in Single quote
# Debug_print $'echo \'ls -al\' | grep tt '

echo _Debug_CMD:$(date +%y%m%d_%H:%M:%S): "$@"
}

Paste_top () {
cat $2 >> $1; mv $1 $2
}


sed_cut() {

#File creation

FILE="/root/script/ex5"
echo "cn=lisa,dc=example,dc=com" > $FILE
echo "cn=chris,dc=example,dc=com" >> $FILE
echo "cn=gang,dc=example,dc=com." >> $FILE

#extract username
awk -F, '/cn=/ {print $1}' $FILE | cut -d= -f2 > ${FILE}_new 



#Add user

## existing user

#debug cat ${FILE}_new
for i in `cat ${FILE}_new`
do
	echo start
	echo start
	PASSWD=$(cut -d: -f1 /etc/passwd | grep ^$i)
	#echo before trim : $i: ${#i}, $PASSWD: ${#PASSWD}
	
	PASSWD=$(echo $PASSWD | sed "s/ //g")
	i=$(echo $i | sed "s/ //g")
	#echo after trim : $i: ${#i}, $PASSWD: ${#PASSWD}
	
	if [[ $i != $PASSWD   ]]
	then
		echo "No existing users so I can add user"
		echo adduser $i
	else
		echo "$i user exists"
	fi
done

 
}


getopts_arithmetic_if_test1() {

#Get opts and parsing and setting
# -a : username, -b number, file_name
while getopts "a:b:" OPTS
do
	case $OPTS in 
	a) echo USERNAME: $OPTARG; USERNAME=$OPTARG;;  
	b) echo NUMBER: $OPTARG; NUMBER=$OPTARG;;
	*) echo Please -a -b; exit 1;
	esac
done

echo OPTIND : $OPTIND
shift $(( OPTIND-1  ))

FILENAME=$1;

#parameter check and setting default

if [[ -z $USERNAME ]];then USERNAME="Defaltname";
else USERNAME=$(echo $USERNAME | tr [:lower:] [:upper:]);
fi;

if [[ -z $NUMBER ]]; then NUMBER=5;fi;

echo the number of parameter without option : $#
i=$#
echo i: $i;
#if [[ -z $@ ]] ;then echo At least one parameter; exit 1; fi;
if (( i != 0  )) ;then echo if_true; 
	(( i=i+1 ))
	echo i: $i
else echo if_false;
fi


# copy with user name with the number of times
echo;echo;echo Print username the number of times!!!!!
for (( i=0 ; i < $NUMBER; i++  ))
do
	(( j=i+1 ))
	echo ${USERNAME}_${FILENAME}_${j}

done


}


select_test() {

select TASK in 'ls' 'find' 'df -h'
do

	echo TASK : $TASK
	
	case $TASK in 
	ls) echo LS;;
	find) echo find;;
	'df -h') echo 'df -h';;
	*) echo Enter different falue; continue;
	esac

echo Select done

done


}


trap_case_test() {

#Redifine signals using Trap
trap "echo nono" INT
trap "echo nono" TERM
trap "echo nono" KILL


#menu
#reset password, show disk usage, ping a lost, log out
trap DEBUG

select TASK in 'Reset Password' 'show disk Usage' 'ping a lost' 'log out'
do
	#case $TASK in 
	#'Reset Password') echo run_reset;;
	#'show disk Usage') echo show disk;;
	#'ping a lost') echo ping;;
	#'log out') echo logout; exit;;
	#*) echo Enter again; continue;
	#esac
	
	case $REPLY in 
	1) echo run_reset : $TASK;;
	2) echo show disk : $TASK;;
	3) echo ping : $TASK;;
	4) echo logout : $TASK; exit;;
	*) echo Enter again; continue;
	esac

done

trap - DEBUG
}

debug_test() {

VALUE=`ls`

echo Test Started
echo $VALUE

}

Random_gugudan() {


cat > /root/script/here << COMMENTS
this is long comment

any  way you can do
this is comment
you can use this as comments
$RANDOM

COMMENTS

while true 
do
	
	##random number and answer
	(( X = RANDOM % 9 ))
	(( X++ ))
	(( Y = RANDOM%9 ))
	(( Y++ ))
	(( RESULT = X*Y ))
#	echo $X, $Y, $RESULT
	
##get answer
	read -p "$X * $Y =  " ANSWER
#	echo $ANSWER
## Action
	if (( RESULT == ANSWER )) ;
	then 
		echo "Correct !!!"
	else 
		echo "Wrong !!!"
		echo "Answer is $RESULT"
	fi

done

}

################################
#variable
global_variable_test() {

	echo GLOBAL1 : $GLOBAL1;
	echo GLOBAL2 : $GLOBAL2;
	echo GLOBAL3 : $GLOBAL3;


}

run_variable_array_test() {

ARRAY_TEST=(abc b c d e)
MASTER=(caasp-master1 caasp-master2 caasp-master3)
MASTER_IP=(192.168.37.71 192.168.37.72 192.168.37.73)

echo array test
for i in {0..5};do
	echo i : $i
	#echo '${#ARRAY_TEST[$i]}: ' ${#ARRAY_TEST[$i]}
	#echo '${ARRAY_TEST[$i]}: ' ${ARRAY_TEST[$i]}
	echo ${MASTER[$i]} : ${MASTER_IP[$i]}
done

#echo "${ARRAY_TEST[@]}"

}

variable_array_aggregation() {
#hostname and IP
MASTER=(caasp-master1 )
MASTER_IP=(192.168.37.30 )
WORKER=(caasp-worker1 caasp-worker2 caasp-worker3)
WORKER_IP=(192.168.37.31 192.168.37.32 192.168.37.33)

# Hostname and IP aggregation
HOSTNAME_TOTAL=()
HOSTNAME_TOTAL[0]=caasp-lb

j=${#HOSTNAME_TOTAL[@]};for i in "${MASTER[@]}";do
	HOSTNAME_TOTAL[$j]=$i;
((j=j+1));done;

j=${#HOSTNAME_TOTAL[@]};for i in "${WORKER[@]}";do
	HOSTNAME_TOTAL[$j]=$i;
((j=j+1));done;

IP_TOTAL=()
IP_TOTAL[0]=192.168.37.71

j=${#IP_TOTAL[@]};for i in "${MASTER_IP[@]}";do
	IP_TOTAL[$j]=$i;
((j=j+1));done;

j=${#IP_TOTAL[@]};for i in "${WORKER_IP[@]}";do
	IP_TOTAL[$j]=$i;
((j=j+1));done;

}

variable_parameter() {

echo "\$@ is $@"

if [[ -z $1 ]] ;
then 
	echo Please input file to copy
	read FILE_NAME
else
	FILE_NAME="$@"
fi

for i in $FILE_NAME
do 
	echo "copy $i"
	cp ./$i ~/
done

}

variable_expansion_parse() {

DATE=$(date +%d-%m-%y)

echo date is ${DATE%%-*}
TMP=${DATE%-*}
echo month is ${TMP#*-}
echo year is ${DATE##*-}

name="Variable in character"
echo ${name}this
}

variable_location3() {

ValueInLocation3="Variable in Other function will not be printed"
}

ValueInLocation4="Variable in Global script will be printed"
variable_location() {

echo Variable_in_location2 : $ValueInLocation2
echo Variable in other function : $ValueInLocation3
echo Variable_in_location4 : $ValueInLocation4
echo Variable Below Print Function : $ValueBelowFunction
}

variable_location2() {

echo "Variable after function"

ValueInLocation2="Variable above the print function will be printed"
variable_location
ValueBelowFunction="what?"

}

####################################
#awk
awk_search_tr() {

STRING='cn=laRa,dc=example,dc=com'
echo $STRING > /root/script/ex4_data
echo STRING : $STRING

USER=$(awk -F, '/cn/ {print $1} ' /root/script/ex4_data)
echo This is the result of USER : $USER
USER=${USER#*=}
echo This is the result of USER : $USER
USER=$(echo $USER | tr [:upper:] [:lower:])

echo This is the result of USER : $USER

}

awk_variable_test() {

VALUE="a b itworks good"
VALUE_array=(a b itworks good)
SECOND="Second values"

for i in ${VALUE}
do
	ls -al | head -1 | awk -v AV="$i" -v AV2="$SECOND" '{print "this is The value from AWK : "AV"  "AV2 }'	

done

echo
echo
echo "array"
for i in ${VALUE_array[@]}
do
	ls -al | head -1 | awk -v AV="$i" '{print "this is The value from AWK : "AV }'	

done
}

###################################
#for
for_arithmetic_test() {
#1 ~ 5, 1 ~ 4,1 ~ 3 ...

	for (( i=5 ; i>0 ; i-- ));
	do
		#for (( j=1; j<($i+1)*2 ; j++ ));
		for (( j=1; j<$i+1 ; j++ ));
		do
			echo -n ${j}
		done;
		echo 
	done;
}

for_variable_expension_test() {

for i in {1..5}
do
	for j in {1..$i}
	do
		echo -n $j
	done
	
	echo
done
}

########################################
#if
if_echo_test() {

if [ -n "$BASH_ENV" ]; then echo "test env";echo "$BASH_ENV"; fi

echo "new line \
 this is after new line"
echo
echo "new line2
this is after new line2"

echo
echo "`ls`"

echo "\$  \' \`  \"  \\"


}

##########################################
#echo
echo_test() {

RED='\e[0;31m'
NC='\e[0m'

echo -e "${RED}Hello word with e option${NC}"
echo "${RED}Hello word without e option${NC}"

}


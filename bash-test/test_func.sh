#!/bin/bash

value_test() {

name="Hello World"


echo ${name}this

}

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

bash_etc_test() {

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

bash_array_test() {

ARRAY_TEST=(abc b c d e)

echo array test
echo ${#ARRAY_TEST[0]}

echo "${ARRAY_TEST[@]}"

}

eval_test() {

for i in {1..5}
do
	for j in {1..$i}
	do
		echo -n $j
	done
	
	echo
done


}

echo_test() {

RED='\e[0;31m'
NC='\e[0m'

echo -e "${RED}Hello word with e option${NC}"
echo "${RED}Hello word without e option${NC}"

}

echo_test2() {


echo "Hello word in another function"

}

Le1_Ex1() {

cp /var/log/messages /var/log/messages.old

echo 'echo ""  > /var/log/messages'

echo Let\'s check if old file exists 

ls -al /var/log/messages.old

}

source_test() {

if [[ ! -e /root/source_test_dir ]]; 
then
	mkdir source_test_dire
else 
	echo Directory exists
	cd /root/source_test_dir
	echo "/dk & (this: ) } { * " 
fi


}

Le2_Ex1_parameter() {

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

Le3_ex1_variable_expansion() {

DATE=$(date +%d-%m-%y)

echo date is ${DATE%%-*}
TMP=${DATE%-*}
echo month is ${TMP#*-}
echo year is ${DATE##*-}

}

ex4_awk_tr() {

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

debug () {

echo COMMAND: "$@"
"$@"

}



ex5_sed_cut() {

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


Le6_getopts_arithmetic_if_test1() {

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


Le6_select_test() {

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

Le6_trap_logger_test() {

echo "log test"

}


Le6_ex6() {

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

global_vari_test() {

	echo GLOBAL1 : $GLOBAL1;
	echo GLOBAL2 : $GLOBAL2;
	echo GLOBAL3 : $GLOBAL3;


}

run_awk_vari_test() {

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

#!/bin/bash

declare -A GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT_IP" ["on_GRP2"]="OTHERS_IP" ["on_GRP3"]="PRIMARY_IP" ["on_GRP4"]="SECONDARY_IP" ["on_GRP5"]="NEW" ["on_GRP6"]="SMB" ["on_GRP7"]="none" ["on_GRP8"]="none" ["on_GRP9"]="none" ) #CHANGEME

GRP0=() #CHANGEME
j=${#GRP0[@]};for i in "${PRIMARY_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
j=${#GRP0[@]};for i in "${SECONDARY_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
GRP1=() #CHANGEME
GRP1[0]=MGMT_IP
GRP2=() #CHANGEME
j=${#GRP2[@]};for i in "${OTHERS_IP[@]}";do GRP2[$j]=$i; ((j=j+1));done; 
GRP3=() #CHANGEME
j=${#GRP3[@]};for i in "${PRIMARY_IP[@]}";do GRP3[$j]=$i; ((j=j+1));done;
GRP4=() #CHANGEME
j=${#GRP4[@]};for i in "${SECONDARY_IP[@]}";do GRP4[$j]=$i; ((j=j+1));done;
#GRP5=() #CHANGEME
#j=${#GRP5[@]};for i in "${NEW_IP[@]}";do GRP5[$j]=$i; ((j=j+1));done;
#GRP6=() #CHANGEME
#j=${#GRP6[@]};for i in "${SMB_IP[@]}";do GRP6[$j]=$i; ((j=j+1));done;
#GRP7=() #CHANGEME
#j=${#GRP7[@]};for i in "${SMB_IP[@]}";do GRP7[$j]=$i; ((j=j+1));done;
#GRP8=() #CHANGEME
#j=${#GRP8[@]};for i in "${SMB_IP[@]}";do GRP8[$j]=$i; ((j=j+1));done;
#GRP9=() #CHANGEME
#j=${#GRP9[@]};for i in "${SMB_IP[@]}";do GRP9[$j]=$i; ((j=j+1));done;

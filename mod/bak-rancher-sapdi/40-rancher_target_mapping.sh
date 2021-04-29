#!/bin/bash

declare -A GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT" ["on_GRP2"]="RANCHER" ["on_GRP3"]="D_MASTER" ["on_GRP4"]="D_WORKER" ["on_GRP5"]="RMS" ["on_GRP6"]="none" ["on_GRP7"]="none" ["on_GRP8"]="none" ["on_GRP9"]="none" ) #CHANGEME

GRP0=() #CHANGEME
j=${#GRP0[@]};for i in "${IP_TOTAL[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
GRP1=() # MGMT
j=${#GRP1[@]};for i in "${MGMT_IP[@]}";do GRP1[$j]=$i; ((j=j+1));done;
GRP2=() # Rancher only
j=${#GRP2[@]};for i in "${RMS_IP[@]}";do GRP2[$j]=$i; ((j=j+1));done; 
j=${#GRP2[@]};for i in "${D_MASTER_IP[@]}";do GRP2[$j]=$i; ((j=j+1));done; 
j=${#GRP2[@]};for i in "${D_WORKER_IP[@]}";do GRP2[$j]=$i; ((j=j+1));done; 
GRP3=() #CHANGEME
j=${#GRP3[@]};for i in "${D_MASTER_IP[@]}";do GRP3[$j]=$i; ((j=j+1));done;
GRP4=() #CHANGEME
j=${#GRP4[@]};for i in "${D_WORKER_IP[@]}";do GRP4[$j]=$i; ((j=j+1));done;
GRP5=() #CHANGEME
j=${#GRP5[@]};for i in "${RMS_IP[@]}";do GRP5[$j]=$i; ((j=j+1));done;
#GRP6=() #CHANGEME
#j=${#GRP6[@]};for i in "${SMB_IP[@]}";do GRP6[$j]=$i; ((j=j+1));done;
#GRP7=() #CHANGEME
#j=${#GRP7[@]};for i in "${SMB_IP[@]}";do GRP7[$j]=$i; ((j=j+1));done;
#GRP8=() #CHANGEME
#j=${#GRP8[@]};for i in "${SMB_IP[@]}";do GRP8[$j]=$i; ((j=j+1));done;
#GRP9=() #CHANGEME
#j=${#GRP9[@]};for i in "${SMB_IP[@]}";do GRP9[$j]=$i; ((j=j+1));done;

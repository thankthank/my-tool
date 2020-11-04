#!/bin/bash

declare -A GRP_MAP=( ["on_GRP0"]="ALL" ["on_GRP1"]="MGMT_IP" ["on_GRP2"]="MON_IP" ["on_GRP3"]="OSD_IP" ["on_GRP4"]="SES_IP" ["on_GRP5"]="NONE") #CHANGEME

GRP0=() #CHANGEME
j=${#GRP0[@]};for i in "${MGMT_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
j=${#GRP0[@]};for i in "${MON_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
j=${#GRP0[@]};for i in "${OSD_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
j=${#GRP0[@]};for i in "${MONITORING_IP[@]}";do GRP0[$j]=$i; ((j=j+1));done; 
GRP1=() #CHANGEME
j=${#GRP1[@]};for i in "${MGMT_IP[@]}";do GRP1[$j]=$i; ((j=j+1));done; 
GRP2=() #CHANGEME
j=${#GRP2[@]};for i in "${MON_IP[@]}";do GRP2[$j]=$i; ((j=j+1));done; 
GRP3=() #CHANGEME
j=${#GRP3[@]};for i in "${OSD_IP[@]}";do GRP3[$j]=$i; ((j=j+1));done;
GRP4=() #CHANGEME
j=${#GRP4[@]};for i in "${SES_IP[@]}";do GRP4[$j]=$i; ((j=j+1));done;
#GRP5=() #CHANGEME
#j=${#GRP5[@]};for i in "${MON_IP[@]}";do GRP5[$j]=$i; ((j=j+1));done;
#j=${#GRP5[@]};for i in "${OSD_IP[@]}";do GRP5[$j]=$i; ((j=j+1));done;

#!/bin/bash

## Match - GRP0: all, GRP1: MGMT, GRP2: Others, GRP3: Primary, GRP4: Seconcary

#StaticHostname on_GRP0
#ConfigureCliRegion $REGION on_GRP0
#TaggingEC2instances on_GRP0
#AddRolsandPolicies on_GRP3
#AddOverlayIPAddress on_GRP3

#ConfigureEC2 on_GRP0
#ConfigureNetwork on_GRP0

## Basic Cluster with fence agent and overlay IP
#Corosynckey on_GRP2
#BootstrapCluster on_GRP-1
#ConfigureProperty_Stonith on_GRP2


## Install SAP applications

## HA for SAP HANA
#sapHANA_HA_DR_profider on_GRP0


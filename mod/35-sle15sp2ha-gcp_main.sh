#!/bin/bash

## Match - GRP0: all, GRP1: MGMT, GRP2: Others, GRP3: Primary, GRP4: Seconcary

#StaticHostname on_GRP0
#ConfigureCliRegion $REGION on_GRP0
#TaggingEC2instances on_GRP0 #for EC2 Fence Agent
#AvoidDeletionOverlayIPNoSource on_GRP0
#AddRolsandPolicies on_GRP3
#AddOverlayIPAddress on_GRP3

#ConfigureEC2 on_GRP0

## Basic Cluster with fence agent and overlay IP
#DisklessSBD on_GRP0
#Corosynckey on_GRP3
#BootstrapCluster on_GRP0
#PacemakerStart on_GRP0
#ConfigureProperty_Stonith on_GRP3

## Install SAP applications

## HA for SAP HANA
#sapHANA_HA_DR_profider on_GRP0 # It is okay to PASS
#setMaintenanceMode on_GRP3
#sapHANA_crm_configuration on_GRP3
#sapSR_check on_GRP1


#HA_test on_GRP3


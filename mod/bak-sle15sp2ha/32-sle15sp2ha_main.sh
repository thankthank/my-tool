#!/bin/bash
## Main
## Target : GRP0-all, GRP1-mgmt, GRP2-others, GRP3-primary, GRP4-seconds

#iSCSIclientInitiator on_GRP2
#iSCSITarget on_GRP1
#ClusterRelatedNetworkDevice on_GRP1
#HA_BootstrapClusterBoth on_GRP2

#HA_BootstrapClusterPrimary on_GRP3
#HA_addnodes on_GRP4

#HA_createDRBD on_GRP2
#HA_createDRBDPrimary on_GRP3

HA_pcmkConfig on_GRP3

#Temp on_GRP2





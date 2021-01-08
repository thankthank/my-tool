#!/bin/bash

## functions for SES 7

SaltMaster () {

	Debug zypper --non-interactive in -y salt-master;
	sed -i 's/#log_level_logfile: warning/log_level_logfile: info/g' /etc/salt/master
	Debug systemctl enable salt-master.service;
	Debug systemctl start salt-master.service;

}

SaltMinion () {

	zypper --non-interactive in salt-minion;
	sed -i 's/#log_level_logfile:/log_level_logfile: info/g' /etc/salt/minion
	echo "master: $MGMT_FQDN" > /etc/salt/minion.d/master.conf
	systemctl restart salt-minion;
	systemctl enable salt-minion;

}


# run on management
AcceptMinion() {

	Debug salt-key -F
	Debug salt-key --accept-all
	Debug salt-run manage.status

	## This configuration disappears after reboot.
	#Debug_print salt '*' grains.append deepsea default
	#salt '*' grains.append deepsea default
	#Debug_print salt -G 'deepsea:*' test.ping
	#salt -G 'deepsea:*' test.ping


}

## Deployment
# run on master
CephSaltDeployment () {

	zypper --non-interactive in ceph-salt
	systemctl restart salt-master.service
	Debug salt \* saltutil.sync_all

}

CephSaltBootstrap() {

	Debug ceph-salt config /cephadm_bootstrap/dashboard/username set ceph-admin
	Debug ceph-salt config /ceph_cluster/minions add '*'
	# include all nodes as well as admin node
	Debug ceph-salt config /ceph_cluster/roles/cephadm add '*'

	# homo-env : ceph admin and salt master located together, hetero-env : ceph admin and salt master will be seperated.
	Debug ceph-salt config /ceph_cluster/roles/admin add $MGMT_FQDN
	Debug ceph-salt config /ceph_cluster/roles/bootstrap set ${MON[0]}.$DOMAIN
	
	# Tuned profile. Choose one of latency or throughput
	for i in ${OSD[@]};
	do
		
		#Debug ceph-salt config /ceph_cluster/roles/tuned/latency add $i.$DOMAIN
		Debug ceph-salt config /ceph_cluster/roles/tuned/throughput add $i.$DOMAIN
	done

	Debug ceph-salt config /ssh generate
	Debug ceph-salt config /time_server disable
	# Dashboard
	Debug ceph-salt config /cephadm_bootstrap/dashboard/username set admin
	Debug ceph-salt config /cephadm_bootstrap/dashboard/password set CHANGEME
	Debug ceph-salt config /cephadm_bootstrap/dashboard/force_password_update disable
	# Registry. ?local registry later
	Debug ceph-salt config /cephadm_bootstrap/ceph_image_path set registry.suse.com/ses/7/ceph/ceph
	
	# Optionally, Cluster network
	Debug ceph-salt config /cephadm_bootstrap/ceph_conf add global
	Debug ceph-salt config /cephadm_bootstrap/ceph_conf/global set cluster_network 192.168.60.0/24
	# Configuration backup
	Debug ceph-salt status
	Debug_print $'ceph-salt export > $froLOCAL_REPO_DIR/cluster.json'
	ceph-salt export > $froLOCAL_REPO_DIR/cluster.json
	# import configuration
	#ceph-salt import $froLOCAL_REPO_DIR/cluster.json

	# Nodes update
	Debug_print Manually update nodes 
#	Debug_print ceph-salt update
#	Debug_print ceph-salt update --reboot
#	Debug_print ceph-salt reboot

	Debug ceph-salt apply --non-interactive
	Debug ceph config set global public_network "$(ceph config get mon public_network)"

	echo ###########################################
	echo Access ceph dashboard at https://<mgr hostname or IP address>:8443
	echo ID : admin / PW : CHANGEME
	ceph mgr services | grep dashboard
	# if there are more than 62 OSDs. e.g. 96 OSDs on node
	#ceph config set osd.* ms_bind_port_max 7568
}

CephAdmCoreDeployment () {

	#Debug ceph orch status
	#Debug ceph orch device ls
	#Debug ceph orch ls
	# List daemon
	#Debug ceph orch ps


cat <<EOF > $froLOCAL_REPO_DIR/t_cluster.yml
service_type: mon
placement:
  hosts:
  - ${MON[0]}
  - ${MON[1]}
  - ${MON[2]}
# Mon or MGR not on same subnet
#  - ${MON[0]}:10.1.2.0/24
#  - ${MON[1]}:10.1.3.0/24
#  - ${MON[2]}:10.1.3.0/24
---
service_type: mgr
placement:
  hosts:
  - ${MON[0]}
  - ${MON[1]}
  - ${MON[2]}

EOF

Debug ceph orch apply -i $froLOCAL_REPO_DIR/t_cluster.yml


	## OSD
	#Debug echo Create encryped OSD in ceph-manager
	# all unused device
	Debug ceph orch apply osd --all-available-devices
	# For specific configuration see Book “Operations and Administration Guide”, Chapter 3 “Operational Tasks”, Section 3.4.3 “Adding OSDs using DriveGroups Specification”)
	#ceph orch apply osd -i drive_groups.yml

}

AddnodeInCephsalt () {

	Debug ceph-salt config /ceph_cluster/minions add $NEW.$DOMAIN
	Debug ceph-salt config /ceph_cluster/roles/cephadm add $NEW.$DOMAIN
	Debug ceph-salt config /ceph_cluster/roles/tuned/throughput add $NEW.$DOMAIN
	Debug ceph-salt config /ceph_cluster/minions ls
#	Debug ceph-salt apply $MGMT.$DOMAIN --non-interactive
	Debug ceph-salt apply $NEW.$DOMAIN --non-interactive
	Debug ceph orch host ls
}


RemoveOsd () {

	local OSD_ID=(3 7 11)
	for i in ${OSD_ID[@]};
	do
	Debug ceph orch osd rm $i;
	done
	Debug ceph orch osd rm status
	
	

}

RemoveOSDManual () {
	local OSD_ID=(3 7 11)
	local NODE="ses-4"
	for i in ${OSD_ID[@]};do
		ceph osd out osd.$i
		ceph osd crush remove osd.$i
		ceph auth del osd.$i
		ceph osd rm osd.$i
	done	

	for i in ${OSD_ID[@]};
	do
	Debug ceph orch daemon rm osd.$i --force;
	done

	#Debug ceph osd crush remove $NODE

}

RemoveNode () {

echo ""
## Remove OSD on the nodes first. using RemoveOsd function.

# Ceph orch removal
local NODE="ses-new"
Debug_print $'ceph orch ls --export > $froLOCAL_REPO_DIR/current_cluster.yml'
ceph orch ls --export > $froLOCAL_REPO_DIR/current_cluster.yml
Debug echo Remove the node, $NODE,  from the file $froLOCAL_REPO_DIR/current_cluster.yml
Debug ceph orch apply -i $froLOCAL_REPO_DIR/current_cluster.yml
Debug ceph orch host rm $NODE

## Ceph-salt removal
# Using ceph-salt sls file.
echo remove node, $NODE, from the file /srv/pillar/ceph-salt.sls
Debug_print $'sed -i "s/- $NODE.$DOMAIN/#- $NODE.$DOMAIN/g" /srv/pillar/ceph-salt.sls'
sed -i "s/- $NODE.$DOMAIN/#- $NODE.$DOMAIN/g" /srv/pillar/ceph-salt.sls
Debug ceph-salt config /ceph_cluster/minions remove $NODE.$DOMAIN
Debug salt-key -d $NODE.$DOMAIN

# Ceph salt removal by command
#Debug ceph-salt config /ceph_cluster/roles/tuned/throughput remove $NODE
#Debug ceph-salt config /ceph_cluster/roles/tuned/latency remove $NODE
#Debug ceph-salt config /ceph_cluster/roles/cephadm remove $NODE
#Debug ceph-salt config /ceph_cluster/roles/admin remove $NODE
#Debug ceph-salt config /ceph_cluster/roles/bootstrap $NODE
#Debug ceph-salt config /ceph_cluster/minions remove $NODE
#Debug salt-key -d $NODE.$DOMAIN

}

ReplaceOSD () {

	local OSD_ID=(3 7 11)
	for i in ${OSD_ID[@]};
	do
	# OSD is not permanently removed from the CRUSH hierarchy and is assigned a destroyed flag instead.
	# The destroyed flag is used to determined OSD IDs that will be reused during the next OSD deployment. 
	Debug ceph orch osd rm $i --replace;
	done
	Debug ceph orch osd rm status

}

ShutdownSES () {

	Debug ceph osd set noout
	FSID=$1
	## in the order of storage client, Gageways, Metadata, osd, mgr, mon
	Debug cm- systemctl stop ceph-$1@osd*
       	Debug cm- systemctl stop ceph-$1@mgr*
	Debug cm- systemctl stop ceph-$1@mon*
	Debug echo Now you can shutdown server.


}
StartupSES () {

	Debug ceph osd unset noout
}

CreateCephFS () {

local CEPHFS_NAME="myCephFS"
cat << EOF > $froLOCAL_REPO_DIR/mds.yml
service_type: mds
service_id: $CEPHFS_NAME
placement:
  hosts:
  - ${OSD[3]}
EOF

Debug ceph orch apply -i $froLOCAL_REPO_DIR/mds.yml

local CEPHFS_DATA='cephfs_data'
local CEPHFS_META='cephfs_meta'
Debug ceph osd pool create $CEPHFS_DATA 32 32 
Debug ceph osd pool create $CEPHFS_META 32 32 

Debug ceph fs new $CEPHFS_NAME $CEPHFS_META $CEPHFS_DATA

# Check status
Debug ceph fs ls
Debug ceph mds stat

}

CephFSManagement  () {


## Mount on client
#: '
local SUBDIR="subdir"
local CEPHKEY=$(ceph auth get-key client.admin)
Debug mkdir -p /mnt/cephfs
Debug mount -t ceph ${MON_IP[1]},${MON_IP[2]},${MON_IP[0]}:6789:/ /mnt/cephfs -o name=admin,secret=$CEPHKEY
#Debug mount -t ceph ${MON_IP[1]},${MON_IP[2]},${MON_IP[0]}:6789:/$SUBDIR /mnt/cephfs
#'

## Snapshot 
# Important : No snapshot in multiple file systems, no more than 400 snapshots in a filesystem.
# Create snapshot
: '
local CEPHFS_NAME="myCephFS"
Debug ceph fs set $CEPHFS_NAME allow_new_snaps true
local CEPHFS_MOUNT='/mnt/cephfs'
local SNAP_TARGET='snapshot_test'
local SNAP_NAME='snapshot1'
Debug cd $CEPHFS_MOUNT/$SNAP_TARGET/
Debug mkdir .snap/$SNAP_NAME
'

# Delete snapshot


}

## NFS 
GaneshaDeployment () {

local NFS_NAME="ganeshanfs"
local NFS_POOL="nfs" #NFS Ganesha configuraion object
cat << EOF > $froLOCAL_REPO_DIR/nfs.yml
service_type: nfs
service_id: $NFS_NAME
placement:
  hosts:
  - ${OSD[3]}
spec:
  pool: $NFS_POOL
#  namespace: $NFS_NAMESPACE
EOF

Debug ceph orch apply -i $froLOCAL_REPO_DIR/nfs.yml

}

CrushmapGet () {

Debug cd $froLOCAL_REPO_DIR;
Debug ceph osd getcrushmap -ocompiled-crushmap-filename
Debug crushtool -dcompiled-crushmap-filename -odecompiled-crushmap-filename

}

PoolRbdmanagement () {

## Pool creation
#Debug ceph osd pool create pool-general 128 128
: '
for i in iscsi nfs pool-on-specific-nodes pool2 poolsnaptest;do
Debug ceph osd pool set $i min_size 2
Debug ceph osd pool set $i size 2
done
'

## Pool delete
#: '
local DELPOOL=(pooltier poolec)
for i in ${DELPOOL[@]};
do
Debug ceph tell mon.* injectargs --mon-allow-pool-delete=true
Debug ceph osd pool delete $i $i --yes-i-really-really-mean-it
done
#'

## untier EC pool 
#ceph osd tier rm poolec pooltier
#osd tier rm poolec pooltier


## Pool management for RGW

# rgw size change
#for i in .rgw.root default.rgw.control default.rgw.log default.rgw.meta default.rgw.buckets.data default.rgw.buckets.index
#do
#       Debug ceph osd pool set \$i min_size 1;
#       Debug ceph osd pool set \$i size 2;
#done

# PG
#Debug ceph osd pool set default.rgw.buckets.index pg_num 32
#Debug ceph osd pool set default.rgw.buckets.index pgp_num 32
#Debug ceph osd pool set default.rgw.buckets.data pg_num 512
#Debug ceph osd pool set default.rgw.buckets.data pgp_num 512




## RBD Creation and map
#Debug rbd -p pool-test create testrbd --size 10240
#Debug rbd -p pool-test ls
#Debug rbd map pool-test/testrbd
#Debug rbd unmap pool-test/testrbd

}

RadosGWManagement () {

echo ;
local ADMIN="s3admin"
local HOSTNAME="ses1.sapdemo.lab"
## User creation
Debug radosgw-admin user create --uid=\$ADMIN  --display-name=\$ADMIN --system

## ceph dashboard setting
#local ACCESS_KEY2='Please input value from the command above'
#local SECRET_KEY2='Please input value from the command above'
Debug ceph dashboard set-rgw-api-access-key \$ACCESS_KEY2
Debug ceph dashboard set-rgw-api-secret-key \$SECRET_KEY2
Debug ceph dashboard set-rgw-api-host \$HOSTNAME
ceph dashboard set-rgw-api-port 7480


}

RadosManagement () {

: '
# Disable in-flight encryption
for i in ms_cluster_mode ms_service_mode ms_client_mode;
do
Debug ceph config set global $i  "crc secure"
done
'

# Get in-flight encryption ode
for i in ms_cluster_mode ms_service_mode ms_client_mode;
do
Debug ceph config get osd $i
Debug ceph config get mon $i
Debug ceph config get mgr $i
done

}

# GW node
SambaGWDeployment_1 () {

Debug zypper install samba-ceph samba-winbind
Debug mkdir -p /etc/ceph

}

# Admin node
SambaGWDeployment_2 () {

Debug_print $'ceph auth get-or-create client.samba.gw mon 'allow r' osd 'allow *' mds 'allow *' -o ceph.client.samba.gw.keyring'
ceph auth get-or-create client.samba.gw mon 'allow r' \
 osd 'allow *' mds 'allow *' -o ceph.client.samba.gw.keyring;
scp ceph.client.samba.gw.keyring ${SMB_IP[0]}:/etc/ceph/

}

# GW node
SambaGWDeployment_3 () {

Debug echo mount cephfs on /mnt/ceph
Debug chmod 600 /etc/ceph/ceph.client.samba.gw.keyring
Debug zypper in -y samba samba-ceph
Debug mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

# directory preparation
Debug mkdir -p /mnt/cephfs/smb_only
Debug chmod 777 /mnt/cephfs/smb_only

local SHARE_NAME="smbtest"
local SMBPATH="/mnt/cephfs/smb_only"
cat << EOF > /etc/samba/smb.conf
[global]
  netbios name = SAMBA-GW
  clustering = no
  idmap config * : backend = tdb2
  passdb backend = tdbsam
  # disable print server
  load printers = no
  smbd: backgroundqueue = no

[$SHARE_NAME]
  path = $SMBPATH
  vfs objects = ceph

  ceph: config_file = /etc/ceph/ceph.conf
  ceph: user_id = samba.gw
  read only = no
  oplocks = no
  kernel share modes = no

# a share using cephfs
[$SHARE_NAME]
  path = $SMBPATH
  # "vfs objects = ceph" and "ceph: config_file / user_id" are dropped
  read only = no
  oplocks = no
  kernel share modes = no

EOF

local USER="cchon" # This user should be an exisiting OS user.
Debug smbpasswd -a $USER



Debug systemctl restart smb.service
Debug systemctl restart nmb.service
Debug systemctl restart winbind.service

Debug systemctl enable smb.service
Debug systemctl enable nmb.service
Debug systemctl restart winbind.service

Debug testparm
Debug smbstatus


}

iSCSIGWdeployment () {

# This is the pool to save iscsi gw configuration
local SSPOOL="iscsi"
local SSRBD="iscsirbd"

Debug ceph osd pool create $SSPOOL 32 32
Debug ceph osd pool set $SSPOOL min_size 1
Debug ceph osd pool set $SSPOOL size 1

Debug rbd -p $SSPOOL create $SSRBD --size 10240

local EXAMPLE_ISCSI="iscsigw"
local EXAMPLE_USER="iscsiuser"
local EXAMPLE_PASSWORD="CHANGEME"

cat << EOF > $froLOCAL_REPO_DIR/iscsi.yml
service_type: iscsi
service_id: $EXAMPLE_ISCSI
placement:
  hosts:
  - ${ISCSI[1]}
  - ${ISCSI[0]}
spec:
  pool: $SSPOOL
  api_user: $EXAMPLE_USER
  api_password: $EXAMPLE_PASSWORD
 # trusted_ip_list: "192.168.37.60,192.168.37.61,192.168.37.62,192.168.37.63"
  trusted_ip_list: "${MON_IP[0]},${MON_IP[1]},${MON_IP[2]},${ISCSI_IP[0]},${ISCSI_IP[1]}"
EOF
Debug ceph orch apply -i $froLOCAL_REPO_DIR/iscsi.yml

}

# on iSCSIGW
iSCSITargetDeployment () {

echo "Do it through Cephmanager"
echo "Pool configured with rbd applicaiton will only be used for target"
: '
local DAEMONNAME=$(cephadm ls | grep -i scsigw | awk -F\" '/name/ {print $4}')
local SSRBD="scsirbd"
local SSPOOL="iscsi"
Debug echo Run the following command in one of iSCSI nodes

local SSTARGETNAME='iqn.2003-01.org.linux-iscsi'
local SSIDENTIFIER=$SSRBD
cat << EOF 

# cephadm enter --name $DAEMONNAME
# gwcli
# cd /iscsi-targets
# create $SSTARGETNAME:$SSIDENTIFIER

# cd $SSTARGETNAME:$SSIDENTIFIER/gateways
# create iscsi1 ${ISCSI_IP[0]}
# create iscsi2 ${ISCSI_IP[1]}

# cd /disks
# attach $SSPOOL/$SSRBD

# cd /iscsi-targets/$SSTARGETNAME:$SSIDENTIFIER/disks
# add $SSPOOL/$SSRBD

Disable Authentication
# cd /iscsi-targets/$SSTARGETNAME:$SSIDENTIFIER/hosts
# auth disable_acl

EOF
'


}

MonitoringStackDeployment () {
echo ""

Debug ceph mgr module enable prometheus
# if prometheus was deployed before the prometheus module enabled, run the command below.
#Debug ceph orch redeploy prometheus

cat << EOF > $froLOCAL_REPO_DIR/monitoring.yml
service_type: prometheus
placement:
  hosts:
  - $MGMT
---
service_type: node-exporter
placement:
  hosts:
  - $MGMT
  - ${OSD[0]}
  - ${OSD[1]}
  - ${OSD[2]}
  - ${OSD[3]}
---
service_type: alertmanager
placement:
  hosts:
  - $MGMT
---
service_type: grafana
placement:
  hosts:
  - $MGMT

EOF

Debug ceph orch apply -i $froLOCAL_REPO_DIR/monitoring.yml



}

RGWDeployment () {
echo "";

local REALM_NAME="rgwrealm"
local ZONE_NAME="rgwzone"

cat << EOF > $froLOCAL_REPO_DIR/rgw.yml
service_type: rgw
service_id: $REALM_NAME.${ZONE_NAME}t
placement:
  hosts:
  - ${RGW[0]}
spec:
  rgw_realm: $REALM_NAME
  rgw_zone: $ZONE_NAME
EOF

Debug ceph orch apply -i $froLOCAL_REPO_DIR/rgw.yml

}

cephtemp () {
echo ""


}

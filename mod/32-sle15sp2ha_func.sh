#!/bin/bash
## Func


iSCSIclientInitiator ()  {

Debug zypper in -y open-iscsi yast2-iscsi-client

sed  -i "s/^InitiatorName\b.*$/#/g" /etc/iscsi/initiatorname.iscsi
echo InitiatorName=iqn.1996-04.de.suse:01:$(hostname) >> /etc/iscsi/initiatorname.iscsi
echo initiator Name :
echo InitiatorName=iqn.1996-04.de.suse:01:$(hostname)


}

iSCSITarget () {

Debug dd if=/dev/zero of=/home/sbd/ha-sle15sp2.sbd bs=1M count=10
Debug echo "iSCSI target configuration in yast"
echo "Configure iSCSI client on each nodes"



}

ClusterRelatedNetworkDevice() {

Debug echo "add cluster network and interface on each nodes"
Debug echo "add DRBD device"


}

# on both node
HA_BootstrapClusterBoth() {

Debug zypper in -y -t pattern ha_sles

Debug_print $'echo softdog > /etc/modules-load.d/watchdog.conf'
echo softdog > /etc/modules-load.d/watchdog.conf
Debug systemctl restart systemd-modules-load

Debug ls -al /dev/disk/by-id
Debug echo "Update env file with SBD device id"

}

# on Primary
HA_BootstrapClusterPrimary() {

Debug ha-cluster-init --name $HA_NAME -u -y -s $HA_SBD -w softdog -i $HA_HEARTBEATINF --admin-ip $HA_VIP
Debug echo "hawk ID/PW : hacluster/linux"

}

# on second nodes
HA_addnodes () {

Debug echo "Run the command on all second hoces : ha-cluster-join -y -c  ${HA_HEARTBEATIP[0]} -i $HA_HEARTBEATINF"

}

#on primary
HA_createDRBD () {

cat << EOTT >/etc/drbd.d/nfs.res
resource nfs {
   device /dev/drbd0; 
   disk   /dev/vdb; 
   meta-disk internal; 

   net {
      protocol  C; 
   }

   connection-mesh { 
      hosts     ${OTHERS[0]} ${OTHERS[1]};
   }
   on ${OTHERS[0]} { 
      address   ${HA_HEARTBEATIP[0]}:7790;
      node-id   0;
   }
   on ${OTHERS[1]} { 
      address   ${HA_HEARTBEATIP[1]}:7790;
      node-id   1;
   }
}
EOTT

Debug drbdadm create-md nfs
Debug drbdadm up nfs
Debug zypper in -y nfs-kernel-server

}

HA_createDRBDPrimary () {

local RESULT=$(cat  /etc/csync2/csync2.cfg | grep res\;$)

if [[ $RESULT == "" ]]
then
sed -i "s/}/#}/g" /etc/csync2/csync2.cfg
cat << EOTT >> /etc/csync2/csync2.cfg
include /etc/drbd.conf;
include /etc/drbd.d/*.res;
}
EOTT
fi

Debug csync2 -xv

Debug drbdadm new-current-uuid --clear-bitmap nfs/0
Debug drbdadm primary --force nfs
Debug drbdadm status nfs
echo "sleep three seconds";sleep 3;

Debug mkfs.xfs /dev/drbd0
}

HA_pcmkConfig () {

cat << EOTT | tee /tmp/pcmk_rscdefault.txt
rsc_defaults resource-stickiness="200"
EOTT

Debug crm configure load update /tmp/pcmk_rscdefault.txt

cat << EOTT | tee /tmp/pcmk_drbd.txt
primitive drbd_nfs \
  ocf:linbit:drbd \
    params drbd_resource="nfs" \
  op monitor interval="15" role="Master" \
  op monitor interval="30" role="Slave"

ms ms-drbd_nfs drbd_nfs \
  meta master-max="1" master-node-max="1" clone-max="2" \
  clone-node-max="1" notify="true"

EOTT

Debug crm configure load update /tmp/pcmk_drbd.txt

cat << EOTT | tee /tmp/pcmk_nfsserver.txt
primitive nfsserver \
  systemd:nfs-server \
  op monitor interval="30s"
clone cl-nfsserver nfsserver \
   meta interleave=true
EOTT
Debug crm configure load update /tmp/pcmk_nfsserver.txt

mkdir -p /srv/nfs/work
cat << EOTT | tee /tmp/pcmk_filesystem.txt
primitive fs_work \
  ocf:heartbeat:Filesystem \
  params device=/dev/drbd0 \
    directory=/srv/nfs/work \
    fstype=xfs\
  op monitor interval="10s"
group g-nfs fs_work
order o-drbd_before_nfs Mandatory: \
  ms-drbd_nfs:promote g-nfs:start
colocation col-nfs_on_drbd Mandatory: \
  g-nfs ms-drbd_nfs:Master
EOTT

Debug crm configure load update /tmp/pcmk_filesystem.txt

cat << EOTT | tee /tmp/pcmk_export.txt
primitive exportfs_work \
  ocf:heartbeat:exportfs \
    params directory="/srv/nfs/work" \
      options="rw,mountpoint,insecure,no_subtree_check,no_root_quash" \
      clientspec="$HA_NFS_CLIENT" \
      wait_for_leasetime_on_stop=true \
      fsid=100 \
  op monitor interval="30s"

primitive vip_nfs IPaddr2 \
   params ip=$HA_NFS_IP cidr_netmask=24 \
   op monitor interval=10 timeout=20
group g-nfs fs_work exportfs_work vip_nfs
EOTT

Debug crm configure load update /tmp/pcmk_export.txt
}

Temp () {
echo ""


}


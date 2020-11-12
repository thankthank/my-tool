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
	for i in ${MON[@]};
	do
		
		Debug ceph-salt config /ceph_cluster/roles/tuned/latency add $i.$DOMAIN
		#Debug ceph-salt config /ceph_cluster/roles/tuned/throughput add $i.$DOMAIN
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
	Debug ceph-salt config /cephadm_bootstrap/ceph_conf/global set cluster_network 192.168.100.0/24
	# Configuration backup
	Debug ceph-salt status
	Debug_print $'ceph-salt export > $froLOCAL_REPO_DIR/cluster.json'
	ceph-salt export > $froLOCAL_REPO_DIR/cluster.json
	# import configuration
	#ceph-salt import $froLOCAL_REPO_DIR/cluster.json

	# Nodes update
	Debug_print run manually on admin node
	Debug_print ceph-salt update
	Debug_print ceph-salt update --reboot
	Debug_print ceph-salt reboot

	Debug ceph-salt apply --non-interactive
	Debug ceph config set global public_network "$(ceph config get mon public_network)"

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




}

cephtemp () {
	echo ""

	## OSD
	# all unused device
	Debug ceph orch apply osd --all-available-devices
	# For specific configuration see Book “Operations and Administration Guide”, Chapter 3 “Operational Tasks”, Section 3.4.3 “Adding OSDs using DriveGroups Specification”)
	#ceph orch apply osd -i drive_groups.yml

}

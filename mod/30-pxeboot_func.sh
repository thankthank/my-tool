#!/bin/bash


DhcpDeployment () {


	Debug zypper in -y -t pattern dhcp_dns_server

if [[ ! -a /etc/dhcpd.conf.bak ]]
then

	Debug cp /etc/dhcpd.conf /etc/dhcpd.conf.bak
fi

## next-server : the server with tftp service
cat << EOTT > /etc/dhcpd.conf
option domain-name "$DOMAIN";
option routers $GATEWAY;
option domain-name-servers $DNS_SERVER;
default-lease-time 14400;
ddns-update-style none;
subnet $DHCP_SUBNET netmask $DHCP_NETMASK {
  range $RANGE_START $RANGE_END;
  default-lease-time 14400;
  max-lease-time 172800;
  next-server $MGMT_IP;
  filename "pxelinux.0";
}
EOTT


if [[ ! -a /etc/sysconfig/dhcpd.bak ]]
then
	Debug cp /etc/sysconfig/dhcpd /etc/sysconfig/dhcpd.bak
fi

cat << EOTT > /etc/sysconfig/dhcpd

DHCPD_INTERFACE="$DHCP_INTERFACE"

DHCPD6_INTERFACE=""

DHCPD_IFUP_RESTART=""

DHCPD6_IFUP_RESTART=""

DHCPD_RUN_CHROOTED="yes"

DHCPD6_RUN_CHROOTED="yes"

DHCPD_CONF_INCLUDE_FILES="/etc/dhcpd.d"

DHCPD6_CONF_INCLUDE_FILES="/etc/dhcpd6.d"

DHCPD_RUN_AS="dhcpd"

DHCPD6_RUN_AS="dhcpd"

DHCPD_OTHER_ARGS=""

DHCPD6_OTHER_ARGS=""

EOTT

Debug systemctl restart dhcpd

}

PXEbootServer() {

echo ""

zypper in -y syslinux tftp

cat << EOTT
Configure by 'yast tftp-server'
	* Enable : (selected)
	* Boot image directory : /srv/tftpboot
EOTT
Debug echo "Cancel here if you didn't do yast for tftp-server"

mkdir -p  /srv/tftpboot/pxelinux.cfg
cp /usr/share/syslinux/{pxelinux.0,vesamenu.c32} /srv/tftpboot
cat << EOTT > /srv/tftpboot/pxelinux.cfg/default
default vesamenu.c32
prompt 0
timeout 50
menu title PXE Install Server
label harddisk
 menu label Local Hard Disk
 localboot 0
EOTT


}


InstallationSourceConfig() {

# tftp resource
Debug mkdir -p /srv/tftpboot/$IMAGE1_NAME
Debug mkdir -p /mnt/$IMAGE1_NAME
Debug mount $IMAGE1_LOCATION /mnt/$IMAGE1_NAME
Debug cp /mnt/$IMAGE1_NAME/boot/x86_64/loader/{initrd,linux} /srv/tftpboot/$IMAGE1_NAME

# installer
Debug zypper in -y vsftpd
Debug systemctl start vsftpd
Debug systemctl enable vsftpd
Debug mkdir -p /srv/ftp/install/$IMAGE1_NAME
Debug rsync -av /mnt/$IMAGE1_NAME/* /srv/ftp/install/$IMAGE1_NAME

# pxe configuration
cat << EOTT >> /srv/tftpboot/pxelinux.cfg/default
label $IMAGE1_NAME
 menu label Install $IMAGE1_NAME
 kernel $IMAGE1_NAME/linux
 append load ramdisk=1 initrd=$IMAGE1_NAME/initrd netsetup=dhcp hostname=pxeinstall install=ftp://$MGMT_IP/install/$IMAGE1_NAME
#label caaspnode
# menu label Install CAASP_NODE
# kernel caasp/linux
# append load ramdisk=1 initrd=caasp/initrd netsetup=dhcp hostname=caasp-admin autoyast=http://192.168.70.71/autoyast install=ftp://192.168.70.75/install/caasp3
EOTT

}


Temp () {

pwd > /dev/null


}

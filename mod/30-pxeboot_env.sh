#!/bin/bash

## DHCP netowrk configuration
DHCP_SUBNET="192.168.37.0"
DHCP_NETMASK="255.255.255.0"
RANGE_START="192.168.37.200"
RANGE_END="192.168.37.254"
DHCP_INTERFACE="eth0"

## Installation source
IMAGE1_NAME=sle15sp2
IMAGE1_LOCATION='/srv/images/SLE-15-SP2-Full-x86_64-GM-Media1.iso'

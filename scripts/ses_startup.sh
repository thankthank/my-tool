#!/bin/bash

echo "Start server in order : Admin, Monitor, OSD"
ceph osd unset noout
echo "Start additional component : Gateways and clients"

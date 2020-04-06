#!/bin/bash

virsh list --all | awk '{ if(/caasp/ && !/template/ && !/caasp-lb/) print "virsh undefine "$2 }' #| bash
find . -type f | awk '{if($1~/master/||$1~/worker/) print "rm -f "$0}'  # |bash

#!/bin/bash

systemctl list-unit-files| grep service | awk '{
print "echo --------------------------------------------------------------------"
print "echo --------------------------------------------------------------------"
print "echo Service name: "$1", State:  "$2
print "echo Packagename : "
print "rpm -qf /usr/lib/systemd/system/"$1
print "echo;echo;"
print "echo RPM_Information"
print "rpm -qi $(rpm -qf /usr/lib/systemd/system/"$1")"

}' | bash

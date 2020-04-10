#!/bin/bash
ceph osd set noout
salt-run disengage.safety
salt-run state.orch ceph.shutdown
salt '*' cmd.run "systemctl poweroff"

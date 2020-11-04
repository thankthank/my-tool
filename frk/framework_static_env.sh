#!/bin/bash
## Static famework values

## Values need to be set up depening on environment!!!!!
froTAR_DEPLOYED_DIR="/root" # The location where airgap.tar file extracted. #CHANGEME
froTAR_BALL_AIRGAPPED=("caasp4_200317.tar.gz" "sles15sp1_200317.tar") # Tar ball name #CHANGEME


##############################################3
## Default Configuration of framework variables. Modify this when you need to change Framework. 
freSCRIPT_NAME="cm-scp_products_deployment" # This script name
freUSER="root" # The user for this script to ssh nodes. It should be root or sudoer without password.
fre_MY_TOOL_INSTALLED_DIR="/usr/local/bin"
freSCP_RUN_Target_dir='/tmp'
# Framework Function variables
froLOCAL_REPO_DIR="$froTAR_DEPLOYED_DIR/local_repo" 
froPUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDe2C4oUonl0PG/b2ItS7dEe6SJYI/E8uj5lGZIpfjOgixbXwgbPRhoBvAibLsSuYxp2bBSLEcjQK35b4t9FVp+YArHDRFNvzxIaYuqbdvcSfjeW5/TMcJyhdeLEfYjctX+elmS9vkTNQ9Eis/cyKFtJ0ww63O+I5+7+hJzKVfd2Jr9QuJf7Sv9XF/CpbfvpP4geC6RfUEaYKmP/YyUZ4+RKpWiycNmjV0G8X/82FFuF4JK0wWst3BiZYxczJBnl2S7dP5X+0gqP5IMMwZrcj/hZ4hXldDG6m1HWrB0UvWExY8/DuhWmYbBdvnhLFJmKqRTplJEKDzPoaDKwJ/8pzC5 root@linux-pf5u'


#!/bin/bash

TempSshPublicKeyForDeployment () {

# SSH key setting
mkdir -p ~/.ssh;chmod 700 ~/.ssh;
echo "$froPUBLIC_KEY" >> ~/.ssh/authorized_keys;

chmod 644 ~/.ssh/authorized_keys


}

TempSshPrivateKeyForDeployment () {

# SSH key setting
mkdir -p ~/.ssh;chmod 700 ~/.ssh;
cp $froLOCAL_REPO_DIR/keys/id_rsa.pub ~/.ssh/id_rsa.pub;
cp $froLOCAL_REPO_DIR/keys/id_rsa ~/.ssh/id_rsa;
echo "$froPUBLIC_KEY" >> ~/.ssh/authorized_keys;

chmod 644 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

}


TarBallDecompress  () {

	local TAR_BALLS=( caasp.tar.gz sle15sp1.tar  )

	# Untar the tarball
	for i in ${TAR_BALLS[@]};do
		echo $i;echo $i
		FILE_EXTENSION=${i##*.}
		if [[ $FILE_EXTENSION == "tar" ]];then tar xvf $i -C $froTAR_DEPLOYED_DIR/
		else tar xvfz $i -C $froTAR_DEPLOYED_DIR/
		fi
		# Delete the tar ball to save space
#		rm -f $i
	done;


}





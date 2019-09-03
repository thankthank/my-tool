#!/bin/bash

osc checkout home:cchon my-tool
VER_MAJOR=$(ls home:cchon/my-tool | grep tar.gz | awk -F\- '{print $3}' | awk -F. '{print $1}')
CUR_VER_MINOR=$(ls home:cchon/my-tool | grep tar.gz | awk -F\- '{print $3}' | awk -F. '{print $2}')
(( NXT_VER_MINOR=CUR_VER_MINOR + 1 ))
VERSION=${VER_MAJOR}.${NXT_VER_MINOR}
VERSION_CUR=${VER_MAJOR}.${CUR_VER_MINOR}

rm -rf home:cchon

cd ..
#current directory : {parent directory of local git repo}

mv my-tool my-tool-${VERSION}
tar cvfz my-tool-${VERSION}.tar.gz my-tool-${VERSION}
mv my-tool-${VERSION}.tar.gz my-tool-$VERSION/

cd my-tool-${VERSION}
#current directory : {parent directory..}/my-tool-${VERSION}

osc checkout home:cchon my-tool

cd home\:cchon/my-tool/
#current directory :  {parent directory of local git repo}/my-tool-${VERSION}/home:cchon/my-tool

##package setup process
osc delete my-tool*.tar.gz

cp ../../my-tool-${VERSION}.tar.gz .
sed -i "s/Version: ${VERSION_CUR}/Version: ${VERSION}/g" my-tool.spec

osc vc

osc add *.tar.gz

osc commit

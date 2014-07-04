#!/bin/sh

# Author: eyujche
# Date: 2013-11-05
# Description: This script used for ONV package installation


if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <package location>, such as ./installonv_ci.sh /tmp/onvpackage/"
  exit 1
fi

if [ -s /opt/ericsson/onv/server/bin/onv.sh  ]
then
   flag=`su - nmsadm -c '/opt/ericsson/onv/server/bin/onv.sh stop'`
   if [ $? -eq 0 ]
   then
      CIHome=`staf local var get system var Onv.Installation.CIGITHome |grep -v Response |grep -v '^-'`
      uninstall_loc=$CIHome/script/
      cd $uninstall_loc
      ./uninstallonv_ci.sh
   fi
fi

packageName=`staf local var get system var ONV.Common.packageName |grep -v Response |grep -v '^-'`

cd $1

if [ -f $1/$packageName.gz ]
then
   gzip -d $packageName.gz

   if [ $? -eq 0 ]
   then
     tar xvf $packageName
   
     if [ $? -eq 0 ]
     then
       ./install.sh -a -s
     else
       exit 1
     fi
   else
     exit 1
   fi
else
   echo "$1/$packageName.gz" does not exist
   exit 1
fi

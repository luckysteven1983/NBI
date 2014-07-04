#!/bin/sh
# Author: eyujche
# Date:   2013-11-15
# Description: This script used for NBI package, testdata/script/config collection


if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <CI config file>"
  exit 1
fi

if [ -f $1 ]
then
  ID=`grep \^ID $1 |awk -F\= '{print $2}'`

else
  echo "CI configuration file $1 not exist, script exit...."
  exit 1
fi

param=$ID."DataCollection.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script-master/common/common.fun

BaseLine=`getSTAFVariableValue $ID "Common.Baseline" "local"`
packageName=`getSTAFVariableValue $ID "Common.packageName" "local"`
dependOnPackage=`staf local var list |grep $ID.Common.dependonpackage|awk -F\: '{print $2}'`


NEFILE=`getSTAFVariableValue $ID "DataCollection.NEInfoFile" "local"`
CMCCGITHome=`getSTAFVariableValue $ID "DataCollection.CMCCGITHome" "local"`
packageInfo=`getSTAFVariableValue $ID "DataCollection.PackageLoc" "local"`
targetLoc=`getSTAFVariableValue $ID "DataCollection.TargetDir" "local"`
dependOnPackageLoc=`getSTAFVariableValue $ID "DataCollection.dependOnPackageLoc" "local"`
copyDependsPackageFlag=`getSTAFVariableValue $ID "DataCollection.copyDependsPackageFlag" "local"`
remoteIP=`getSTAFVariableValue $ID "DataCollection.RemoteIP" "local"`

target_package_dir=$targetLoc/packages/
target_package_depend_on_dir=$targetLoc/packages/depend_on
target_script_dir=$targetLoc/script/
target_config_dir=$targetLoc/config/
target_testdata_dir=$targetLoc/testdata/


if [ -d $targetLoc ]
then
   echo "Target directory $targetLoc directory exist, remove it then create a new one ..."
   rm -rf $targetLoc
fi

mkdir -p $target_package_dir
mkdir -p $target_script_dir
mkdir -p $target_config_dir
mkdir -p $target_testdata_dir   
mkdir -p $target_package_depend_on_dir


packageLoc=`cat $packageInfo`

echo "\ncopying nbi package $packageName to $target_package_dir ..."
cp $packageLoc/$packageName $target_package_dir

if [ $? -eq 0 ]
then
  echo "copy CMCC NBI package $packageName done\n"
else
  echo "copy CMCC NBI package $packageName failed\n"
  exit 1
fi

if [ "$copyDependsPackageFlag" = "true" ]
then
echo "\ncopying depend on packages $dependOnPackage to $target_package_depend_on_dir ..."
cp $dependOnPackageLoc/* $target_package_depend_on_dir
  if [ $? -eq 0 ]
  then
    echo "copy depend on packages done\n"
  else
    echo "copy depend on packages failed\n"
    exit 1
  fi

fi

APPDBNAME=`getSTAFVariableValue $ID "DataCollection.APPDBNAME" "local"`
APPDBUSER=`getSTAFVariableValue $ID "DataCollection.APPDBUSER" "local"`
APPDBPASSWD=`getSTAFVariableValue $ID "DataCollection.APPDBPASSWD" "local"`
ReadyRetention=`getSTAFVariableValue $ID "DataCollection.ReadyRetention" "local"`
APPDBSAPASSWD=`getSTAFVariableValue $ID "DataCollection.APPDBSAPASSWD" "local"`

configFile=$target_config_dir/varConfig.data

if [ -f $configFile ]
then
   rm $configFile
fi

echo "APPDBNAME=$APPDBNAME" >>$configFile
echo "APPDBUSER=$APPDBUSER" >>$configFile
echo "APPDBPASSWD=$APPDBPASSWD" >>$configFile
echo "ReadyRetention=$ReadyRetention" >>$configFile
echo "APPDBSAPASSWD=$APPDBSAPASSWD" >>$configFile


echo "copying config to $target_config_dir ..."
cp -rf $CIGITHome/config/CMCC/* $target_config_dir
cp $CIGITHome/config/sentinal-license/Perm_$remoteIP $target_config_dir

if [ $? -eq 0 ]
then
  echo "copy config files to $target_config_dir done\n"
else
  echo "copy config files failed\n"
  exit 1
fi

echo "copying script files to $target_script_dir ..."
cp $CIGITHome/script/CMCC/* $target_script_dir
if [ $? -eq 0 ]
then
  cp $CIGITHome/script-master/common/common.fun $target_script_dir
  echo "copy script to $target_script_dir done\n"
else
  echo "copy script failed\n"
  exit 1
fi

echo "start CMCC GIT Data collection ..."
Collect_script=$CMCCGITHome/TestScript/FUNENV-SETUP/data_collection.sh

if [ ! -s $Collect_script ]
then
  echo -e "ERROR : Can not find script $Collect_script !\n"
  exit 1
else
  cd $CMCCGITHome/TestScript/FUNENV-SETUP/
  sh $Collect_script $CMCCGITHome $CIGITHome/$NEFILE $targetLoc $BaseLine >>/dev/null 2>&1
  echo "data collection done under $targetLoc"
fi
  

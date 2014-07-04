#!/bin/sh
# Author: eyujche
# Date:   2013-11-05
# Description: This script used for package and testdata/script/config collection

param="ONV.DataCollection.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script-master/common/commonV1.fun

NEFILE=`getSTAFVariableValue "ONV.DataCollection.NEInfoFile" "local"`
BaseLine=`getSTAFVariableValue "ONV.Common.Baseline" "local"`

packageName=`getSTAFVariableValue "ONV.Common.packageName" "local"`
packageName=$packageName.gz

ONVGITHome=`getSTAFVariableValue "ONV.DataCollection.ONVGITHome" "local"`
packageInfo=`getSTAFVariableValue "ONV.DataCollection.PackageLoc" "local"`
targetLoc=`getSTAFVariableValue "ONV.DataCollection.TargetDir" "local"`


target_package_dir=$targetLoc/package/
target_script_dir=$targetLoc/script/
target_config_dir=$targetLoc/config/
target_testdata_dir=$targetLoc/testdata/


if [ ! -d $targetLoc ]
then
   echo "$targetLoc directory does not exist, create it ..."
   mkdir -p $target_package_dir
   mkdir -p $target_script_dir
   mkdir -p $target_config_dir
   mkdir -p $target_testdata_dir   
  
fi

packageLoc=`cat $packageInfo`

echo "\ncopying onv package to $target_package_dir ..."
cp $packageLoc/$packageName $target_package_dir

if [ $? -eq 0 ]
then
  echo "copy onv package done\n"
else
  echo "copy onv package failed\n"
  exit 1
fi

echo "copying script to $target_script_dir ..."
cp $CIGITHome/config/ONV/* $target_config_dir
if [ $? -eq 0 ]
then
  echo "copy script to $target_script_dir done\n"
else
  echo "copy onv package failed\n"
  exit 1
fi

echo "copying config files to $target_config_dir ..."
cp $CIGITHome/script/ONV/* $target_script_dir

if [ $? -eq 0 ]
then
  cp $CIGITHome/script-master/common/commonV1.fun $target_script_dir
  echo "copy script to $target_config_dir done\n"
else
  echo "copy script failed\n"
  exit 1
fi

echo "start cm data collection ..."
CM_Collection=$ONVGITHome/TestScript/ENV_SETUP/cmdata_collection.sh

if [ ! -s $CM_Collection ]
then
  echo -e "ERROR : Can not find cm_data generation script $CM_Collection !\n"
  exit 1
else
  bash $CM_Collection $ONVGITHome $CIGITHome/$NEFILE $targetLoc >>/dev/null 2>&1
  echo "cm data collection done under $target_testdata_dir"
fi


echo "\nstart KPI north file collection ..."
PM_Collection=$ONVGITHome/TestScript/ENV_SETUP/pm_north_file_collection.sh

if [ ! -s $PM_Collection ]
then
  echo -e "ERROR : Can not find pm north file collection script $PM_Collection !\n"
  exit 1
else
  bash $PM_Collection $ONVGITHome $CIGITHome/$NEFILE $targetLoc $BaseLine >>/dev/null 2>&1
  echo "KPI north file collection done under $target_testdata_dir$BaseLine"

  echo "\nData Collection finished, package and testa data copy to $targetLoc, please check"
fi

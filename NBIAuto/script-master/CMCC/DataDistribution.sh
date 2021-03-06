#!/bin/sh
# Author: eyujche
# Date:   2013-11-05
# Description: This script used for package and testdata/script/config distribution to remote test machie
#              Also give the execute permission to script changemode.sh which will be invoked by install-commisson step


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

SourceLoc=`getSTAFVariableValue $ID "DataCollection.TargetDir" "local"`
remoteIP=`getSTAFVariableValue $ID "DataCollection.RemoteIP" "local"`
RemoteLoc=`getSTAFVariableValue $ID "Installation.CIHome" $remoteIP`


staf $remoteIP FS list DIRECTORY $RemoteLoc > /dev/null

if [ $? -eq 0 ]
then 
  echo "delete remote location $RemoteLoc on test machine $remoteIP"
  result=`staf $remoteIP FS DELETE ENTRY $RemoteLoc RECURSE CONFIRM`
  
  if [ $? -eq 0 ]
  then
     echo "delete remote location $RemoteLoc done\n"
  else
     echo "delete remote location $RemoteLoc failed, please check staf status\n"
     exit 1
  fi

fi
echo "\ncopying nbi package, testdata, script and config files to remote test machine $remoteIP ..."

result1=`staf local FS COPY DIRECTORY $SourceLoc TODIRECTORY $RemoteLoc TOMACHINE $remoteIP RECURSE KEEPEMPTYDIRECTORIES`

if [ $? -eq 0 ]
then
   echo "copy nbi package, testdata, script and config files done\n"
else
   echo "copy nbi package, testdata, script and config files failed, please check staf status\n"
   exit 1
fi

scriptLoc=$RemoteLoc/script
result2=`staf $remoteIP process START shell COMMAND chmod +x $scriptLoc/changemode.sh`

if [ $? -eq 0 ]
then
   echo "Remote script $scriptLoc/changemode.sh execution permission granted"
   echo "\nDataDistribution Finished"
   exit 0
else
   echo "Give script $scriptLoc/changemode.sh execution permission failed, please check staf status\n"
   exit 1
fi

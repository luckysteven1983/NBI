#!/bin/sh
# Author: eyujche
# Date: 2013-12-03
# Description: This script used for CMCC CI test report generation

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


remoteIP=`getSTAFVariableValue $ID "DataCollection.RemoteIP" "local"`
pkgname=`getSTAFVariableValue $ID "TestCase.buildversionPkgName" $remoteIP"`
genReportScript=`getSTAFVariableValue $ID "TestReport.genReportScript" $remoteIP`
remoteCIHome=`getSTAFVariableValue $ID "Installation.CIHome" $remoteIP`
genReportScript=$remoteCIHome/$genReportScript

staf $remoteIP process start shell command $genReportScript PARMS \'$ID\' 

#staf 10.185.3.9 process start shell command 'pkginfo -l ERICnbiXcmcss-R13B-EC01 | grep PSTAMP ' RETURNSTDOUT RETURNSTDERR wait |grep PSTAMP |awk -F\: '{print $3}'

buildInfo=`staf $remoteIP process start shell command "pkginfo -l $pkgname|grep PSTAMP"  wait RETURNSTDOUT RETURNSTDERR |grep PSTAMP |awk -F\: '{print \$3}'`

sleep 3

FinalResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" $remoteIP`


ReportFile=`staf $remoteIP FS list directory $FinalResultLoc |grep Report|grep $buildInfo` 
ReportFile=$FinalResultLoc/$ReportFile

staf $remoteIP FS query entry  $ReportFile >/dev/null
if [ $? -eq 0 ]
then
  staf $remoteIP FS get file $ReportFile 
else
  echo "REPORT START"
  echo "Do not find the report file :("
  echo "REPORT END"
fi





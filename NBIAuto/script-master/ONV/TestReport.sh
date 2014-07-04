#!/bin/sh
# Author: eyujche
# Date: 2013-11-08
# Description: This script used for test report shown on the GUI


param="ONV.DataCollection.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script-master/common/common.fun


remoteIP=`getSTAFVariableValue "ONV.DataCollection.RemoteIP" "local"`

FinalResultFile=`getSTAFVariableValue "ONV.TestReport.FinalResult" $remoteIP`
baseline=`getSTAFVariableValue "ONV.Common.Baseline" "local"`

FinalResultFile=$FinalResultFile.$baseline

staf $remoteIP FS get file $FinalResultFile





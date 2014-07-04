#!/bin/sh

if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <ID>"
  exit 1
fi

ID=$1

param=$ID."Installation.CIHome"
CIHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIHome/script/common.fun


CommissionScript=`getSTAFVariableValue $ID "Installation.CommissionScript" "local"`
InstallScript=`getSTAFVariableValue $ID "Installation.InstallScript" "local"`
CommissionPrepareScript=`getSTAFVariableValue $ID "Installation.CommissionPrepareScript" "local"`
StartCMSyncScript=`getSTAFVariableValue $ID "Installation.StartCMSyncScript" "local"`

StopScript=`getSTAFVariableValue $ID "Installation.StopScript" "local"`

genCMCompareScript=`getSTAFVariableValue $ID "TestCase.genCMCompareScript" "local"`
genPMCompareScript=`getSTAFVariableValue $ID "TestCase.genPMCompareScript" "local"`

genReportScript=`getSTAFVariableValue $ID "TestReport.genReportScript" "local"`

checkAllModulesStatusScript=`getSTAFVariableValue $ID "TestCase.checkAllModulesStatusScript" "local"`

chmod +x $CIHome/$CommissionScript
chmod +x $CIHome/$CommissionPrepareScript
chmod +x $CIHome/$InstallScript
chmod +x $CIHome/$StartCMSyncScript
chmod +x $CIHome/$genCMCompareScript
chmod +x $CIHome/$genPMCompareScript
chmod +x $CIHome/$genReportScript
chmod +x $CIHome/$StopScript
chmod +x $CIHome/$checkAllModulesStatusScript

chown -R nbi:nbi $CIHome


#!/bin/sh
# Author: eyujche
# Date: 2013-11-05
# Description: This script used for script execution permission change which invoked by remote master server used in CI system

param="ONV.Installation.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script/commonV1.fun


commissionscript=`getSTAFVariableValue "ONV.Installation.CommissionScript" "local"`
installscript=`getSTAFVariableValue "ONV.Installation.InstallScript" "local"`
kpihandlejobgenscript=`getSTAFVariableValue "ONV.Installation.KPIHandleJobGenScript" "local"`
uninstallscript=`getSTAFVariableValue "ONV.Installation.UninstallScript" "local"`
kpihandlescript=`getSTAFVariableValue "ONV.TestCase.KPICompareScript" "local"`


chmod +x $CIGITHome/$commissionscript

chmod +x $CIGITHome/$installscript

chmod +x $CIGITHome/$kpihandlejobgenscript

chmod +x $CIGITHome/$uninstallscript

chmod +x $CIGITHome/$kpihandlescript

chmod +x $CIGITHome/script/cli.sh


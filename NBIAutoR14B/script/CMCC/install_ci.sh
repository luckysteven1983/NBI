#!/bin/sh
# Author: eyujche
# Date: 2013-11-15
# Description: This script used for CMCC container installation


startSybase()
{

if [ -f /opt/sybase/start.log ]
then
   rm /opt/sybase/start.log
fi
su - sybase -c "/opt/sybase/ASE-15_0/install/startserver -f RUN_NBI" |tee /opt/sybase/start.log

while [ ! `grep 'witching to blocking mode' /opt/sybase/start.log` ]
do
   sleep 10
done

}


writeMsg()
{
msg=$1
logFile=$2

timestamp=`date '+%Y/%m/%d %H:%M:%S'`

echo "$timestamp\t$msg" >>$logFile 

}

if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <ID>"
  exit 1
fi

ID=$1

param=$ID."Installation.CIHome"
CIHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIHome/script/common.fun

chmod 777 /opt/nbi/DataFile

packageName=`getSTAFVariableValue $ID "Common.packageName" "local"`
packageLoc=$CIHome/packages/

upgradeFrom=`getSTAFVariableValue $ID "Installation.upgradeFrom" "local"`
dependOnPackage=`staf local var list |grep -i Common.dependonpackage|awk -F\: '{print $2}'`

firstpackage=`echo $dependOnPackage |awk '{print $1}'`

FinalResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" "local"`
mkdir -p $FinalResultLoc
logFile=$FinalResultLoc/install.log
rm $logFile >/dev/null 2>&1


configFile=$CIHome/config/varConfig.data

if [ -f /var/opt/ericsson/NBI/SWInventory/Container.current.data ]
then

    currentRelease=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep ContainerInstance |awk -F\= '{print $2}'`
    InstallStatus=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep InstallStatus |awk -F\= '{print $2}'`
 
    if [ "$InstallStatus" != "Installed" ]
    then
       writeMsg "NBI server status is abnormal, installation can't performed." $logFile
       writeMsg "Installation Failed." $logFile
       exit 1
    else
       writeMsg "Current SW level is $currentRelease" $logFile 
       case $currentRelease in
       $packageName)
            writeMsg "Uninstall $packageName firstly, then install the latest package again" $logFile
            writeMsg "Execute command /opt/IS/IS.sh --rollback $upgradeFrom --silent --file $configFile" $logFile
            mv /opt/IS/log/IS_log.log /opt/IS/log/IS_log.log.before.rollbackto.$upgradeFrom
            /opt/IS/IS.sh --rollback $upgradeFrom --silent --file $configFile > /dev/null 2>&1
            grep "Removal of  $packageName was successful" /opt/IS/log/IS_log.log >/dev/null 
            if [ $? -eq 0 ]
            then
              checkStatus=true
              writeMsg "Uninstall $packageName successfully" $logFile
            else
              writeMsg "Rollback $packageName failed, please check IS log for details." $logFile
              writeMsg "Installation Failed." $logFile
              exit 1
            fi
            ;;
       $upgradeFrom)
            checkStatus=true
            ;;
       *)
            writeMsg "Server status not meet installation requirment, uninstall all packages firstly " $logFile
            writeMsg "Execute command /opt/IS/IS.sh --rollback all --silent --file $configFile" $logFile
            mv /opt/IS/log/IS_log.log /opt/IS/log/IS_log.log.before.rollbackto.empty
            /opt/IS/IS.sh --rollback all --silent --file $configFile > /dev/null 2>&1
            grep "Removal of  $firstpackage was successful" /opt/IS/log/IS_log.log >/dev/null 
            if [ $? -eq 0 ]
            then
              writeMsg "Uninstall all packages successfully" $logFile
              checkStatus=true
            else
              writeMsg "Rollback all packages failed, please check IS log for details." $logFile
              writeMsg "Installation Failed." $logFile
              exit 1
            fi
            
            #startSybase
            
            targetContainer=$upgradeFrom
            repositoryLocation=$CIHome"/packages/depend_on"
            checkStatus=false              
       ;;
       
       esac
       
    fi

else
    targetContainer=$upgradeFrom
    repositoryLocation=$CIHome"/packages/depend_on"
    checkStatus=false
fi


if [ "$checkStatus" = "false" ]
then
   writeMsg "It will cost a lot of time to install $dependOnPackage on this sever, please wait ..." $logFile
   writeMsg "Execute command /opt/IS/IS.sh --install --device $repositoryLocation $targetContainer --silent --file $configFile" $logFile
   mv /opt/IS/log/IS_log.log /opt/IS/log/IS_log.log.before.upgradeto.$targetContainer
   /opt/IS/IS.sh --install --device $repositoryLocation $targetContainer --silent --file $configFile > /dev/null 2>&1
   
   Release=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep ContainerInstance |awk -F\= '{print $2}'`
   Status=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep InstallStatus |awk -F\= '{print $2}'`
   
   if [ "$Release" = "$targetContainer" ] && [ "$Status" = "Installed" ];
   then
     checkStatus=true
     writeMsg "Install depend on packages $dependOnPackage successfully" $logFile
   else
     writeMsg "Install depend on packages $dependOnPackage failed, please check IS log for details." $logFile
     writeMsg "Installation Failed." $logFile
     exit 1
   fi
fi

if [ "$checkStatus" = "true" ]
then
   writeMsg "Start to install the latest $packageName." $logFile
   writeMsg "Execute command /opt/IS/IS.sh --install --device $packageLoc $packageName --silent --file $configFile" $logFile
   mv /opt/IS/log/IS_log.log /opt/IS/log/IS_log.log.before.upgradeto.$packageName
   /opt/IS/IS.sh --install --device $packageLoc $packageName --silent --file $configFile > /dev/null 2>&1
 
   Release=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep ContainerInstance |awk -F\= '{print $2}'`
   Status=`cat /var/opt/ericsson/NBI/SWInventory/Container.current.data |grep InstallStatus |awk -F\= '{print $2}'`
   
   if [ "$Release" = "$packageName" ] && [ "$Status" = "Installed" ];
   then
     writeMsg "Install $packageName successfully." $logFile
   else
     writeMsg "Install $packageName failed, please check IS log for details." $logFile
     writeMsg "Installation Failed." $logFile
     exit 1
   fi
fi

grep staf /opt/nbi/.cshrc
if [ $? != 0 ]
then

  basedir=/opt


  echo "#####################set staf env##########################" >> /opt/nbi/.cshrc
  echo setenv CLASSPATH \${CLASSPATH}:$basedir/staf/lib/JSTAF.jar:$basedir/staf/lib/STAFHTTPSLS.jar >>/opt/nbi/.cshrc
  echo setenv PATH \${PATH}:$basedir/staf/bin >>/opt/nbi/.cshrc
  echo setenv LD_LIBRARY_PATH \${LD_LIBRARY_PATH}:$basedir/staf/lib >>/opt/nbi/.cshrc
  echo setenv STAFCONVDIR $basedir/staf/codepage >>/opt/nbi/.cshrc
  
fi
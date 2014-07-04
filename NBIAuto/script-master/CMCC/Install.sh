#!/bin/sh
# Author: eyujche
# Date: 2013-11-15
# Description: This script used for CMCC NBI package installation and commission, it invoke a stax xml and tracking the progress

checkInstallStatus()
{
step=$1
flag=$2
logname=$3
if [ $flag = "Start" ]
then  
    flag=false
    while [ $flag = "false" ]
    do 
      if [ -f tmp.log ]
      then
         rm tmp.log
      fi
      staf local log query machine $machineName logname $logname |grep Step >tmp.log
      result=`cat tmp.log | grep $step |grep Start`
      if [ $? -ne 0 ]
      then
        sleep 5
      else
        flag="true"
        return 0
      fi
    done
else
    flag=false
    while [ $flag = "false" ]
    do 
      if [ -f tmp.log ]
      then
         rm tmp.log
      fi
      staf local log query machine $machineName logname $logname |grep Step >tmp.log    
      result=`cat tmp.log | egrep "Finished|Failed" | grep $step`
      if [ $? -ne 0 ]
      then 
        sleep 5
      else
        flag="true"
      fi
    done
    
    echo $result | grep Failed
    
    if [ $? -eq 0 ]
    then
       rm tmp.log
       return 1
    else
       rm tmp.log
       return 0
    fi
fi    

}


msgbox()
{
step=$1
message=$2

case $step in
Step1)
   output="Installation Preparation"
   ;;
Step2)
   output="Stop NBI Services"
   ;;
Step3)
   output="Installation"
   ;;
Step4)
   output="Commission Preparation"
   ;;
Step5)
   output="Commission"
   ;;
Step6)
   output="Start CMMapping"
   ;;
Step7)
   output="Start All NBI Module"
   ;;   
  
esac

echo "$1 $output $2"
return 0

}


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

machineName=`staf local var get system var STAF/Config/MachineNickname|grep -v Response|grep -v '^-'`

scriptName=$CIGITHome/script-master/CMCC/Install_Commission.xml

userlogName=$ID"_InstallationLog"

STAFResult=`staf local log query machine $machineName logname $userlogName`

if [ $? -eq 0 ]
then
   STAFResult=`staf local log delete machine $machineName logname $userlogName confirm`
   echo "delete user log $userlogName successfully\n"
else
   echo "user log $userlogName not exist, will write installation informtion into it\n"
fi

#staf local stax execute file /home/eyujche/script/STAX/example.xml ARGS "{'ID':'CMCC1'}"

echo staf local stax execute file $scriptName ARGS \"{\'ID\':\'$ID\'}\"

STAFResult=`staf local stax execute file $scriptName ARGS \"{\'ID\':\'$ID\'}\"`

if [ $? -eq 0 ]
then
   for N in 1 2 3 4 5 6 7
   do
      if checkInstallStatus Step$N "Start" $userlogName; then
         msgbox Step$N "Start"
         if checkInstallStatus Step$N "Finished" $userlogName; then
            msgbox Step$N "Finished"
         else 
            msgbox Step$N "Failed"
            exit 1
         fi
      fi
   done
else
  echo "stax script $scriptName invoking faile, please check staf status"
  exit 1
fi



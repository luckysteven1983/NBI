#!/bin/sh
# Author: eyujche
# Date: 2013-11-06
# Description: This script used for KPI test case execution, it invoke a stax xml and tracking the progress

checkStatus()
{
step=$1
flag=$2

if [ $flag = "Start" ]
then  
    flag=false
    while [ $flag = "false" ]
    do 
      if [ -f tmp.log ]
      then
         rm tmp.log
      fi
      staf local log query machine $machineName logname TestCaseLog |grep Step >tmp.log
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
      staf local log query machine $machineName logname TestCaseLog |grep Step >tmp.log    
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
   output="KPI Test Case Execution"
   ;;
Step2)
   output="TBD"
   ;;

esac

echo "$1 $output $2"
return 0

}



param="ONV.DataCollection.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script-master/common/commonV1.fun

machineName=`getSTAFVariableValue "STAF/Config/MachineNickname" "local"`

scriptName=$CIGITHome/script-master/ONV/TestCase_KPI.xml

STAFResult=`staf local log query machine $machineName logname TestCaseLog `

if [ $? -eq 0 ]
then
   STAFResult=`staf local log delete machine $machineName logname TestCaseLog confirm`
   echo "delete user log TestCaseLog successfully\n"
else
   echo "user log TestCaseLog not exist\n"
fi

STAFResult=`staf local stax execute file $scriptName`

if [ $? -eq 0 ]
then
   for N in 1
   do
      if checkStatus Step$N "Start"; then
         msgbox Step$N "Start"
         if checkStatus Step$N "Finished"; then
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



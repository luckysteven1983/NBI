#!/bin/sh

writeMsg()
{
msg=$1
logFile=$2

timestamp=`date '+%Y/%m/%d %H:%M:%S'`

echo "$timestamp $msg" >>$logFile 

}


checkCMSyncStatus()
{

timeout=$1
key=$2

    costtime=0
    flag=false
    while [ $flag = "false" ]
    do 
      result=`grep "$key" /opt/nbi/log/CMMapping.log `
      if [ $? -ne 0 ] && [ $costtime -lt $timeout ];
      then
        sleep 5
        costtime=`expr $costtime + 5 `
      elif [ $costtime -ge $timeout ]
      then
        flag=true
        return 1
      else
        flag=true
        sleep 20
        return 0
      fi
    done

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

FinalResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" "local"`
logFile=$FinalResultLoc/cmsync.log

logLTEINVFile=$FinalResultLoc/LTEINVsync.log
logCOREINVFile=$FinalResultLoc/COREINVsync.log
logFULLAMOSFile=$FinalResultLoc/FULLAMOSsync.log
logENODEBWPFile=$FinalResultLoc/ENODEBWPsync.log
rm $logLTEINVFile >/dev/null 2>&1
rm $logCOREINVFile >/dev/null 2>&1
rm $logFULLAMOSFile >/dev/null 2>&1
rm $logENODEBWPFile >/dev/null 2>&1

rm $logFile >/dev/null 2>&1

rm /opt/nbi/log/CMMapping.log

writeMsg "CM sync with flow=LTEINV Start" $logFile
#/opt/nbi/bin/CMMapping -f LTEINV >>/dev/null
/opt/nbi/bin/CMMapping -f LTEINV -n >> $logLTEINVFile

checkCMSyncStatus 1200 "ACTIVITY END InvSync-EndAct"

if [ $? -ne 0 ]
then
   writeMsg "CM sync with flow=LTEINV Failed" $logFile
   exit 1
else
   writeMsg "CM sync with flow=LTEINV Successfully" $logFile
fi

mv /opt/nbi/log/CMMapping.log /opt/nbi/log/CMMapping.log.lteinv


writeMsg "CM sync with flow=COREINV Start" $logFile
#/opt/nbi/bin/CMMapping -f COREINV >>/dev/null
/opt/nbi/bin/CMMapping -f COREINV -n >> $logCOREINVFile

checkCMSyncStatus 3000 "ACTIVITY END InvSync-EndAct"

if [ $? -ne 0 ]
then
   writeMsg "CM sync with flow=COREINV Failed" $logFile
   exit 1
else
   writeMsg "CM sync with flow=COREINV Successfully" $logFile
fi


mv /opt/nbi/log/CMMapping.log /opt/nbi/log/CMMapping.log.coreinv

writeMsg "CM sync with flow=FULL_AMOS Start" $logFile

#/opt/nbi/bin/CMMapping -f FULL_AMOS >>/dev/null
/opt/nbi/bin/CMMapping -f FULL_AMOS -n >> $logFULLAMOSFile

checkCMSyncStatus 7800 "TRACE0:STEP END MIB-SwitchAct"

if [ $? -ne 0 ]
then
   writeMsg "CM sync with flow=FULL_AMOS Failed" $logFile
   mv /opt/nbi/log/CMMapping.log /opt/nbi/log/CMMapping.log.full_amos
   exit 1
else
   writeMsg "CM sync with flow=FULL_AMOS Successfully" $logFile
fi

mv /opt/nbi/log/CMMapping.log /opt/nbi/log/CMMapping.log.fullamos
writeMsg "CM sync with flow=ENODEB_WP Start" $logFile

#/opt/nbi/bin/CMMapping -w >>/dev/null
/opt/nbi/bin/CMMapping -w -n >> $logENODEBWPFile

checkCMSyncStatus 1800 "ACTIVITY END Sync-EndAct"

if [ $? -ne 0 ]
then
   writeMsg "CM sync with flow=ENODEB_WP Failed" $logFile
   mv /opt/nbi/log/CMMapping.log /opt/nbi/log/CMMapping.log.WP
   exit 1
else
   writeMsg "CM sync with flow=ENODEB_WP Successfully" $logFile
fi

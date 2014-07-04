#!/bin/sh 
# Author: eyujche
# Date: 2013-12-05
# Discription: This script used for CI test report generation, including install, CM sync and CM/PM comparation result

if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <ID>"
  exit 1
fi

ID=$1

param=$ID."Installation.CIHome"
CIHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIHome/script/common.fun


writeGeneralInfo()
{
ID=$1
reportFile=$2
buildVersion=$3
packageName=$4


baseline=`getSTAFVariableValue $ID "Common.BaseLine" "local"`

NEInfoFile=`getSTAFVariableValue $ID "Installation.NEInfoFile" "local"`
NEInfoFile=$CIHome/$NEInfoFile

HostName=`staf local var list|grep STAF/Config/MachineNickname |awk -F\: '{print $2}'`
if [ -z "$HostName" ]
then
  echo "staf not running, please check"
  exit 1
else
  IPAddress=`ping -a $HostName |awk -F\( '{print $2}' |awk -F\) '{print $1}' |head -1`
fi

echo "REPORT START" >> $reportFile
echo "1. General Info" >> $reportFile
echo "   Server  : $IPAddress" >> $reportFile
echo "   Package : $packageName" >> $reportFile
echo "   Build   : $buildVersion" >> $reportFile
echo "   BaseLine: $baseline" >> $reportFile
echo "   NE List : " >> $reportFile
echo "             NEName\tNEType\tNEVersion" >>$reportFile
   while read LINE
   do
       if [ "`echo $LINE |grep "#"`" = "" ]
       then
          NEName=`echo $LINE |awk -F\, '{print $1}'`
          NEType=`echo $LINE |awk -F\, '{print $2}'`
          NEVersion=`echo $LINE |awk -F\, '{print $3}'`
          echo "             $NEName\t$NEType\t$NEVersion" >>$reportFile
       fi
   done < $NEInfoFile
   
echo "\n" >> $reportFile
}

writeInstallInfo()
{
installLog=$1
packageName=$2
reportFile=$3

echo "2. Installation" >> $reportFile

if [ -f $installLog ]
then
   grep "Installation Failed" $installLog
   if [ $? -eq 0 ]
   then
      echo "   Install $packageName Failed, check $installLog and IS log for details"  >> $reportFile 
      exit 1
   else
      echo "   Install $packageName successfully" >> $reportFile 
   fi
else
   echo $installLog not exist
fi
echo "\n" >> $reportFile
}


writeCMSyncInfo()
{
cmsyncLog=$1
reportFile=$2

echo "3. CM Sync" >> $reportFile

if [ -f $cmsyncLog ]
then
   LTEINVResult=`grep "Failed" $cmsyncLog |grep LTEINV`
   if [ $? -eq 0 ]
   then
      echo "   CM Sync with flow=LTEINV Failed, check $cmsyncLog and CMMapping.log for details"  >> $reportFile 
      exit 1
   else
      echo "   `grep 'LTEINV Successfully' $cmsyncLog`" >> $reportFile 
   fi
   
   LTEFULLAMOS=`grep "Failed" $cmsyncLog |grep LTEFUL_AMOS`
   if [ $? -eq 0 ]
   then
      echo "   CM Sync with flow=LTEFUL_AMOS Failed, check $cmsyncLog and CMMapping.log for details"  >> $reportFile 
      exit 1
   else
      echo "   `grep 'LTEFUL_AMOS Successfully' $cmsyncLog `" >> $reportFile
   fi
else
   echo $cmsyncLog not exist
fi
   echo "\n" >> $reportFile
}


writeCMCompareResult()
{
reportFile=$1
DetailsLoc=$2

echo "4. CM Comparation Result" >> $reportFile
printf "%30s %10s    %-30s\n" "Type" "Result" "Details" >> $reportFile

for MOC in AntennaFunction EnbFunction EpRpDynS1uEnb EpRpStaS1MmeEnb EthernetPort EutranCellTdd EutranRelationTdd GsmRelation InventoryUnitAccessory InventoryUnitPack InventoryUnitRack InventoryUnitRru InventoryUnitShelf ManagedElement SctpAssoc UtranRelationTdd GGSN SGW PGW SGSN MME PCRF
do
  exceptionFile=$MOC.exception.log
  if [ ! -f $DetailsLoc/$exceptionFile ]
  then
     printf "%30s %10s    %-30s\n"  $MOC "Failed" "North-File-not-generated" >> $reportFile
  else
     egrep "Failed|Missing" $DetailsLoc/$exceptionFile  >/dev/null 2>&1
     if [ $? -eq 0 ]
     then
        printf "%30s %10s    %-30s\n" $MOC "Failed" $DetailsLoc/$exceptionFile >> $reportFile
     else
        printf "%30s %10s %30s\n" $MOC "Passed" "" >> $reportFile
     fi 
  fi

done

echo "\n" >> $reportFile

}

writePMCompareResult()
{
reportFile=$1
DetailsLoc=$2

echo "5. PM Comparation Result" >> $reportFile
printf "%30s %10s    %-30s\n" "Type" "Result" "Details" >> $reportFile

for MOC in EpRpDynS1uEnb EthernetPort EutranCellTdd EutranRelationTdd ManagedElement SctpAssoc GGSN SGW PGW SGSN MME PCRF
do
  failFlag="false"
  for min in 00 15 30 45
  do
     exceptionFile=$MOC.$min.exception.log
     if [ ! -f $DetailsLoc/$exceptionFile ]
     then
        failFlag="true"
        failMsg="North-file-of-ROP-$min-not-generated"
        break
     else
        egrep "Failed|Missing" $DetailsLoc/$exceptionFile >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
           failFlag="true"
           failMsg=$DetailsLoc/$MOC.$min.exception.log
           break
        else
           failFlag="false"
        fi 
     fi
  done
  
  if [ "$failFlag" = "true" ]
  then
      printf "%30s %10s    %-30s\n"  $MOC "Failed" $failMsg >> $reportFile
  else
      printf "%30s %10s %30s\n" $MOC "Passed" "" >> $reportFile
  fi
done

echo "\n" >> $reportFile

}

getBuildVersionPkg=`getSTAFVariableValue $ID "TestCase.buildversionPkgName" "local"`
buildVersion=`pkginfo -l $getBuildVersionPkg | grep PSTAMP |awk -F\: '{print $2}'`
buildVersion=`echo $buildVersion`
packageName=`getSTAFVariableValue $ID "Common.packageName" "local"`

FinalResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" "local"`
FinalReport=$FinalResultLoc/$buildVersion"_Report.log"

rm $FinalReport >/dev/null 3>&1

writeGeneralInfo $ID $FinalReport $buildVersion $packageName

InstallationLog=$FinalResultLoc/install.log
writeInstallInfo $InstallationLog $packageName $FinalReport

if [ $? -ne 0 ]
then
   exit 1
fi

CMSyncLog=$FinalResultLoc/cmsync.log
writeCMSyncInfo $CMSyncLog $FinalReport

if [ $? -ne 0 ]
then
   exit 1
fi

CMCompareDetailsLoc=$FinalResultLoc/$buildVersion/CM
writeCMCompareResult $FinalReport $CMCompareDetailsLoc

PMCompareDetailsLoc=$FinalResultLoc/$buildVersion/PM
writePMCompareResult $FinalReport $PMCompareDetailsLoc

echo "REPORT END" >> $reportFile

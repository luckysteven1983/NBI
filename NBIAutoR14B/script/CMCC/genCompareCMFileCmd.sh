#!/bin/sh
# Author: eyujche
# Date: 2013-12-03
# Description: This script used for north CM North file comparation


if [ $# -ne 1 ]
then
  echo "Input parameter needed, usage $0 <ID>"
  exit 1
fi

ID=$1

param=$ID."Installation.CIHome"
CIHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIHome/script/common.fun

NorthFileLoc=`getSTAFVariableValue $ID "TestCase.NorthFileLoc" "local"`
getBuildVersionPkg=`getSTAFVariableValue $ID "TestCase.buildversionPkgName" "local"`
baseline=`getSTAFVariableValue $ID "Common.BaseLine" "local"`

buildVersion=`pkginfo -l $getBuildVersionPkg | grep PSTAMP |awk -F\: '{print $2}'`

buildVersion=`echo $buildVersion`

CMComparePerlScript=`getSTAFVariableValue $ID "TestCase.CMComparePerlScript" "local"`
CMComparePerlScript=$CIHome/$CMComparePerlScript

CompareResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" "local"`
CompareDetailFile=$CompareResultLoc/$buildVersion/CM_CompareDetails.log
CompareResultLoc=$CompareResultLoc/$buildVersion/CM
mkdir -p $CompareResultLoc

myTimeStamp=`/opt/sybase/OCS-15_0/bin/isql -Unbi -Pnbi1234 -SNBI << EOF | awk '!/affected/ && !/-/ && NF > 0 {print $1" "$2}'
select top 1 convert(char(10),endTime,111)+' '+convert(char(10),endTime,108) from CM_syncFlowStatus where flow='FULL_AMOS' and flag=0 order by endTime desc
go
EOF`


cmfileDay=`echo $myTimeStamp |awk '{print $1}' | awk -F\/ '{print $1$2$3}'`
cmfileMinutes=`echo $myTimeStamp |awk '{print $2}' | awk -F\: '{print $1$2}'`
cmfileTimestamp=$cmfileDay"-"$cmfileMinutes


CMNorthFileLocation=$NorthFileLoc/$buildVersion/CM
CMNorthFileLocation_base=$CIHome/testdata/NorthFile/$baseline/CM
gzip -d $CMNorthFileLocation_base/*.gz
rm $CMNorthFileLocation_base/*.gz


if [ ! -d $CMNorthFileLocation ]
then
   mkdir -p $CMNorthFileLocation
else
   rm $CMNorthFileLocation/*
fi
 
for NETYPE in AntennaFunction EnbFunction EpRpDynS1uEnb EpRpStaS1MmeEnb EthernetPort EutranCellTdd EutranRelationTdd GsmRelation InventoryUnitAccessory InventoryUnitPack InventoryUnitRack InventoryUnitRru InventoryUnitShelf ManagedElement SctpAssoc UtranRelationTdd  GGSN SGW PGW SGSN MME PCRF HLR HSS
do
   echo "\n---------------------------------------------------------" >> $CompareDetailFile
   echo "TestCase: TYPE $NETYPE comparation" >> $CompareDetailFile
   
   
        case $NETYPE in
        SGSN)
            cmfileName="CMCC-"$NETYPE"-NRM-V4.0.2-"$cmfileTimestamp.xml.gz
            ;;
        GGSN|HLR)
            cmfileName="CMCC-"$NETYPE"-NRM-V4.0.1-"$cmfileTimestamp.xml.gz
            ;;
        MME)
            cmfileName="CMCC-"$NETYPE"-NRM-V1.2.0-"$cmfileTimestamp.xml.gz
            ;;
        SGW)
            cmfileName="CMCC-"$NETYPE"-NRM-V1.3.0-"$cmfileTimestamp.xml.gz
            ;;
        PGW|PCRF)
            cmfileName="CMCC-"$NETYPE"-NRM-V1.3.1-"$cmfileTimestamp.xml.gz
            ;;
        HSS)
            cmfileName="CMCC-"$NETYPE"-NRM-V2.1.0-"$cmfileTimestamp.xml.gz
            ;;
        *)
            cmfileName="CMCC-ENB-NRM-V2.3.0-"$NETYPE"-"$cmfileTimestamp.xml.gz
            ;;
        esac
   
   if [ -f /opt/nbi/DataFile/Exported/CM/$cmfileName ]
   then
     cp /opt/nbi/DataFile/Exported/CM/$cmfileName $CMNorthFileLocation
     gzip -d $CMNorthFileLocation/$cmfileName
   
     baseFile=`ls $CMNorthFileLocation_base |grep $NETYPE`
     newFile=`ls $CMNorthFileLocation |grep $NETYPE|grep -v gz`
     
     baseFile=$CMNorthFileLocation_base/$baseFile
     echo "baseFile=$baseFile" >> $CompareDetailFile
     
     newFile=$CMNorthFileLocation/$newFile
     echo "newFile=$newFile" >> $CompareDetailFile

     CompareDetail=$CompareResultLoc/$NETYPE.detail.xml
     echo "CompareDetail=$CompareDetail" >> $CompareDetailFile
     
     ResultFile=$CompareResultLoc/$NETYPE.exception.log
     echo "CompareResult=$ResultFile" >> $CompareDetailFile

     echo "CMD = perl $CMComparePerlScript BaseCMNorthFile=$baseFile NewCMNorthFile=$newFile ResultFile=$CompareDetail ResultSummaryFile=$ResultFile" >> $CompareDetailFile
     perl $CMComparePerlScript BaseCMNorthFile=$baseFile NewCMNorthFile=$newFile ResultFile=$CompareDetail ResultSummaryFile=$ResultFile
     
     egrep "Failed|Missing" $ResultFile >/dev/null
             
     if [ $? -eq 0 ]
     then
        echo "TestCaseResult=Failed" >> $CompareDetailFile
     else
        echo "TestCaseResult=Passed" >> $CompareDetailFile
     fi

   else
     echo "TestCaseResult=Failed" >> $CompareDetailFile
     echo "Reason=/opt/nbi/DataFile/Exported/CM/$cmfileName not exist" >> $CompareDetailFile
   fi
done


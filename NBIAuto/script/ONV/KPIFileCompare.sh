#!/bin/sh
#Author: eyujche
#Date: 2013-11-05
#Description: This script used for the generation of compare command and invoke the compare command for KPI handle north file comparation


param="ONV.Installation.CIGITHome"
CIGITHome=`staf local var get system var "$param" |grep -v Response |grep -v '^-'`
. $CIGITHome/script/commonV1.fun


NEINFOFile=`getSTAFVariableValue "ONV.TestCase.NEINFOFile" "local"`
NEINFO=$CIGITHome/$NEINFOFile

BaseLine=`getSTAFVariableValue "ONV.Common.Baseline" "local"`
BaseFileLoc=$CIGITHome/testdata/$BaseLine

onvVersion=`onv version | grep Release |awk '{print $2}'`

KPICompareScript=`getSTAFVariableValue "Onv.TestCase.KPIComparePerlScript" "local"`
KPICompareScript=$CIGITHome/$KPICompareScript

KPIFilescopy2Loc=`getSTAFVariableValue "Onv.TestCase.KPIGenNorthFileLoc" "local"`
KPIFilescopy2Loc=$KPIFilescopy2Loc/$onvVersion

FinalResultFile=`getSTAFVariableValue "Onv.TestReport.FinalResult" "local"`
FinalResultFile=$FinalResultFile.$BaseLine

if [ ! -d $KPIFilescopy2Loc ]
then
   mkdir -p $KPIFilescopy2Loc
fi 
   
KPICompareDetailFile=`getSTAFVariableValue "Onv.TestCase.KPICompareDetailLoc" "local"`
KPICompareDetailFileLoc=$KPICompareDetailFile/$BaseLine-$onvVersion
KPICompareDetailFileLoc1=$KPICompareDetailFile/$onvVersion-$BaseLine

if [ ! -d $KPICompareDetailFileLoc ]
then
   mkdir -p $KPICompareDetailFileLoc
   mkdir -p $KPICompareDetailFileLoc1
fi 
   
KPICompareSummaryFile=`getSTAFVariableValue "Onv.TestReport.KPICompareSummaryLoc" "local"`
KPICompareSummaryFileLoc=$KPICompareSummaryFile/$BaseLine-$onvVersion
KPICompareSummaryFileLoc1=$KPICompareSummaryFile/$onvVersion-$BaseLine


if [ ! -d $KPICompareSummaryFileLoc ]
then
   mkdir -p $KPICompareSummaryFileLoc
   mkdir -p $KPICompareSummaryFileLoc1
fi 

 if [ -f $CIGITHome/script/$onvVersion-$BaseLine.sh ]
 then
    rm $CIGITHome/script/$onvVersion-$BaseLine.sh
    rm $CIGITHome/script/$BaseLine-$onvVersion.sh
 fi
 if [ -s $NEINFO ]
 then

    while read LINE
    do
        
        if [ "`echo $LINE |grep "#"`" = "" ]
        then
         #echo $LINE
         NEName=`echo $LINE |awk -F\, '{print $1}'`
         NEType=`echo $LINE |awk -F\, '{print $2}'`
         NEVersion=`echo $LINE |awk -F\, '{print $3}'`
         SubNetwork=`echo $LINE |awk -F\, '{print $5}'`
         
         if [ "$NEType" = "EPG" -a "$NEVersion" = "12A" ] || [ "$NEType" = "SGSNMME" -a "$NEVersion" = "13A" ];
         then
            echo $NEName
            KPIOutputFilesLoc=/var/opt/ericsson/sgw/outputfiles/onv/$NEName
            if [ ! -d $KPIOutputFilesLoc ]
            then
               continue
            fi
            for GP in 00 15 30 45
            do
               newFile=`ls /var/opt/ericsson/sgw/outputfiles/onv/$NEName |grep $GP.xml |head -1`
               echo newFile=$newFile
               if [ -f /var/opt/ericsson/sgw/outputfiles/onv/$NEName/$newFile ]
               then
                 cp /var/opt/ericsson/sgw/outputfiles/onv/$NEName/$newFile $KPIFilescopy2Loc
                 baseFile=`ls $BaseFileLoc |grep $NEName |grep $GP.xml |head -1`
                 if [ -f $BaseFileLoc/$baseFile ]
                 then
                 echo baseFile=$baseFile
                 echo "perl $KPICompareScript BaseNFIFile=$BaseFileLoc/$baseFile NewNFIFile=$KPIFilescopy2Loc/$newFile ResultFile=$KPICompareDetailFileLoc/$NEName.xml.$GP ResultSummaryFile=$KPICompareSummaryFileLoc/$NEName.result_$GP" >> $CIGITHome/script/$BaseLine-$onvVersion.sh
                 echo "\n" >> $CIGITHome/script/$BaseLine-$onvVersion.sh
                 echo "cat $KPICompareSummaryFileLoc/$NEName.result_$GP >> $FinalResultFile "  >>$CIGITHome/script/$BaseLine-$onvVersion.sh
                 #echo "perl $KPICompareScript BaseNFIFile=$KPIFilescopy2Loc/$newFile NewNFIFile=$BaseFileLoc/$baseFile ResultFile=$KPICompareDetailFileLoc1/$NEName.xml.$GP ResultSummaryFile=$KPICompareSummaryFileLoc1/$NEName.result_$GP" >> $CIGITHome/script/$onvVersion-$BaseLine.sh
                 #echo "\n" >> $CIGITHome/script/$onvVersion-$BaseLine.sh
                 fi
               fi
            done
         fi
        fi
         
    done < $NEINFO
 fi
 
#sh $CIGITHome/script/$onvVersion-$BaseLine.sh
sh $CIGITHome/script/$BaseLine-$onvVersion.sh

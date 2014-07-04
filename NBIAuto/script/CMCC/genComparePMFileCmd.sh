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

NorthFileLoc=`getSTAFVariableValue $ID "TestCase.NorthFileLoc" "local"`
baseline=`getSTAFVariableValue $ID "Common.BaseLine" "local"`
getBuildVersionPkg=`getSTAFVariableValue $ID "TestCase.buildversionPkgName" "local"`
buildVersion=`pkginfo -l $getBuildVersionPkg | grep PSTAMP |awk -F\: '{print $2}'`
buildVersion=`echo $buildVersion`

PMComparePerlScript=`getSTAFVariableValue $ID "TestCase.PMComparePerlScript" "local"`
PMComparePerlScript=$CIHome/$PMComparePerlScript

CompareResultLoc=`getSTAFVariableValue $ID "TestReport.FinalResultLoc" "local"`
CompareDetailFile=$CompareResultLoc/$buildVersion/PM_CompareDetails.log
CompareResultLoc=$CompareResultLoc/$buildVersion/PM
mkdir -p $CompareResultLoc


PMNorthFileLocation=$NorthFileLoc/$buildVersion/PM
PMNorthFileLocation_base=$CIHome/testdata/NorthFile/$baseline/PM
gzip -d $CIHome/testdata/NorthFile/$baseline/PM/*.gz >>/dev/null
rm $CIHome/testdata/NorthFile/$baseline/PM/*.gz

if [ ! -d $PMNorthFileLocation ]
then
   mkdir -p $PMNorthFileLocation
else
   rm $PMNorthFileLocation/* 
fi

perl $CIHome/script/getPMFileTimestamp.pl $CIHome/script/pm_time_list

     
for NETYPE in EpRpDynS1uEnb EthernetPort EutranCellTdd EutranRelationTdd ManagedElement SctpAssoc GGSN SGW PGW SGSN MME PCRF
do
      echo "\n---------------------------------------------------------" >> $CompareDetailFile
      echo "TestCase: TYPE $NETYPE comparation" >> $CompareDetailFile
    
      while read LINE
      do
        pmfileTimestamp=`echo $LINE |awk '{print $1}'`
        mymin=`echo $LINE |awk '{print $2}'`
        pmfile_day=`echo $LINE |awk '{print $1}' |awk -F\- '{print $1}'`
        
        case $NETYPE in
        SGSN|GGSN)
            pmfileName="CMCC-"$NETYPE"-PM-V4.0.2-"$pmfileTimestamp.xml.gz
            ;;
        PGW|SGW|PCRF|MME)
            pmfileName="CMCC-"$NETYPE"-PM-V1.2.0-"$pmfileTimestamp.xml.gz
            ;;
        *)
            pmfileName="CMCC-ENB-PM-V2.1.0-"$NETYPE"-"$pmfileTimestamp.xml.gz
            ;;
        esac
        
        if [ -f /opt/nbi/DataFile/Generated/PM/NFI.bak/$pmfile_day/$pmfileName ]
        then
             cp /opt/nbi/DataFile/Generated/PM/NFI.bak/$pmfile_day/$pmfileName $PMNorthFileLocation
             gzip -d $PMNorthFileLocation/$pmfileName  
            
             baseFile=`ls $PMNorthFileLocation_base |grep $NETYPE | grep $mymin.xml |grep -v gz`
             newFile=`ls $PMNorthFileLocation |grep $NETYPE | grep $mymin.xml |grep -v gz`
    
             baseFile=$PMNorthFileLocation_base/$baseFile
             echo "baseFile=$baseFile" >> $CompareDetailFile
        
             newFile=$PMNorthFileLocation/$newFile
             echo "newFile=$newFile" >> $CompareDetailFile
   
             CompareDetail=$CompareResultLoc/$NETYPE.$mymin.detail.xml
             echo "CompareDetail=$CompareDetail" >> $CompareDetailFile
        
             ResultFile=$CompareResultLoc/$NETYPE.$mymin.exception.log
             echo "CompareResult=$ResultFile" >> $CompareDetailFile
       
             echo "CMD = perl $PMComparePerlScript BaseNFIFile=$baseFile NewNFIFile=$newFile ResultFile=$CompareDetail ResultSummaryFile=$ResultFile" >> $CompareDetailFile
             perl $PMComparePerlScript BaseNFIFile=$baseFile NewNFIFile=$newFile ResultFile=$CompareDetail ResultSummaryFile=$ResultFile
             
             egrep "Failed|Missing" $ResultFile >/dev/null
             
             if [ $? -eq 0 ]
             then
                 echo "TestCaseResult=Failed" >> $CompareDetailFile
             else
                 echo "TestCaseResult=Passed" >> $CompareDetailFile
             fi
           
        else
        
             echo "TestCaseResult=Failed" >> $CompareDetailFile
             echo "Reason=/opt/nbi/DataFile/Generated/PM/NFI.bak/$pmfile_day/$pmfileName not exist" >> $CompareDetailFile
        fi
        
      done  < $CIHome/script/pm_time_list  
      
done


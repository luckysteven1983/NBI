#!/bin/sh
# Description: This script used for CMCC NBI server commission, including the steps below
# 1) System.xml generation
# 2) ossrc.xml generation
# 3) db.properties generation
# 4) Invoke nedisover.sh for collector_ENODEB.xml collector_EE.xml generation, also insert record into ne_version_info
# 5) config crontab for PM raw file generation, EE pm raw file generation
# 6) add a new variable CIHome to /opt/nbi/.cshrc
# 7) update CMPMInterWork.xml file, use a fixed bulk file as input
# 8) invoke td-cm.sh for CMDef_Sync_Flow.xml generation, some template replaced to copy local file instead of get bulk, HW, arne, amos file from OSSRC
# 9) Copy NBI license file
# 10) change PMMappingnum to 10 for function test
# 11) insert ne_verion_info record

writeMsg()
{
msg=$1
logFile=$2

timestamp=`date '+%Y/%m/%d %H:%M:%S'`

echo "$timestamp $msg" >>$logFile 

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
logFile=$FinalResultLoc/commission.log
rm $logFile >/dev/null 2>&1

NEInfoFile=`getSTAFVariableValue $ID "Installation.NEInfoFile" "local"`

HostName=`staf local var list|grep STAF/Config/MachineNickname |awk -F\: '{print $2}'`

if [ -z "$HostName" ]
then
  echo "staf not running, please check"
  exit 1
else
  IPAddress=`ping -a $HostName |awk -F\( '{print $2}' |awk -F\) '{print $1}' |head -1`
fi

cp $CIHome/config/Perm_$IPAddress /opt/nbi/License/lservrc

passwd=`getSTAFVariableValue $ID "Installation.NBIServerPasswd" "local"`

encryptPasswd=`/opt/nbi/Utilities/crypttool -e $passwd |awk -F\: '{print $2}'`

if [ -f /opt/nbi/config/System.xml ]
then
    mv /opt/nbi/config/System.xml /opt/nbi/config/System.xml.bk
    writeMsg "old System.xml mv to System.xml.bk" $logFile
fi

sed "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$IPAddress/g" /opt/nbi/config/System_template.xml |sed 's/<PMMappingNum>60</<PMMappingNum>10</g' > /opt/nbi/config/System.xml
writeMsg "System.xml generated" $logFile


if [ -f /opt/nbi/config/ossrc.xml ]
then
    mv /opt/nbi/config/ossrc.xml /opt/nbi/config/ossrc.xml.bk
    writeMsg "old ossrc.xml mv to ossrc.xml.bk" $logFile
fi

writeMsg "copy ossrc_template.xml to ossrc.xml and replace IPaddress to $IPAddress, user and password to nbi" $logFile
username=`grep '<ossuser>' /opt/nbi/config/ossrc_template.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
osspasswd=`grep '<osspasswd>' /opt/nbi/config/ossrc_template.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
eepasswd=`grep '<eepasswd>' /opt/nbi/config/ossrc_template.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
sed "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$IPAddress/g" /opt/nbi/config/ossrc_template.xml |sed "s/$username/nbi/g"  |sed "s/<osspasswd>$osspasswd/<osspasswd>$encryptPasswd/g" |sed "s/<eepasswd>$eepasswd/<eepasswd>$encryptPasswd/g" >/opt/nbi/config/ossrc.xml
writeMsg "ossrc.xml generated" $logFile


writeMsg "Replace the IPaddress to $IPAddress in db.properties, old file mv to bk" $logFile
IP_old=`grep 'db.url' /opt/nbi/config/NFI/db.properties |awk -F\: '{print $4}'`

sed "s/$IP_old/$IPAddress/g" /opt/nbi/config/NFI/db.properties > /opt/nbi/config/NFI/db.properties.tmp
cp /opt/nbi/config/NFI/db.properties /opt/nbi/config/NFI/db.properties.bk
mv /opt/nbi/config/NFI/db.properties.tmp /opt/nbi/config/NFI/db.properties

writeMsg "db.properties IP replace done" $logFile

writeMsg "delete collector_ENODEB.xml and collector_EE.xml firstly, then invoke nediscover.sh to generated a new one" $logFile
rm /opt/nbi/config/collector_ENODEB.xml >/dev/null 2>&1
rm /opt/nbi/config/collector_EE.xml >/dev/null 2>&1

/opt/nbi/Utilities/CLI/nediscover/script/nediscover.sh -t ENODEB -f $CIHome/testdata/arne.xml -o -s

sed "s/\/var\//\/opt\/nbi\/DataFile\/var\//g" /opt/nbi/config/collector_ENODEB.xml > /opt/nbi/config/collector_ENODEB.xml.new
mv /opt/nbi/config/collector_ENODEB.xml.new /opt/nbi/config/collector_ENODEB.xml

sed "s/\/eniq\//\/opt\/nbi\/DataFile\/eniq\//g" /opt/nbi/config/collector_EE.xml > /opt/nbi/config/collector_EE.xml.new
mv /opt/nbi/config/collector_EE.xml.new /opt/nbi/config/collector_EE.xml

writeMsg "collector_ENODEB.xml and collector_EE.xml generated" $logFile

writeMsg "mv ossrc.xml to ossrc.xml.CI and copy ossrc_template.xml to ossrc.xml, PMFileCollector limitation" $logFile
mv /opt/nbi/config/ossrc.xml /opt/nbi/config/ossrc.xml.CI
cp /opt/nbi/config/ossrc_template.xml /opt/nbi/config/ossrc.xml

----------------------------------------------------------
writeMsg "insert record into ne_version_info start" $logFile

/opt/sybase/OCS-15_0/bin/isql -Unbi -Pnbi1234 -SNBI -i $CIHome/config/insert_ne_version_info.sql

writeMsg "insert record into ne_version_info done" $logFile

--------------------------------------------------------------
writeMsg "create crontab of nbi user to simulate PM raw file and EE raw file" $logFile

sh $CIHome/script/EEPMRawFileSimulator/genEERawFileSimulator_config.sh $CIHome/$NEInfoFile
cp $CIHome/$NEInfoFile $CIHome/script/PMRawFileSimulator
#cp $CIHome/$NEInfoFile $CIHome/script/EEPMRawFileSimulator

echo "0,15,30,45 * * * * /usr/bin/perl $CIHome/script/PMRawFileSimulator/pmrawfile_simulator.pl NEINFO.csv >/dev/null" > $CIHome/config/sim_cron 
echo "0,15,30,45 * * * * /usr/bin/perl $CIHome/script/EEPMRawFileSimulator/eepmrawfile_simulator.pl EENEInfo.cfg >/dev/null" >> $CIHome/config/sim_cron
echo "0 * * * * sh $CIHome/script/copyAmosFile.sh $CIHome $CIHome/$NEInfoFile" >> $CIHome/config/sim_cron

crontab -r
crontab $CIHome/config/sim_cron

writeMsg "crontab created" $logFile

writeMsg "Add a variable CIHome to /opt/nbi/.cshrc" $logFile
grep CIHome /opt/nbi/.cshrc
if [ $? != 0 ]
then
echo "setenv CIHome $CIHome" >> /opt/nbi/.cshrc
fi

writeMsg "Copy ENODEB amos files ...." $logFile
sh $CIHome/script/copyAmosFile.sh $CIHome $CIHome/$NEInfoFile

writeMsg "Copy ENODEB amos file done" $logFile

writeMsg "Invokde td-cm.sh/td-pm.sh to generated CMDef_Sync_Flow.xml, collector_Core.xml...." $logFile

cp -R /opt/nbi/Utilities/NEConfig/template /opt/nbi/Utilities/NEConfig/template.bk
cp $CIHome/config/template/CMSyncFlow/* /opt/nbi/Utilities/NEConfig/template/td-standard

cp $CIHome/config/template/PMCollector/* /opt/nbi/Utilities/NEConfig/template/td-collector

cp $CIHome/config/template/CMPMInterWork.xml /opt/nbi/config/CM/CMPMInterWork.xml 


### workround for RAN part, CORE NE will added to CI step by step
##
##if [ ! -f /opt/nbi/Utilities/NEConfig/data/td_common.dat ]
##then
##   echo "1 EPC  CG2 MM 7" >/opt/nbi/Utilities/NEConfig/data/td_common.dat 
##fi
##
##if [ ! -f /opt/nbi/Utilities/NEConfig/config/td-config.xml ]
##then
## cp /opt/nbi/Utilities/NEConfig/config/td-config_template.xml /opt/nbi/Utilities/NEConfig/config/td-config.xml
##fi
##

##comment below lines when NBIConfigFill.sh passed verification, currently copy fixed td_common.dat td_UDC.dat as workround
#workround begin

cp $CIHome/config/td_common.dat /opt/nbi/Utilities/NEConfig/data
cp $CIHome/config/td_UDC.dat /opt/nbi/Utilities/NEConfig/data
cp $CIHome/config/td-config.xml /opt/nbi/Utilities/NEConfig/config

## workround end

##uncomment below lines when NBIConfigFill.sh passed verification
#cp $CIHome/testdata/arne.xml /opt/nbi/Utilities/NEConfig/config
#cp $CIHome/config/common_config.xml /opt/nbi/Utilities/NEConfig/config
#sh $CIHome/script/NBIConfigFill.sh
#######

cd /opt/nbi/Utilities/NEConfig/
sh /opt/nbi/Utilities/NEConfig/td-cm.sh


mv /opt/nbi/config/CM/CMDef_Sync_Flow.xml /opt/nbi/config/CM/CMDef_Sync_Flow.xml.bk

if [ -f /opt/nbi/Utilities/NEConfig/result/CMDef_Sync_Flow.xml ] 
then 
   cp /opt/nbi/Utilities/NEConfig/result/CMDef_Sync_Flow.xml /opt/nbi/config/CM/CMDef_Sync_Flow.xml
   writeMsg "CMDef_Sync_Flow.xml generated " $logFile
   exit 0
else
   writeMsg "CMDef_Sync_Flow.xml generation failed, commission exit ..." $logFile
   exit 1
fi

cd /opt/nbi/Utilities/NEConfig/
sh /opt/nbi/Utilities/NEConfig/td-pm.sh

mv /opt/nbi/config/collector_Core.xml /opt/nbi/config/collector_Core.xml.bk

if [ -f /opt/nbi/Utilities/NEConfig/result/collector_Core.xml ] 
then 
   cp /opt/nbi/Utilities/NEConfig/result/collector_Core.xml /opt/nbi/config/collector_Core.xml
   writeMsg "/opt/nbi/config/collector_Core.xml generated " $logFile
   writeMsg "Commission done" $logFile
   exit 0
else
   writeMsg "collector_Core.xml generation failed, commission exit ..." $logFile
   exit 1
fi

#!/bin/sh

# Author: eyujche
# Date: 2013-11-05
# Description: This script used for ONV server commission, user file interface for onv_cm,onv_fm and onv_rtpm module


CIHome=`staf local var get system var ONV.Installation.CIGITHome |grep -v Response |grep -v '^-'`

DataLoc=$CIHome"/testdata"

echo "copy file ....."

cp $DataLoc/arne_oss_rc_data.xml  /opt/ericsson/onv/server/cm/test
cp $DataLoc/rru_output.xml  /opt/ericsson/onv/server/cm/test
cp $DataLoc/rtpem_oss_rc_data.xml /opt/ericsson/onv/server/cm/test

cp $DataLoc/alarm_oss_rc_data.txt /opt/ericsson/onv/server/fm/test

cp $DataLoc/rtpm_profile_oss_rc_data.txt  /opt/ericsson/onv/server/rtpm/test
cp $CIHome/config/networkconfig_epclink.xml  /var/opt/ericsson/onv/data

echo "copy file done....\n"s

echo "compare configuration file and copy configuration file .......\n"

for MC in cm fm rtpm
do

   OriConfigFile="/opt/ericsson/onv/server/"$MC"/conf/config.properties"
   OriConfigFile_bak=$OriConfigFile".orig"
   
   OriConfigFile_log="/opt/ericsson/onv/server/"$MC"/conf/log4j.xml"
   OriConfigFile_log_bak=$OriConfigFile_log".orig"
   
           
  mv $OriConfigFile $OriConfigFile_bak
  sed 's/file.cleanfile.debugmode=false/file.cleanfile.debugmode=true/g' $OriConfigFile_bak | sed 's/file.simulator.enable=false/file.simulator.enable=true/g' > $OriConfigFile
  
  if [ $? -eq 0 ]
  then 
     echo "$MC configuration file config.properties replaced"
  fi
  
  mv $OriConfigFile_log $OriConfigFile_log_bak
  sed 's/priority value="error"/priority value="info"/' $OriConfigFile_log_bak >$OriConfigFile_log
  
  if [ $? -eq 0 ]
  then 
     echo "$MC log config file log4j.xml replaced, log level changed to info\n"
  fi
  
done

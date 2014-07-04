#!/bin/sh
ECHO=/bin/echo
LS=/bin/ls
GREP=/bin/grep
common_dir=/opt/ericsson/onv/server/bin
common_exist=`$LS $common_dir |$GREP common.sh`
if [ "${common_exist}" != "common.sh" ];then
  $ECHO "Key file: common.sh cann't be found in $common_dir."
  exit 1
fi

. $common_dir/common.sh

$JAVA_CMD -jar ../lib/sqltool.jar --rcFile ./sqltool.rc onvdb

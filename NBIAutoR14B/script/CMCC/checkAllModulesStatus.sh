#!/usr/bin/sh

writeMsg()
{
	msg=$1
	logFile=$2
	timestamp=`date '+%Y/%m/%d %H:%M:%S'`
	echo "   $timestamp $msg" >> $logFile 
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
logFile=$FinalResultLoc/checkAllModulesStatus.log

rm $logFile >/dev/null 2>&1

Module_Name=All
case "$Module_Name" in  
	"All")
               pid=`ps -ef -o pid,args | grep EPAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No EPAgent is running." $logFile 
                else
                        writeMsg "EPAgent is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep FTAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No FTAgent is running." $logFile
                else
                        writeMsg "FTAgent is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep CSAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No CSAgent is running." $logFile
                else
                        writeMsg "CSAgent is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep CMPMInterwork |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No CMPMInterwork is running." $logFile
                else
                        writeMsg "CMPMInterwork is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep NAAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No NAAgent is running." $logFile
                else
                        writeMsg "NAAgent is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep CMAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No CMAgent is running." $logFile
                else
                        writeMsg "CMAgent is running." $logFile
                fi
                #pid=`ps -ef -o pid,args | grep CMAvcHandler |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                #if [ "$pid" -eq "" ]; then
                #        writeMsg "No CMAvcHandler is running." $logFile
                #else
                #        writeMsg "CMAvcHandler is running." $logFile
                #fi
                pid=`ps -ef -o pid,args | grep PMAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6` 
                if [ "$pid" -eq "" ]; then
                        writeMsg "No PMAgent is running." $logFile
                else
                        writeMsg "PMAgent is running." $logFile
                fi

				pid=`ps -ef -o pid,args | grep NFI |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6` 
                if [ "$pid" -eq "" ]; then
                        writeMsg "No NFI is running." $logFile
                else
                        writeMsg "NFI is running." $logFile
                fi
				pid=`ps -ef -o pid,args | grep EventDecoder |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6` 
                if [ "$pid" -eq "" ]; then
                        writeMsg "No EventDecoder is running." $logFile
                else
                        writeMsg "EventDecoder is running." $logFile
                fi
				pid=`ps -ef -o pid,args | grep PMFileCollector |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6` 
                if [ "$pid" -eq "" ]; then
                        writeMsg "No PMFileCollector is running." $logFile
                else
                        writeMsg "PMFileCollector is running." $logFile
                fi
                #$NBI_HOME/bin/NFI/admin.sh -stop
                #${NBI_HOME}/bin/EventDecoder/eventDecoder.sh -stop
                #$NBI_HOME/bin/PMFileCollector/PMFileCollector.sh -stop

                pid=`ps -ef -o pid,args | grep EventDistributor |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
		            if [ "$pid" -eq "" ]; then
			            writeMsg "No EventDistributor is running." $logFile
		            else
			            writeMsg "EventDistributor is running." $logFile
		            fi

#		            pid=`ps -ef -o pid,args | grep EEFileCollector |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
#		            if [ "$pid" -eq "" ]; then
#			            writeMsg "No EEFileCollector is running." $logFile
#		            else
#                    	writeMsg "EEFileCollector is running." $logFile
#		            fi
		            pid=`ps -ef -o pid,args | grep PMCLIRetriever |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
		            if [ "$pid" -eq "" ]; then
			            writeMsg "No PMCLIRetriever is running." $logFile
		            else
                    	writeMsg "PMCLIRetriever is running." $logFile
		            fi
                pid=`ps -ef -o pid,args | grep PMFileRetriever |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No PMFileRetriever is running." $logFile
                else
                        writeMsg "PMFileRetriever is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep PMMapping |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No PMMapping is running." $logFile
                else
                        writeMsg "PMMapping is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep AlarmAgent |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No AlarmAgent is running." $logFile
                else
                        writeMsg "AlarmAgent is running." $logFile
                fi
                pid=`ps -ef -o pid,args | grep AlarmAdaptor |grep -v $0|grep -v " vi" | grep -v " tail" |grep -v " more" |grep -v " grep" | cut -b 0-6`
                if [ "$pid" -eq "" ]; then
                        writeMsg "No AlarmAdaptor is running." $logFile
                else
                        writeMsg "AlarmAdaptor is running." $logFile
                fi
                ;;

esac


#!/bin/sh


if [ $# -ne 2 ]
then
  echo "Input parameter needed, usage $0 <CIHome> <NE Info File, .csv file>"
  exit 1
fi

CIHome=$1

NEINFO=$2

if [ -s $NEINFO ]
then
     echo "# NEName   Path  SubNetwork " >>EENEInfo.cfg.tmp
     while read LINE
     do
         if [ "`echo $LINE |grep "#"`" = "" ]
         then
     
            NEName=`echo $LINE |awk -F\, '{print $1}'`
            NEVersion=`echo $LINE |awk -F\, '{print $3}'`
            amosfile="enodeb_amosfilelist_"$NEVersion".txt"
            
            echo "/opt/nbi/DataFile/Retrieved/CM/"$NEName"_amos.out" >>$amosfile
            cp $CIHome/testdata/$NEName"_amos.out" /opt/nbi/DataFile/Retrieved/CM
            
            
        fi 
 
     done  < $NEINFO
     
     mv enodeb_amosfilelist_L13B.txt /opt/nbi/DataFile/Retrieved/CM/enodeb_amosfilelist_L13B.txt
     mv enodeb_amosfilelist_L12B.txt /opt/nbi/DataFile/Retrieved/CM/enodeb_amosfilelist_L12B.txt

 else
     echo NE information file $NEINFO not exist, script exit.......
     exit 1   
fi  

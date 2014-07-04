#!/bin/sh

 
 CIHome=`staf local var get system var Onv.Installation.CIGITHome |grep -v Response |grep -v '^-'`
 cp $CIHome/script/cli.sh /opt/ericsson/onv/server/tpp/hsqldb/bin/
 cp $CIHome/script/sqltool.rc /opt/ericsson/onv/server/tpp/hsqldb/bin/
 
 NEINFO=$CIHome/config/NEINFO.csv
 
 sql_script=$CIHome/script/insert_gnm_job.sql
 
 rm $sql_script
 
 bsc_rai=$CIHome/config/BSC_RAI.csv
 rnc_rai=$CIHome/config/RNC_RAI.csv
 
 
 datetime=`date '+%Y-%m-%d %H:%M:%S.0`

 
 if [ -s $NEINFO ]
 then
    count=1
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
          
            dn="SubNetwork=ONRM_ROOT_MO,SubNetwork="$SubNetwork",ManagedElement="$NEName
            echo_string1='INSERT INTO "PUBLIC"."GNM_JOB" ( "ID", "JOBNAME", "STATE", "STARTTIME", "RECOVERYSTATE", "RECOVERYMODE", "MOFDN", "RP" ) VALUES ('
            echo_string2="$count,'$dn',1,'$datetime',6,'MISSMODE','$dn',15);"
            echo "$echo_string1$echo_string2" >> $sql_script
            count=`expr $count + 1`

         fi
         
        fi
    done < $NEINFO
    echo "update GNM_RETRIEVE_MAP set CMD='gsh eci dist' where CMD='eci dist';" >> $sql_script
    echo "UPDATE CM_EPG SET UPIC='3';" >> $sql_script
    echo "UPDATE CM_MME SET PPSLICENSE='64';" >> $sql_script
    echo "commit;" >> $sql_script

 fi


cd /opt/ericsson/onv/server/tpp/hsqldb/bin/
./cli.sh <<EOF >>/home/nmsadm/cli_import.log
\i $sql_script
\q
EOF

/opt/ericsson/onv/server/bin/raimap.sh -ib $bsc_rai <<EOF
yes
EOF

/opt/ericsson/onv/server/bin/raimap.sh -ir $rnc_rai <<EOF
yes
EOF


#su - nmsadm -c '/opt/ericsson/onv/server/bin/onv.sh restart'

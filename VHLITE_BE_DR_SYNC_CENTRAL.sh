#!/bin/bash
# created by  Chandiman
# VH_LITE_DR_SYNC : Pool A OPS

OCI_DES_SCHEDULER_PATH=/usr/local/tbx/central/Scheduler_Resources
OCI_DES_LIBS_PATH=/usr/local/tbx/central/apache-tomcat-8.0.21/lib/ext
OCI_DES_SERVICES_PATH=/usr/local/tbx/central/apache-tomcat-8.0.21/webapps


OCI_DES_APP_SERVER_IP=10.168.3.57
OCI_DES_APP_USER=central


SOURCE_SCHEDULER_PATH=/usr/local/tbx/central/Scheduler_Resources
SOURCE_LIBS_PATH=/usr/local/tbx/central/apache-tomcat-8.0.21/lib/ext
SOURCE_SERVICES_PATH=/usr/local/tbx/central/apache-tomcat-8.0.21/webapps



CURRENT_TIME=`date "+%Y-%m-%d_%H.%M.%S"`
CURRENT_DATE=`date +"%Y_%m_%d"`

LOG_FILE_LOCATION=/home/central/dr_sync
SOURCE_MD5SUM_FILE_LOCATION=/home/central/dr_sync
OCI_DES_MD5SUM_FILE_LOCATION=/home/central/dr_sync

############

LOG_FILE=$LOG_FILE_LOCATION/"${OCI_DES_APP_USER}Synced_${CURRENT_TIME}".log
OCI_DES_MD5SUM_FILE=$OCI_DES_MD5SUM_FILE_LOCATION/"${OCI_DES_APP_USER}_source_md5sum_${CURRENT_TIME}".log
SOURCE_MD5SUM_FILE=$SOURCE_MD5SUM_FILE_LOCATION/"${OCI_DES_APP_USER}_des_md5sum_${CURRENT_TIME}".log
DIFF_OUTPUT_FILE=$LOG_FILE_LOCATION/diff_output_${CURRENT_DATE}.txt
STATUS_FILE=$LOG_FILE_LOCATION/STATUS_BE.log

##### mail details ###

subject="DO NOT REPLY: VHTC BE DR SYNC $CURRENT_TIME "
to="seops@codegen.net"

# Get DR server status

echo "Getting DR server status......"
PING_RESULT=$(ping -c 1 $OCI_DES_APP_SERVER_IP >/dev/null 2>&1 && echo "up" || echo "down")

if [ "$PING_RESULT" == "up" ]
then
echo "Server is up"


##rsync####

echo "Starting sync SCHEDULER........."
rsync -ravvzh $SOURCE_SCHEDULER_PATH/*.jar ${OCI_DES_APP_USER}@${OCI_DES_APP_SERVER_IP}:${OCI_DES_SCHEDULER_PATH}/ >> $LOG_FILE
echo "SCHEDULER sync completed"
echo "Starting sync LIBS........."
rsync -ravvzh $SOURCE_LIBS_PATH/*.jar ${OCI_DES_APP_USER}@${OCI_DES_APP_SERVER_IP}:${OCI_DES_LIBS_PATH}/>> $LOG_FILE
echo "LIBS sync completed"
echo "Starting sync SERVICES........."
rsync -ravvzh $SOURCE_SERVICES_PATH/*.war ${OCI_DES_APP_USER}@${OCI_DES_APP_SERVER_IP}:${OCI_DES_SERVICES_PATH}/ >> $LOG_FILE
echo "SERVICES sync completed"



################################ MD5SUM SOURCE#################################

#Get md5sum values in DR server
echo "Getting md5sum values from dr server ( 10.168.3.57 ).............."
echo "SCHEDULER" >> $OCI_DES_MD5SUM_FILE
ssh $OCI_DES_APP_USER@$OCI_DES_APP_SERVER_IP "cd $OCI_DES_SCHEDULER_PATH && md5sum *.jar" >> $OCI_DES_MD5SUM_FILE
echo "LIBS" >> $OCI_DES_MD5SUM_FILE
ssh $OCI_DES_APP_USER@$OCI_DES_APP_SERVER_IP "cd $OCI_DES_LIBS_PATH && md5sum *.jar ">> $OCI_DES_MD5SUM_FILE
echo "SERVICES" >> $OCI_DES_MD5SUM_FILE
ssh $OCI_DES_APP_USER@$OCI_DES_APP_SERVER_IP "cd $OCI_DES_SERVICES_PATH && md5sum *.war">> $OCI_DES_MD5SUM_FILE



# Get md5sum values in Local server
echo "Getting md5sum values from Local server ( 192.168.3.57 ).............."
echo "SCHEDULER" >> $SOURCE_MD5SUM_FILE
cd $SOURCE_SCHEDULER_PATH;md5sum *.jar >> $SOURCE_MD5SUM_FILE
echo "LIBS" >> $SOURCE_MD5SUM_FILE
cd $SOURCE_LIBS_PATH;md5sum *.jar >> $SOURCE_MD5SUM_FILE
echo "SERVICES" >> $SOURCE_MD5SUM_FILE
cd $SOURCE_SERVICES_PATH;md5sum *.war >> $SOURCE_MD5SUM_FILE

cd LOG_FILE_LOCATION

echo "Comparing values ............................."

if [ -z "$(diff $SOURCE_MD5SUM_FILE $OCI_DES_MD5SUM_FILE)" ]; then
  echo "Sync completed. md5sum values are identical."
  # sending mail
   #body="$CURRENT_TIME Backup is successfully."
   #echo  "$body" | mail -s "$subject" $to
   echo "yes" >> $STATUS_FILE

else
  echo "md5sum values are different. Please check again."
  echo "Different "
  diff $SOURCE_MD5SUM_FILE $OCI_DES_MD5SUM_FILE
  diff $SOURCE_MD5SUM_FILE $OCI_DES_MD5SUM_FILE >> $DIFF_OUTPUT_FILE
  #body="$CURRENT_TIME Backup is failed. md5sum values are different"
  #mail -s "$subject" -a "$DIFF_OUTPUT_FILE" "$to" <<< "$body"
  echo "no" >> $STATUS_FILE

fi

#create log file

echo "Date : $CURRENT_DATE" >> $LOG_FILE
echo "md5sum values for local ENV" >> $LOG_FILE
cat $OCI_DES_MD5SUM_FILE >> $LOG_FILE

echo "md5sum values for DR ENV" >> $LOG_FILE
cat $SOURCE_MD5SUM_FILE >> $LOG_FILE
echo "....................................................................." >> $LOG_FILE

echo "cleaning Temp log files......"
rm $OCI_DES_MD5SUM_FILE $SOURCE_MD5SUM_FILE
echo "log file creating successful....."

#remove old log files and txt files

log_dir="/home/central/dr_sync"
days=10
find $log_dir -type f -name "*.log" -mtime +$days -exec rm {} \;
find $log_dir -type f -name "*.txt" -mtime +$days -exec rm {} \;


else
  echo "Server is down"
  #body="$CURRENT_TIME Backup is failed.DR server is down"
  #echo  "$body" | mail -s "$subject" $to
  echo "down" >> $STATUS_FILE

fi

exit 0;

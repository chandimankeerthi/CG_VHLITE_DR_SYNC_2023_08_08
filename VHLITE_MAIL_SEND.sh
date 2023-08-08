#!/bin/bash
#created by Deshan
#Modified by Chandiman
#VH_DR_SYNC : Pool A OPS

VHTC_FE_IP=192.168.3.41
VHTC_FE_USER=vhtcfestg

VHTC_BE_IP=192.168.3.38
VHTC_BE_USER=vhtcbestg

VHTC_FE_STATUS_PATH=/home/vhtcfestg/dr_sync
VHTC_BE_STATUS_PATH=/home/vhtcbestg/dr_sync
MAIL_BODY_FILE=/home/vhtcbestg/dr_sync/body.txt

CURRENT_TIME=`date "+%Y-%m-%d_%H.%M.%S"`
CURRENT_DATE=`date +"%Y_%m_%d"`

##### mail details ###

subject="DO NOT REPLY: VHTC DR SYNC $CURRENT_TIME "
BE_ST=$(cat $VHTC_BE_STATUS_PATH/STATUS_BE.log)
to="seops@codegen.net"


# check sync status in FE side
FE_ST=$(ssh $VHTC_FE_USER@$VHTC_FE_IP "cat $VHTC_FE_STATUS_PATH/STATUS_FE.log")

#remove status file
ssh $VHTC_FE_USER@$VHTC_FE_IP "rm $VHTC_FE_STATUS_PATH/STATUS_FE.log"

# check sync status in BE side
BE_ST=$(cat $VHTC_BE_STATUS_PATH/STATUS_BE.log)

#remove status file
rm $VHTC_BE_STATUS_PATH/STATUS_BE.log


# Genarate email body for FE

if [ "$FE_ST" == "yes" ];then

    fe_body=" VHTC FE ($VHTC_FE_IP) $CURRENT_TIME Backup is successfully."

elif [ "$FE_ST" == "down" ];then

    fe_body=" VHTC FE ($VHTC_FE_IP) $CURRENT_TIME Backup is failed.DR server is down"
else
    fe_body=" VHTC FE ($VHTC_FE_IP) $CURRENT_TIME Backup is failed. md5sum values are different"
fi



# Genarate email body for BE

if [ "$BE_ST" == "yes" ];then

    be_body=" VHTC BE ($VHTC_BE_IP) $CURRENT_TIME Backup is successfully."

elif [ "$FE_ST" == "down" ];then

    be_body=" VHTC BE ($VHTC_BE_IP) $CURRENT_TIME Backup is failed.DR server is down"

else
    be_body=" VHTC BE ($VHTC_BE_IP) $CURRENT_TIME Backup is failed. md5sum values are different"

fi 

echo "VHTC DR sync status" >> $MAIL_BODY_FILE
echo "********************" >> $MAIL_BODY_FILE
echo "$fe_body" >> $MAIL_BODY_FILE
echo "********************" >> $MAIL_BODY_FILE
echo "$be_body" >> $MAIL_BODY_FILE

full_body=$(cat $MAIL_BODY_FILE) 

#send mail
echo  "$full_body" | mail -s "$subject" $to

#remove mail body file
rm $MAIL_BODY_FILE

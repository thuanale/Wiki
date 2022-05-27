#!/bin/bash
#########################################################################
#
# Script to check and send alert to L1 hotline if Number of JOBS >=300000
# Author: Son Nhat NGUYEN
# Version: 1.0
#
#########################################################################

source ~/bin/ssh_functions.sh

user=LBNAUTO

# Initial log filei
BASEDIR=$(dirname $0)/..
LOGDIR=${BASEDIR}/logs/SFO_jobs_check
LOGFILE=${LOGDIR}/SFO_jobs_check.log

JOBS_NUM=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@SFO.dfs "system 'dspsyssts' | grep 'Jobs in system'" 2> /dev/null | tail -1 | awk '{ print $17 }')

JOBS_CHECK=$(awk '{ if($1 >= 300000) print $1 }' <<< "$JOBS_NUM")

if [ ! -z "$JOBS_CHECK" ]; then
    date >> $LOGFILE
    echo "$JOBS_CHECK" >> $LOGFILE
    BODY="HIGH_SFO_JOBS:${JOBS_CHECK}"
    echo "$BODY" >> $LOGFILE
    curl --request POST \
  --url https://fcm.googleapis.com/fcm/send \
  --header 'Accept: application/json' \
  --header 'Authorization: key=AAAAp8nvbpQ:APA91bG10hOGWvtMbGPSld56FKEd2lKm-0kv9jQhQj90bYwzdG5P-zXcKALVKXdkZl6GmQSvU4lwLC2gxvJRLZXnVsd8qix8jFgKTtYHs_IZsnUR2b1cMZ7FaRulNJaiTfGfstydNjfS' \
  --header 'Content-Type: application/json' \
  --header 'Postman-Token: 3e4514cf-75d8-4f89-bae8-5b5233fd11fc' \
  --header 'cache-control: no-cache' \
  --data '{"condition":"'\''FCM-DATA'\'' in topics","data":{"title":"LINUX-MONITOR","body":"'${BODY}'"},"android":{"priority":"high"},"apns":{"headers":{"apns-priority":"10"}},"priority":10}'

fi

#!/usr/bin/bash
#=============================================================================
#
# Title: Master Script to check for the availability of spirit.py during SGT Business Hours
# Author: Son Nhat NGUYEN
# Version 1 - 04/11/2020
#
#=============================================================================

source /home/as400auto/bin/ssh_functions.sh
check_running

while :
do
    output=$(ps -ef | grep spirit | grep -v grep | grep python)
    if [ "$output" != "" ]; then
	echo "Script is running properly"
	echo "Sleeping for 10 minutes..."	
    else
	SMTP="smtprelaysg.dfs.com"
        PORT="25"
	FROM="spirit-watcher@dfs.com"
	TO="sn.nguyen@linkbynet.com"
	SUBJECT="Spirit Ticket Assigning Tool Status Report"
        mail_input ${SMTP} ${FROM} "${TO}" "${SUBJECT}" "Script is not running during Business Hours!!! Please check" | telnet ${SMTP} ${PORT}
    fi
    echo "========================================================"
    sleep 600
done



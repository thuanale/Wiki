#!/bin/bash

[[ ! -f ~/etc/agent.sh ]] && echo "Aborting: agent not started" && exit 1
source ~/etc/agent.sh >/dev/null

AS400USR=LBNAUTO
SMTP="smtprelaysg.dfs.com"
PORT="25"

function ssh_exec {
    [[ -z ${CMD} ]] && echo "Debug: No command set before calling ssh_exec" && exit 1
    ssh ${AS400USR}@${SRV}.dfs "system ${CMD}"
    RETCODE=$?
}

function is_alive {
    ping -c4 ${SRV}.dfs >/dev/null 2>&1
    RETCODE=$?
}

# This function to send mail. Example:
# FROM="noreply-dstqmon@dfs.com"
# TO="nqhuy211@gmail.com, qh.nguyen@linkbynet.com"
# SUBJECT="DSTQ Monitoring"
# mail_input ${SMTP} ${FROM} "${TO}" "Test Subject" "Test Body" | telnet ${SMTP} ${PORT}
# mail_input ${SMTP} ${FROM} "${TO}" "${SUBJECT}" "$(cat ${OUTFILE})" | telnet ${SMTP} ${PORT}

function mail_input {
    echo "helo $1" && sleep 1
    echo "MAIL FROM: <$2>" && sleep 1
    IFS=,
    for i in $3
    do
        echo "RCPT TO:<$i>" 
        sleep 1
    done
    echo "DATA" && sleep 1
    echo "From: <$2>" && sleep 1
    echo "To: <$3>" && sleep 1
    echo "Subject: $4" && sleep 1
    echo "$5" && sleep 1
    echo "." && sleep 1
    echo "quit"
}

# Validate if instance is running already
function check_running {
    PROG_NAME=$(basename $0)
    ALL_RUNNING=$(ps -ef)
    NB_RUNNING=$(echo "${ALL_RUNNING}" | grep -v "grep" | grep -v "vi" | grep -v "more" | grep -v "tail" | grep -v "sh -c" | grep ${PROG_NAME} | wc -l)
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${NB_RUNNING} instance ${PROG_NAME} is running."
    [[ ${NB_RUNNING} -gt 1 ]] && echo "$(date +'%Y-%m-%d %H:%M:%S') SCRIPT IS ALREADY RUNNING. EXITING THIS INSTANCE." && exit 1
}

#!/bin/bash

################################################################################################################
#
# Description:  This script monitors DSTQ on AS400 servers
# Author:       Huy Quang Nguyen
# Created on:   16/08/2019
# Version:      1.0 Initial Creation
#               1.1 Edit output format - 2019/08/26
#               1.2 Edit function - 2019/09/10
#
################################################################################################################

function log {
    echo "$1" >&2
    echo "$1" >> ${LOGFILE}
}

source ~/bin/ssh_functions.sh
DIR_NAME=$(dirname $0) && cd ${DIR_NAME}
BASEDIR=$(dirname $0)/..
CFGDIR=${BASEDIR}/etc
# Initialize log file
LOGDIR=${BASEDIR}/logs/dstq_mon
mkdir -p ${LOGDIR}
LOGFILE=${LOGDIR}/dstq_mon.log
OUTFILE=${LOGDIR}/dstq_mon.out
echo $(date +'%Y-%m-%d %H:%M:%S') > ${OUTFILE}

check_running >> ${LOGFILE}

# For sending email
FROM="noreply-dstqmon@dfs.com"
TO="DFS-RICE-OPS@linkbynet.com, DFS-RICE-IBM@linkbynet.com"
SUBJECT="DSTQ Monitoring"
DOMAIN="DFS"

for SERVER in $(cat ${CFGDIR}/as400_prod)
do
    DSTQ_FAIL=$(ssh -o ConnectTimeout=10 ${AS400USR}@${SERVER}.${DOMAIN} 'system "wrkdstq"' | grep "Normal\|High" | grep -v "Distribution queue priority\|Waiting\|Held")
    DSTQ_FAIL_NUM=$(echo "${DSTQ_FAIL}" | grep -i Rty | wc -l)
    if [ ${DSTQ_FAIL_NUM} -gt 0 ]
    then
        echo "*****${SERVER} is having DSTQ error, please check:*****" >> ${OUTFILE}
        echo "${DSTQ_FAIL}" >> ${OUTFILE}
    fi
done

CHK_OUTFILE=$(cat ${OUTFILE} | wc -l)

if [ ${CHK_OUTFILE} -gt 1 ]
then
    mail_input ${SMTP} ${FROM} "${TO}" "${SUBJECT}" "$(cat ${OUTFILE})" | telnet ${SMTP} ${PORT}
    log "$(date +'%Y-%m-%d %H:%M:%S') DSTQ is having issue!"
    log "$(date +'%Y-%m-%d %H:%M:%S') Alert email sent to ${TO}."
else
    log "$(date +'%Y-%m-%d %H:%M:%S') DSTQ checking done, all servers are OK."
fi

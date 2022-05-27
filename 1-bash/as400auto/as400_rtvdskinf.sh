#!/bin/bash

################################################################################################################
#
# Description:  This script launches retrieve disk info job on AS400 servers
# Author:       Huy Quang Nguyen
# Created on:   14/08/2019
# Version:      1.0 Initial Creation
#
################################################################################################################

source ~/bin/ssh_functions.sh
check_running
DIR_NAME=$(dirname $0)
cd ${DIR_NAME}

USER="LBNAUTO"
DOMAIN="DFS"
EXCLUDE="NONE"
BASEDIR=$(dirname $0)/..
CFGDIR=${BASEDIR}/etc
LOGDIR=${BASEDIR}/logs

for SERVER in `cat ${CFGDIR}/as400_prod`
do
echo "===========${SERVER}============"
    for TMP in ${EXCLUDE}
    do
        [[ ${TMP} == ${SERVER} ]] && echo "Excluding ${SERVER}" && continue 2
    done
ssh -o ConnectTimeout=10 ${USER}@${SERVER}.${DOMAIN} << EOF
system "SBMJOB CMD(RTVDSKINF) JOB(RTVDSKINF) JOBQ(QSYS/QCTL)";
exit
EOF
done


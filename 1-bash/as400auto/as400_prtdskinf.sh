#!/bin/bash

################################################################################################################
#
# Description:  This script launches print disk info job on AS400 servers
# Author:       Huy Quang Nguyen
# Created on:   14/08/2019
# Version:      1.0 Initial Creation
#
################################################################################################################

source ~/bin/ssh_functions.sh
check_running
DIR_NAME=$(dirname $0)
cd ${DIR_NAME}

FDATE=`date +'%Y-%m-%d %H:%M'`
SDATE=`date +'%Y%m%d'`
USER="LBNAUTO"
DOMAIN="DFS"
EXCLUDE="NONE"

BASEDIR=$(dirname $0)/..
CFGDIR=${BASEDIR}/etc
LOGDIR=${BASEDIR}/logs/as400_prtdskinf

# Initialize log file
#mkdir -p ${LOGDIR}
LOGFILE=${LOGDIR}/prtdskinf_${SDATE}.log

rm ${LOGDIR}/prtdskinf_*.log.gz
echo ${FDATE} > ${LOGFILE}

for SERVER in `cat ${CFGDIR}/as400_prod`
do
echo "===========${SERVER}============" >> ${LOGFILE}
    for TMP in ${EXCLUDE}
    do
        [[ ${TMP} == ${SERVER} ]] && echo "Excluding ${SERVER}" && continue 2
    done
ssh -o ConnectTimeout=10 ${USER}@${SERVER}.${DOMAIN} 'system "PRTDSKINF RPTTYPE(*LIB)";system "PRTDSKINF RPTTYPE(*LIB) OBJ(*ALL) MINSIZE(99999)";' >> ${LOGFILE}
done

gzip -f ${LOGFILE}
python as400_prtdskinf_mail.py dfs-rice-ibm@linkbynet.com

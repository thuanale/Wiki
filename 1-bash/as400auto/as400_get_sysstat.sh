#!/bin/bash

################################################################################################################
#
# Description:  This script get system value of AS400 servers then input to DB
# Author:       Huy Quang Nguyen
# Version:      1.0 Initial Creation - 11/09/2019
#
################################################################################################################

source ~/bin/ssh_functions.sh
DIR_NAME=$(dirname $0) && cd ${DIR_NAME}
BASEDIR=$(dirname $0)/..
CFGDIR=${BASEDIR}/etc
LOGDIR=${BASEDIR}/logs/as400_get_sysstat

check_running
echo "$(date +'%Y-%m-%d %H:%M:%S') Starting collect data" 

USER=LBNAUTO
DATFILE=${LOGDIR}/AS400_SYSSTAT

[[ ! -f ${DATFILE} ]] &&\
    echo "CREATE TABLE SYSSTAT (timestamp INTEGER, server TEXT, cpu REAL, asp_gb REAL, asp_pct REAL, jobs INTEGER, temp_mb INTEGER);" |\
     sqlite3 ${DATFILE}  

TS=$(date +%s)

for SERVER in $(cat ${CFGDIR}/as400_prod_dr)
do
    #echo $SERVER
    case $SERVER in
    KSENV6U|SAP2PFS)
    VAL=$(ssh ${USER}@${SERVER}.DFS "system DSPSYSSTS"  | egrep '(%|Job)' | sed -e 'N;N;N;N' -e 's/\n/ /g' -e 's/ \.//g' -e 's/ \+/ /g' -e 's/[a-zA-Z]\+//g' | awk '{print $3, $5, $10, $12, $19}')
    ;;

    *)
    VAL=$(ssh ${USER}@${SERVER}.DFS "system DSPSYSSTS"  | egrep '(%|Job)' | sed -e 'N;N;N;N' -e 's/\n/ /g' -e 's/ \.//g' -e 's/ \+/ /g' -e 's/[a-zA-Z]\+//g' | awk '{print $3, $5, $11, $13, $15}')
    ;;
    esac
    #echo $VAL | awk '{print NF}'

    [[ $(echo $VAL | awk '{print NF}') != 5 ]] && VAL="0 0 0 0 -1"
    VAL="${TS} ${SERVER} ${VAL}"
    echo $VAL
    echo ${VAL} | awk '{printf("INSERT INTO SYSSTAT VALUES(%s, \"%s\", %s, %s, %s, %s, %s);\n", $1, $2, $3, $4, $5, $6, $7)}' | sqlite3 ${DATFILE}
done
echo "$(date +'%Y-%m-%d %H:%M:%S') Finish collecting" 

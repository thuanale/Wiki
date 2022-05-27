user=$1

ASPSRV=(CAM CATS CLUX DFSNZ1 DFSDEVD DRCAM DRCATS DRCLUX DRDFSNZ1 DRGDC DRGVA DRHKGA DRHNL DRINDO DRITL DRKOREA DRLAX1 DRMIDEST DRMIDPAC DRPAD1 DRPAX1 DRPRC DRSAP2PF DRSFO2 DRSIN2 DRSYD FRANCE GDC GVA HKGA HNL INDO ITL KOREA KSENV5U KSENV6 KSENV6U LAX1 MIDEAST MIDPAC PAD1 PAX1 PRC SAP2PFS SFO SFO2 SIN2 SYD)
INCSRV=(CAM CATS CLUX DFSNZ1 DRSAP2PF FRANCE GDC GVA HKGA HNL INDO ITL KOREA LAX1 MIDEAST MIDPAC PAD1 PAX1 PRC SFO SFO2 SIN2 SYD)
count=0

while :;
do
    start=`date +%s`
    ERR_host_arr=()
    ASP_host_arr=()
    ASP_arr=()
    INC_host_arr=()
    INC_type_arr=()
    INC_stt_arr=()
    INC_END_host_arr=()
    INC_END_code_arr=()
    JOBS_PRINT=""
    REST_JOB=""
    for host in "${ASPSRV[@]}"
    do
        currTime=`date +%s`
        host=$(echo $host | tr '[:lower:]' '[:upper:]')
        nc -z ${host}.dfs -w 10 22 > /dev/null

        if [[ $? != 0 ]]
        then
            ERR_host=$(echo -e "\e[41m$host\033[0m")
            ERR_host_arr=( "${ERR_host_arr[@]}" "$ERR_host" )
        else
            RES=""
            ASP=""
            INC=""
            etime=""
            if echo ${INCSRV[@]} | grep -q -w "$host"; then
                case $host in
                    CAM)
                        etime="00:15"
                        ;;
                    CATS)
                        if [ `date +%u` -ne 7 ]; then
                            etime="01:30" #except Sun
                        fi
                        ;;
                    CLUX)
                        etime="23:59"
                        ;;
                    DFSNZ1)
                        etime="01:30"
                        ;;
                    FRANCE)
                        etime="05:50"
                        ;;
                    GVA)
                        if [ `date +%u` -eq 7 ]; then
                            etime="20:30"
                        else
                            etime="19:30"
                        fi
                        ;;
                    GDC)
                        etime="00:15"
                        ;;
                    HKGA)
                        if [ `date +%u` -ne 7 ]; then
                            etime="02:00" #except Sun
                        fi
                        ;;
                    HNL)
                        if [ `date +%u` -ne 7 ]; then
                            etime="17:45" #except Sun
                        fi
                        ;;
                    INDO)
                        etime="23:00"
                        ;;
                    ITL)
                        etime="04:45"
                        ;;
                    KOREA)
                        etime="21:50"
                        ;;
                    LAX1)
                        if [ `date +%u` -ne 7 ]; then
                            etime="14:00" #except Sun
                        fi
                        ;;
                    MIDEAST)
                        etime="02:15"
                        ;;
                    MIDPAC)
                        etime="21:30"
                        ;;
                    PAD1)
                        if [ `date +%u` -ne 1 ]; then
                            etime="21:00" #except Mon
                        fi
                        ;;
                    PAX1)
                        if [ `date +%u` -ne 1 ]; then
                            etime="18:45" #except Mon
                        fi
                        ;;
                    PRC)
                        etime="23:15"
                        ;;
                    DRSAP2PF)
                        if [ `date +%u` -ne 7 ]; then
                            etime="18:30" #except Sun
                        fi
                        ;;
                    SFO)
                        if [ `date +%u` -ne 7 ]; then
                            etime="21:15" #except Sun
                        fi
                        ;;
                    SFO2)
                        etime="21:30"
                        ;;
                    SIN2)
                        if [ `date +%u` -ne 6 ]; then
                            etime="23:00" #except Sat
                        fi
                        ;;
                    SYD)
                        etime="22:30"
                        ;;
                    *)
                        exit 1
                        ;;
                esac

                RES=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'dspsyssts' | grep 'ASP used' && system 'wrkactjob' | grep BRMSSAVE" 2> /dev/null)
                ASP=$(echo "$RES" | grep '% system ASP used' | tail -1 | awk '{ print $28 }' | xargs)
                INC=$(echo "$RES" | grep -E "BRMSSAVE.*BCH" | tail -1 | awk '{ print $1"\t"$12}' | xargs)
                PRINT1=$(awk '{ print $1 }' <<< $INC)
                STT=$(awk '{ print $2 }' <<< $INC)
                if [[ $INC = *MSGW* ]]
                then
                    PRINT2=$(echo -e "\e[41m$STT\033[0m")
                else
                    PRINT2=$(echo -e "\e[32m$STT\033[0m")
                fi

                if [[ "$INC" != "" ]]; then
                    if [[ $host = *DRSAP2PF* ]]
                    then
                        host="DRSAP2"
                    fi
                    INC_host_arr=( "${INC_host_arr[@]}" "$host" )
                    INC_type_arr=( "${INC_type_arr[@]}" "$PRINT1" )
                    INC_stt_arr=( "${INC_stt_arr[@]}" "$PRINT2" )
                else
                    if [[ "$etime" != "" ]]; then
                        #
                        if [ $currTime -ge `date -d "$etime 1 hour ago" +%s` ] && [ $currTime -le `date -d "$etime 90 minutes" +%s` ]; then
                            RES_TMP=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs 'system "PRTRPTBRM TYPE(*CTLGRPSTAT) CTLGRP(SAVDLY)"' | tail -2 | head -1 | awk '{print $13}')
                            if [[ $RES_TMP = *QUAL* ]]; then
                                RES_2=$(echo -e "\e[32m$RES_TMP\033[0m")
                            fi
                            if [[ $host = *DRSAP2PF* ]]
                            then
                                host="DRSAP2"
                            fi
                            INC_END_host_arr=( "${INC_END_host_arr[@]}" "$host" )
                            INC_END_code_arr=( "${INC_END_code_arr[@]}" "$RES_2" )
                        fi
                    fi
                fi
                #[ -z "$INC" ] || paste <(printf %s "$host") <(printf %s "") <(printf %s "$PRINT1") <(printf %s "$PRINT2")
            else
                if [[ $host = KSENV6U ]] || [[ $host = SAP2PFS ]]; then
                    ASP=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'dspsyssts' | grep '% system ASP used'" 2> /dev/null | grep '% system ASP used' | tail -1 | awk '{ print $33 }' | xargs)
                else
                    if [[ $host = SFO ]]; then
                        ASP_TMP=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'dspsyssts' | grep -E '(% system ASP used|Jobs in system)'" 2> /dev/null)
                        ASP=$(echo -e "$ASP_TMP" | head -1 | awk '{ print $28 }' | xargs)
                        JOBS_NUM=$(echo -e "$ASP_TMP" | tail -1 | awk '{ print $17 }')
                    else
                        ASP=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'dspsyssts' | grep '% system ASP used'" 2> /dev/null | grep '% system ASP used' | tail -1 | awk '{ print $28 }' | xargs)
                    fi
                fi
            fi
            if [[ $host = DFSDEVD ]]
            then
                REST_JOB=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'WRKACTJOB'" | grep -E 'RST|RNM' | awk '{ print $1 "-" $12 }')
            elif [[ $host = SFO ]]
            then
                JOBS_NUM=$(ssh -n -o ConnectTimeout=60 -o StrictHostKeyChecking=no $user@$host.dfs "system 'dspsyssts' | grep 'Jobs in system'" 2> /dev/null | tail -1 | awk '{ print $17 }')
                JOBS_CHECK=$(awk '{ if($1 >= 300000) print $1 }' <<< "$JOBS_NUM")
                if [[ "$JOBS_CHECK" < 350000 ]]
                then
                    JOBS_PRINT=$(echo -e "\e[33m\t$JOBS_CHECK\033[0m")
                else
                    JOBS_PRINT=$(echo -e "\e[41m\t$JOBS_CHECK\033[0m")
                fi

                CHECK=$(awk '{ if($1 >= 70) print $1 }' <<< "$ASP")
                if [[ "$CHECK" < 75 ]]
                then
                    PRINT=$(echo -e "|\e[33m\t$CHECK\033[0m")
                else
                    PRINT=$(echo -e "|\e[41m\t$CHECK\033[0m")
                fi

                if [[ "$CHECK" != "" ]]; then
                    ASP_host_arr=( "${ASP_host_arr[@]}" "$host" )
                    ASP_arr=( "${ASP_arr[@]}" "$PRINT" )
                fi
                #[ -z "$CHECK" ] || paste <(printf %s "$host") <(printf %s "$PRINT")
            elif [[ $host = DR* ]]
            then
                #awk '{ if($1 >= 90) { print $2" | "$1 }}' <<< "$ASP $host"
                CHECK=$(awk '{ if($1 >= 90) print $1 }' <<< "$ASP")
                if [[ "$CHECK" < 93 ]]
                            then
                    PRINT=$(echo -e "|\e[33m\t$CHECK\033[0m")
                else
                    PRINT=$(echo -e "|\e[41m\t$CHECK\033[0m")
                fi
                case $host in
                    DRMIDEST)
                        host="DRM-EST"
                        ;;
                    DRDFSNZ1)
                        host="DRNZ1"
                        ;;
                    DRMIDPAC)
                        host="DRMPAC"
                        ;;
                    DRSAP2PF)
                        host="DRSAP2"
                        ;;
                    *)
                        ;;
                esac

                if [[ "$CHECK" != "" ]]; then
                    ASP_host_arr=( "${ASP_host_arr[@]}" "$host" )
                    ASP_arr=( "${ASP_arr[@]}" "$PRINT" )
                fi
                #[ -z "$CHECK" ] || paste <(printf %s "$host") <(printf %s "$PRINT")
            else
                #awk '{ if($1 >= 84) { print $2" | "$1 }}' <<< "$ASP $host"
                CHECK=$(awk '{ if($1 >= 85) print $1 }' <<< "$ASP")
                if [[ "$CHECK" > 85 ]] || [[ "$CHECK" = 85 ]] && [[ "$CHECK" < 86 ]]
                then
                    PRINT=$(echo -e "|\e[33m\t$CHECK\033[0m")
                elif [[ "$CHECK" > 86 ]] || [[ "$CHECK" = 86 ]] && [[ "$CHECK" < 89 ]]
                then
                    PRINT=$(echo -e "|\e[35m\t$CHECK\033[0m")
                else
                    PRINT=$(echo -e "|\e[41m\t$CHECK\033[0m")
                fi
                if [[ "$CHECK" != "" ]]; then
                    ASP_host_arr=( "${ASP_host_arr[@]}" "$host" )
                    ASP_arr=( "${ASP_arr[@]}" "$PRINT" )
                fi
                #[ -z "$CHECK" ] || paste <(printf %s "$host") <(printf %s "$PRINT")
            fi
        fi
    done

    if [ $count -gt 0 ]; then
        #sleep 30
        clear
        date +"Date: "%d/%m/%y" - Time: "%T
        echo "---------------------------"
        if [ ! -z $ASP_host_arr ]; then
            echo -e "\e[4mASP:\e[0m"
            END1=${#ASP_host_arr[@]}
            for ((i=1;i<=END1;i++)); do
                paste <(printf %s "${ASP_host_arr[$i-1]}") <(printf %s "${ASP_arr[$i-1]}")
            done
            echo "---------------------------"
        fi
        if [ ! -z $INC_host_arr ]; then
            echo -e "\e[4mIncremental Backups:\e[0m"
            END2=${#INC_host_arr[@]}
            for ((i=1;i<=END2;i++)); do
                paste <(printf %s "${INC_host_arr[$i-1]}") <(printf %s "${INC_type_arr[$i-1]}") <(printf %s "${INC_stt_arr[$i-1]}")
            done
            echo "---------------------------"
        fi
        if [ ! -z $INC_END_host_arr ]; then
            echo -e "\e[4mFinished INC:\e[0m"
            END3=${#INC_END_host_arr[@]}
            for ((i=1;i<=END3;i++)); do
                paste <(printf %s "${INC_END_host_arr[$i-1]}") <(printf %s "RESULT:") <(printf %s "${INC_END_code_arr[$i-1]}")
            done
            echo "---------------------------"
        fi

        if [ ! -z "$JOBS_CHECK" ]; then
            echo -e "\e[4mSFO Jobs:\e[0m $JOBS_PRINT"
            echo "---------------------------"
        fi

        if [ ! -z "$REST_JOB" ]; then
            echo -e "\e[4mRestoration:\e[0m $REST_JOB"
        fi
        #echo -e "\e[4mL1-Sentinel:\e[0m"
        #ALERT=$(cat /home/lbn/sn.nguyen/aix-report.txt)
        #echo -e "\e[41m$ALERT\033[0m"

        echo "============END============"
        if [ ! -z $ERR_host_arr ]; then
            echo -e "\e[4mAuthentication Error For:\e[0m"
            END4=${#ERR_host_arr[@]}
            for ((i=1;i<=END4;i++)); do
                paste <(printf %s "${ERR_host_arr[$i-1]}")
            done
            echo -e "Please stop the script and check!!!"
            echo "---------------------------"
        fi
    else
        date +"Date: "%d/%m/%y" - Time: "%T
        echo "---------------------------"
        if [ ! -z $ASP_host_arr ]; then
            echo -e "\e[4mASP:\e[0m"
            END1=${#ASP_host_arr[@]}
            for ((i=1;i<=END1;i++)); do
                paste <(printf %s "${ASP_host_arr[$i-1]}") <(printf %s "${ASP_arr[$i-1]}")
            done
            echo "---------------------------"
        fi

        if [ ! -z $INC_host_arr ]; then
            echo -e "\e[4mIncremental Backups:\e[0m"
            END2=${#INC_host_arr[@]}
            for ((i=1;i<=END2;i++)); do
                paste <(printf %s "${INC_host_arr[$i-1]}") <(printf %s "${INC_type_arr[$i-1]}") <(printf %s "${INC_stt_arr[$i-1]}")
            done
            echo "---------------------------"
        fi

        if [ ! -z $INC_END_host_arr ]; then
            echo -e "\e[4mFinished INC:\e[0m"
            END3=${#INC_END_host_arr[@]}
            for ((i=1;i<=END3;i++)); do
                paste <(printf %s "${INC_END_host_arr[$i-1]}") <(printf %s "RESULT:") <(printf %s "${INC_END_code_arr[$i-1]}")
            done
            echo "---------------------------"
        fi

        if [ ! -z "$JOBS_CHECK" ]; then
            echo -e "\e[4mSFO Jobs:\e[0m $JOBS_PRINT"
            echo "---------------------------"
        fi

        echo -e "\e[4mL1-Sentinel:\e[0m"
        ALERT=$(cat /home/lbn/sn.nguyen/aix-report.txt)
        echo -e "\e[41m$ALERT\033[0m"
        echo "============END============"
        if [ ! -z $ERR_host_arr ]; then
            echo -e "\e[4mAuthentication Error For:\e[0m"
            END4=${#ERR_host_arr[@]}
            for ((i=1;i<=END4;i++)); do
                paste <(printf %s "${ERR_host_arr[$i-1]}")
            done
            echo -e "Please stop the script and check!!!"
            echo "---------------------------"
        fi
        #sleep 30
        clear
    fi
    end=`date +%s`
    runtime=$((end-start))
    echo "Execution Time: $runtime seconds"
    ((count++))
done

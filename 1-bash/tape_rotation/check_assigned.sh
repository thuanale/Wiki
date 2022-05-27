#!/bin/bash
#check the file
[[ "$#" -eq "0" ]] && echo "USAGE: bash check_assigned.sh <assigned_file>" && exit 1 || {
    file="$1"
    [[ ! -e "$file" ]] && echo "File not found!" && exit 1
    [[ ! -s "$file" ]] && echo "File is empty!" && exit 1
}

declare -A assigned     # assigned quantity vs servers
declare -A missed       # server(s) doesn't have enough required tape(s)
declare -A redundant    # server(s) has more tape(s) than required.
declare -A required     # required quantity vs servers

#List of required files
script=$(dirname "$0")
server_ip_file="$script/server.txt"

dir="$HOME/NTT/$(date +%Y)/$(date +%m)"
[[ ! -d "$dir" ]] && mkdir -p "$dir"
today="$(date +%A)"
date_format="$(date +%d%m%y)"
missed_file="$dir/MISSED_$date_format.txt"
redudant_file="$dir/REDUNDANT_$date_format.txt"
#counting tapes
servers=( $(awk '{print $NF}' "$file") )
for server in ${servers[@]}
do
    [[ -z "${assigned[$server]}" ]] && assigned["$server"]="1" || (( assigned["$server"]+=1 ))
done 

#export server which missed tape

case "$today" in
    "Friday")
        required["CAM"]=1;required["CATS"]=1;required["CLUX"]=1;required["DFSNZ1"]=2;required["FRANCE"]=1;
        required["GDC"]=1;required["GVA"]=1;required["HKGA"]=1;required["HNL"]=1;required["INDO"]=1;
        required["ITL"]=1;required["KOREA"]=1;required["KSENV5U"]=1;required["KSENV6"]=1;required["KSENV6U"]=1;
        required["LAX1"]=1;required["MIDEAST"]=2;required["MIDPAC"]=1;required["PAD1"]=1;required["PAX1"]=1;
        required["PRC"]=1;required["SFO"]=1;required["SFO2"]=1;required["SIN2"]=1;required["SYD"]=1;
        ;;
    "Saturday")
        
        today_month="$(date +%m)"
#Check if today is second Saturday of the month
        if [[ "$today_month" = "$(date -d "1 week ago" +%m )" && 
            ! "$today_month" = "$(date -d "2 week ago" +%m )" ]]
        then
            required["CAM"]=2;required["CATS"]=1;required["CLUX"]=2;required["DFSNZ1"]=1;required["FRANCE"]=2;
            required["GDC"]=2;required["GVA"]=2;required["HKGA"]=2;required["HNL"]=2;required["INDO"]=2;
            required["ITL"]=1;required["KOREA"]=2;required["KSENV5U"]=0;required["KSENV6"]=0;required["KSENV6U"]=0;
            required["LAX1"]=1;required["MIDEAST"]=1;required["MIDPAC"]=2;
            required["PAD1"]=1;required["PAX1"]=1;required["PRC"]=2;required["SFO"]=1;required["SFO2"]=2;
            required["SIN2"]=1;required["SYD"]=2;
        else
            required["CAM"]=2;required["CATS"]=1;required["CLUX"]=2;required["DFSNZ1"]=1;required["FRANCE"]=2;
            required["GDC"]=2;required["GVA"]=2;required["HKGA"]=1;required["HNL"]=2;required["INDO"]=2;
            required["ITL"]=1;required["KOREA"]=2;required["KSENV5U"]=0;required["KSENV6"]=0;required["KSENV6U"]=0;
            required["LAX1"]=1;required["MIDEAST"]=1;required["MIDPAC"]=2;
            required["PAD1"]=1;required["PAX1"]=1;required["PRC"]=2;required["SFO"]=1;required["SFO2"]=2;
            required["SIN2"]=1;required["SYD"]=2;
        fi
        ;;
    *)
        required["CAM"]=1;required["CATS"]=1;required["CLUX"]=1;required["DFSNZ1"]=1;required["FRANCE"]=1;
        required["GDC"]=1;required["GVA"]=1;required["HKGA"]=1;required["HNL"]=1;required["INDO"]=1;
        required["ITL"]=1;required["KOREA"]=1;required["KSENV5U"]=0;required["KSENV6"]=0;required["KSENV6U"]=0;
        required["LAX1"]=1;required["MIDEAST"]=1;required["MIDPAC"]=1;required["PAD1"]=1;required["PAX1"]=1;
        required["PRC"]=1;required["SFO"]=1;required["SFO2"]=1;required["SIN2"]=1;required["SYD"]=1;
        ;;
    esac
    
for server in ${!required[@]}
do
    different=$(( assigned[$server] - required[$server] ))
    [[ "$different" -lt 0 ]] && missed["$server"]=$(( different*-1 ))
    [[ "$different" -gt 0 ]] && redundant["$server"]=$different
done

echo "Tapes in total: $(wc -l  < $file)"
[[ -z "${missed[@]}" ]] && echo "BINGO!" || 
{
    #created file
    for server in ${!missed[@]}
    do 
    printf "%-10s%4d\n" $server ${missed[$server]}
    done | sort > "$dir/MISSED_$date_format.txt"
    
    for server in ${!redundant[@]}
    do 
        #check if server is up/down
        #space in '/'$server '/ is needed => different between KSENV6 & KSENV6U
        ip=$(awk '/'$server' / {print $2}' "$server_ip_file")
        if ping -c 2 $ip &> /dev/null
        then 
            printf "%-10s%4d\n" $server ${redundant[$server]}
        fi

    done | sort -nk2,2r > "$redudant_file"

    #export to output
    echo "Missed server:"
    cat "$missed_file"
    echo "Redundant server:"
    cat "$redudant_file"
}
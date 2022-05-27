#!/usr/bin/bash
#===================================================================================
# #
#FILE: kddi_thursday_tapes.sh
# #
#USAGE: bash kddi_thursday_tapes.sh <AS400 uid>
#
# DESCRIPTION: Print list of tapes that need to be retrieved to KDDI for DRSAP2PF BK
# VERSION: 1.0
# CREATED: 12.11.2020 - 09:41:00 UTC+7
# REVISION: 12.11.2020
#==================================================================================

ER_NOINPUT=64
[[ -n "$@" ]] && user="$1" || {
    echo "NO INPUT DATA."
    echo "USAGE: bash kddi_thursday_tapes.sh <AS400 uid>"
    exit $ER_NOINPUT
}

check_mlb_tapes="$(dirname "$0")/check_mlb_tapes.sh"

#Check directory
dir="$HOME/KDDI/$(date +%Y)/$(date +%m)"
[[ ! -d "$dir" ]] && mkdir -p "$dir"
date_format="$(date +%d%m%y)"
offsite_file="$dir/OFFSITE_$date_format.TXT"
expired_file="$dir/EXPIRED_$date_format.TXT"
retrieved_file="$dir/RETRIEVED_$date_format.TXT"

weekday="$(date +%u)"
if [[ "$weekday" -eq "1" ]]
then
	ssh $user@DRSAP2PF.DFS "system 'PRTRPTBRM TYPE(*CTLGRPSTAT) PERIOD(*DAYS) DAYS(3)'" | awk '/50[0-9]{4}/ {printf("%-6dL5\n",$12)}' | tail -3 > "$offsite_file"
elif [[ "$weekday" -ge "2" && "$weekday" -le "5" ]]
then
#Get all tapes that are in expired status
    ssh $user@DRSAP2PF.DFS "system 'PRTRPTBRM TYPE(*CTLGRPSTAT) PERIOD(*DAYS) DAYS(1)'" | awk '/50[0-9]{4}/ {printf("%-6dL5\n",$12)}' | tail -1 > "$offsite_file"
    [[ "$weekday" -eq "4" ]] && {
    ssh $user@DRSAP2PF.DFS 'system "WRKMEDBRM TYPE(*EXP) LOC(TAPMLB09) MEDCLS(ULTRIUM5)"' | grep '*NONE' > "$expired_file"
    bash "$check_mlb_tapes" -u "$user" -f "$expired_file" -l kddi | grep -E '^50[0-9]+' > "$retrieved_file"
    }
else
#Print tape are not in media libary
    echo "Nothing to show today."
fi

find "$dir/" -type f \( ! -name OFFSITE_* \) -and \( ! -name RETRIEVED_* \) -delete;

print_files () {
    for file in $@
    do
        if [[ -e $file ]]
        then
            echo "$file"
            cat $file
	    #while IFS="" read -r line
            #do
   	    #    echo "$line"
            #done <"$file"
	fi
    done
}

print_files "$offsite_file" "$retrieved_file"
bash tlim.sh -u "t.le" -p "123456" -tl kddi -o "removetape" -f "$offsite_file"
bash tlim.sh -u "t.le" -p "123456" -tl kddi -o "viewIO"

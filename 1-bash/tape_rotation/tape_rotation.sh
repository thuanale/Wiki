#!/usr/bin/bash
#===================================================================================
# #
#FILE: tape_rotation.sh
# #
#USAGE: bash tape_rotation.sh <AS400 ID>
#
# DESCRIPTION: Check & initialize new tapes/expire active tapes/reassign tapes
# in everyday's afternoon
# VERSION: 1.0
# CREATED: 26.10.2020 - 12:41:00
# REVISION: 04.11.2020
#==================================================================================
ER_NOINPUT=64

[[ -n "$@" ]] && user="$1" ||
	{
		echo "NO INPUT DATA!"		
		echo "USAGE: bash tape_rotation.sh <AS400 ID>"
		exit $ER_NOINPUT
	}
date_format="$(date +%d%m%y)"

#1.1/ Pathname of scripts which will be used
script="$(dirname "$0")"
check_assigned="$script/check_assigned.sh"
check_mlb_tapes="$script/check_mlb_tapes.sh"
initialize_tapes="$script/initialize_tapes.sh"
expire_tapes="$script/expire_tapes.sh"
reassign_tapes="$script/reassign_tapes.sh"

# 1.2/ Check & create directory if needed
dir="$HOME/NTT/$(date +%Y)/$(date +%m)"
[[ ! -d "$dir" ]] && mkdir -p "$dir"

# 1.3/ Define list of files will be used. 
active_file="$dir/ACTIVE_$date_format.txt"
assigned_file="$dir/ASSIGNED_$date_format.txt"
new_file="$dir/NEW_$date_format.txt"
missed_file="$dir/MISSED_$date_format.txt"
redundant_file="$dir/REDUNDANT_$date_format.txt"

# 1.4.1/ Querry files include list of active tapes which should be expired
ssh $user@INDO.DFS "system 'WRKMEDBRM TYPE(*ACT) VOL(*ALL) LOC(LTO5DRT) MEDCLS(ULTRIUM5)'" | 
					grep -v "*PERM" | 
					awk '/*NONE/ {printf("%-10d%10s\t",$1,$NF);system("date -d "$6" +%y%m%d");}' | 
					awk -v today="$(date -d yesterday +%y%m%d)" '{ if ($3 < today) print $1,$2,$3 }' \
					> "$active_file"

# 1.4.2/ Querry files include list of expire tapes has been assigned to each server
for SERVER in CAM CATS CLUX DFSNZ1 FRANCE GDC GVA HKGA HNL INDO ITL KOREA KSENV5U \
			KSENV6 KSENV6U LAX1 MIDEAST MIDPAC PAD1 PAX1 PRC SFO SFO2 SIN2 SYD
do 
    ssh "$user"@INDO.DFS "system \
						'WRKMEDBRM TYPE(*EXP) MEDCLS(ULTRIUM5) LOC(LTO5DRT) SYSNAME(APPN.'$SERVER')'" | 
						grep LTO5DRT | 
						grep -v Location
done > "$assigned_file"

# 1.4.3/ Querry files include list of new tapes which has been loaded into the media library
ssh $user@INDO.DFS "system 'WRKMLMBRM MLB(LTO5DRT) CGY(*INSERT)'" | 
					awk '/NONE/ { if ($1 ~ /^55[0-9]+$/) print $1 }' > "$new_file"

#####################################################
#2/ Check if assgined tapes are in media library
# Return: new assigned_file after removing unloaded tape or print "All tapes in load"
#####################################################
bash "$check_mlb_tapes" -u "$user" -f "$assigned_file" -l "ntt"

#####################################################
#3/ Check if assigned tapes are enough for each server
# Return: MISSED_<Date format>.TXT inlcudes servers than need more tape(s) & quantity
# REDUNDANT_<Date format>.TXT for server has more than enough & quantity
#####################################################
bash "$check_assigned" "$assigned_file"

#####################################################
#4/ Reassign/Exprire/Init Tape miss tape
#####################################################

if [[ -s "$missed_file" ]]
then
    missed_server=( $(awk '{printf("%s\n",$1)}' "$missed_file") )			#servers which are missed tapes
	missed=( $(awk '{printf("%d\n",$2)}' "$missed_file") )					#quantity of tapes are missed per server
    redundant_server=( $(awk '{printf("%s\n",$1)}' "$redundant_file") )		#servers which are redudant of tape
	redundant=( $(awk '{printf("%d\n",$2)}' "$redundant_file") )			#quantity of tapes are redundant per server
    for ((i=0;i<${#missed_server[@]};i++))
    do
        server=${missed_server[$i]}; 
        if [[ "${missed[$i]}" -gt "0" ]]
		then
#4.2/ Reassign tape from other redundant server
			if [[ -s "$redundant_file" ]]
			then
				echo "*** START RE-ASSIGN TAPES ***"
				for ((j=0;j<${#redundant_server[@]};j++))
		   		do
		   	    	sender=${redundant_server[$j]}  
		   	    	tape_list=( $(awk '/'$sender'$/ {printf("%d\n",$1)}' "$assigned_file") )
		   	    	echo ${tape_list[@]}
		   	    	for tape in ${tape_list[@]}
		   	 		do
						if [[ "${redundant[$j]}" -gt "0" ]]
	   			      	then
							echo "Reassign $tape from $sender to $server!"
	    		   	       	bash "$reassign_tapes" -u $user -s "$server" -t "$tape"
							(( missed[$i]-=1 ))
	     		        	(( redundant[$j]-=1 ))
							sed -i '/'$tape'/d' "$assigned_file"
							[[ "${redundant[$j]}" -eq "0" ]] && sed -i '/\<'$sender'\>/d' "$redundant_file"
	    		         	[[ "${missed[$i]}" -eq "0" ]] && continue 3  
						else 
							continue 2
	     		       fi
					done
				done
#4.2/ Initialize tape:
			elif [[ -s "$new_file" ]]
			then
				echo "*** START INITIALIZE NEW TAPES ***"
				new_tape=( $(cat "$new_file") )
	 			for ((j=0;j<${#new_tape[@]};j++))
				do
					tape="${new_tape[$j]}"
					echo "Initialize and assign $tape to $server."
					bash "$initialize_tapes" -u "$user" -t "$tape" -s "$server"
					unset new_tape[$j]
					sed -i '/'$tape'/d' "$new_file"
					(( missed[$i]-=1 ))
	 		      	[[ "${missed[$i]}" -eq "0" ]] && continue 3
				done
		
#4.3/ Expire active tape:
			elif [[ -s $active_file ]] 
			then
				echo "*** START EXPIRING TAPES ***"
				bash $expire_tapes -u $user -f $active_file
				echo "*** PLEASE WAIT THIS PROCESS DONE & RERUN YOUR SCRIPT AGAIN ***"
				break
			#4.4 Error
			else
				echo "RED ALERT! NOT ENOUGH TAPE FOR DAILY TASKS. PLEASE ESCALTE ASAP!" && break
			fi
		fi
	done
#5/ Remove all files but ASSIGNED_*
#5.1/ Expire leftover:
	
	if [[ -n "${new_tape[@]}" ]]
	then
		echo "*** START INITIALIZE REST NEW TAPES ***"
		bash "$initialize_tapes" -u "$user" -f "$new_file"
	fi

#5.2/ Creating new ASSIGNED_FILE
	echo "*** CREATING NEW ASSIGNED_FILE ***"
	for SERVER in CAM CATS CLUX DFSNZ1 FRANCE GDC GVA HKGA HNL INDO ITL KOREA KSENV5U KSENV6 KSENV6U LAX1 MIDEAST MIDPAC PAD1 PAX1 PRC SFO SFO2 SIN2 SYD
	do 
	    ssh "$user"@INDO.DFS "system 'WRKMEDBRM TYPE(*EXP) MEDCLS(ULTRIUM5) LOC(LTO5DRT) SYSNAME(APPN.'$SERVER')'" | grep LTO5DRT | grep -v Location; 
	done > "$assigned_file"
	bash "$check_mlb_tapes" -u "$user" -f "$assigned_file" -l "ntt"
fi
#Remove all files except ASSIGNED file(s)
echo "*** REMOVING TEMP FILES ***"
find "$dir" \( -type f ! -name "ASSIGNED_*" \) -and \( -type f ! -name "RETURN*" \) -delete;
echo "Please find new assigned in $dir"
echo "***FIN.***"

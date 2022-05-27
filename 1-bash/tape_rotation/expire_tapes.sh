#!/usr/bin/bash
#===================================================================================
# #
# FILE: expire_tapes.sh
# #
# USAGE1: bash expire_tapes.sh -u <AS400 uid> -f <active tape file>
# USAGE2: bash expire_tapes.sh -u <AS400 uid> -s <server> -t <volume id> -r <received server>
#
# DESCRIPTION: Expire active (*ACT) tape which is missed by the system somehow. 
# VERSION: 2.0
# CREATED: 26.10.2020 - 12:41:00
# REVISION: 20.11.2020
#==================================================================================

E_WRONG_INPUT=64

error() {
    echo "USAGE1: bash expire_tapes.sh -u <AS400 uid> -f <active tape file>" 
	echo "USAGE2: bash expire_tapes.sh -u <AS400 uid> -s <sender server> -t <volume id> -r <received server>"
	exit $E_WRONG_INPUT
}

expire() {
	echo "Expire tape $tape on $server"
	#DATE_FORMAT="$(ssh $user@$server.dfs "system 'DSPSYSVAL SYSVAL(QDATFMT)'" | 
	#	awk '/QDATFMT/ { print $3 }')"

	#DAY="$(ssh $user@$server.dfs "system 'DSPSYSVAL SYSVAL(QDAY)'" | awk '/QDAY/ {print $2}')"
	#MONTH="$(ssh $user@$server.dfs "system 'DSPSYSVAL SYSVAL(QMONTH)'" | awk '/QMONTH/ {print $2}')"
	#YEAR="$(ssh $user@$server.dfs "system 'DSPSYSVAL SYSVAL(QYEAR)'" | awk '/QYEAR/ {print $2}')"

	#[[ "$DATE_FORMAT" = "DMY" ]] && today="$(date -d "$(printf %d/%d/%d $MONTH $DAY $YEAR)" +%d/%m/%y)" ||
	#								today="$(date -d "$(printf %d/%d/%d $MONTH $DAY $YEAR)" +%m/%d/%y)"
	
	today="$(ssh $user@$server.dfs "system 'DSPSYSVAL SYSVAL(QDATE)'" | awk '/QDATE/ { print $2 }')"
	ssh $user@$server.dfs 'system "CHGMEDBRM VOL('$tape') EXPDATE('\'$today\'')"'
}

#List of required files
script=$(dirname "$0")
server_ip_file="$script/server.txt"
reassign_tapes="$script/reassign_tapes.sh"

#Check whether if user is not set. It also check whether both file and (server or tape) is not set.

if [[ "$#" = 0 ]]
then
	error
else
	while [[ "$#" -gt 0 ]]
	do
		case "$1" in
			-u) [[ -z "$2" ]] && error || user="$2";;
			-f) [[ -z "$2" ]] && error || file="$2";;
			-t) [[ -z "$2" ]] && error || tape="$2";;
			-s) [[ -z "$2" ]] && error || server="$2";;
			-r) [[ -z "$2" ]] && error || receiver="$2";;
			*)
				error
 	   		;;
		esac
		shift 2
	done
	[[ -z "$user" || ( ! -s "$file" &&  ( -z "$server"  || -z "$tape" )) ]] && error 
fi

#Check option and start
if [[ -n "$tape" ]] 
then
	expire 		#Expire specific tape
	[[ -n "$receiver" ]] && bash "$reassign_tapes" -u "$user" -t "$tape" -s "$receiver"
else
#Expire tapes based on active file.
#Beforehand, if server is down => echo "$server is down"
	while true
	do
		echo "List of tapes can be expired:"
		cat "$file"
		active_tape=( $(awk '{printf("%d\n",$1)}' "$file" ) )	
		read -p "Please enter one: " tape
		if [[ -n "$tape" && "${active_tape[@]}" =~ "$tape" ]] 
		then
			server="$(awk '/\<'$tape'\>/ {printf("%s\n",$2)}' "$file" 2>/dev/null)"
			ip="$(awk '/\<'$server'\>/ {print $2}' "$server_ip_file")"
			if ping -c 2 $ip &>/dev/null
			then
				expire
				sed -i '/'$tape'/d' "$file"
				read -p "Please enter server you want to assign to: " receiver
				[[ -n "$receiver" ]] && bash "$reassign_tapes" -u "$user" -t "$tape" -s "$receiver"
			else
				echo "$server is down & will be remove from the list."
				sed -i '/\<'$server'\>/d' "$file"
			fi
		else
			echo "Tape is not found or has been expired."
		fi

		while true
		do
			read -p "Do you want to continue (y/n)? " answer
			case "$answer" in
				"y"|"Y") 
					break
				;;
				"n"|"N")
					echo "*** Expring tape is done. ***"
					exit 0
				;;
				*) 
					echo "Please enter y (yes) or n (no) only!"
				;;
			esac
		done
	done
fi
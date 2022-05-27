#!/usr/bin/bash
#===================================================================================
# #
#FILE: check_mlb_tapes.sh
# #
#USAGE: bash check_mlb_tapes.sh -u <AS400 ID> -f <ASSIGNED/RETURN File> -l <NTT/KDDI>
#
# DESCRIPTION: Check if tape(s) is in media library.
# In case there is any changes, remove line which contains missed tape.
# CREATED: 26.10.2020 - 12:41:00
# REVISION: 30.10.2020
#===================================================================================

declare -a MLB_Tape
declare -a NOT_MLB_Tape

error() {
    echo "SYNTAX: bash "$0" -u <AS400 uid> -f <assigned tape file> -l <ntt/kddi>"
	exit 1
}

if [[ "$#" = 0 ]]
then
	error
else
	while [[ "$#" -gt 0 ]]
	do
	case $1 in
		-u) [[ -z "$2" ]] && error || user="$2";;
		-f) [[ -z "$2" ]] && error || file="$2";;
		-l) case "$2" in 
				"ntt"|"NTT") 
					server="INDO"
					media="LTO5DRT"
					;;
				"kddi"|"KDDI") 
					server="DRSAP2PF"
					media="TAPMLB09";;
				*) error;;
			esac
		;;
		*)
			error;;
	esac
	shift 2
	done
	[[ -z "$user" || ! -s "$file" || -z "$server" ]] && error
fi

#Get list of current tapes in media library 
MLB_Tape=( $(ssh "$user"@$server.dfs "system 'wrkmlmbrm mlb('$media') medcls(ultrium5)'" | awk '/ULTRIUM5/ {printf("%-6d\n",$1)}') )

#Check if assigned tapes are in media library
while IFS= read -r tape 
do
	[[ ! ${MLB_Tape[@]} =~ "$tape" ]] && { 
        NOT_MLB_Tape+=( "$tape" )
        sed -i '/'$tape'/d' "$file"
    }
done < <( awk '{printf("%-4d\n",$1)}' "$file" )

[[ -z ${NOT_MLB_Tape[@]} ]] && echo "All assigned tapes are in tape library!" || { 
    echo "Tapes are not in MLB: "
	printf "%d\n" "${NOT_MLB_Tape[@]}" 
    }

#!/usr/bin/bash
#===================================================================================
# #
#FILE: initialize_tapes.sh
# #
#USAGE1: bash initialize_tapes.sh -u <AS400 uid> -f <new tapes file>
#USAGE2: bash initialize_tapes.sh -u <AS400 uid> -s <server> -t <volume id>"
#
# DESCRIPTION: Initialize specific tape to a destination server or 
# initiliaze them to servers which have scheduled SAVARCC/ARCSPLF1 job
# VERSION: 1.1
# CREATED: 26.10.2020 - 12:41:00
# REVISION: 05.11.2020
#==================================================================================

#Produce error when input data is not set properly
error() {
    E_DATA_ERR="64"
	echo "USAGE1: bash initialize_tapes.sh -u <AS400 uid> -f <new tapes file>"
	echo "USAGE2: bash initialize_tapes.sh -u <AS400 uid> -s <server> -t <volume id>"
	exit $E_DATA_ERR
}
########################################################
#Initialize a tape & assign to a server
#This task should be done on INDO.
#Benefit: easy to control in case needed servers is down
########################################################
initialize() {
	echo "Initialiaze & assign $tape to $server."
	ssh "$user"@indo.dfs 'system "ADDMLMBRM MLB(LTO5DRT) VOL('$tape') INZ(*YES) MEDCLS(ULTRIUM5) CHECK(*NO)";
								system "CHGMEDBRM VOL('$tape') SYSNAME(APPN.'$server')"'
}

#Check input data
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
		*)
			error
 	   ;;
	esac
	shift 2
	done
	[[ -z "$user" || ( ! -s "$file" &&  ( -z "$server"  || -z "$tape" )) ]] && error
fi

#Check if tape is specified, then assign it to input server
#Else assign them randomly to servers which have scheduled SAVARCC/ARCSPLF1 job
if [[ -n "$tape" ]]
then
	initialize
else
	new_tape=( $( cat "$file" ) )
	quantity="${#new_tape[@]}"
	until [[ "$i" -eq "$quantity" ]]
	do
		for server in GDC HKGA HNL LAX1 MIDEAST MIDPAC PRC SIN2 SYD
		do
			tape="${new_tape[$i]}"
			initialize
			sed -i '/'$tape'/d' "$file"
			((i++))
			[[ "$i" -eq "$quantity" ]] && {
				echo "All tapes have been initialized!"
				break 2
			}
		done
	done
fi

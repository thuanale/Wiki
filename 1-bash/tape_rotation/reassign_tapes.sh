#!/usr/bin/bash

error() {
    echo "SYNTAX: bash reassign_tapes.sh -u <AS400 uid> -t <active tape file> -s <server> "
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
		-t) [[ -z "$2" ]] && error || tape="$2";;
		-s) [[ -z "$2" ]] && error || server=$2;;
		*)
			error
 	   ;;
	esac
	shift 2
	done
	[[ -z "$user" || -z "$server"  || -z "$tape" ]] && error
fi
ssh "$user"@indo.dfs 'system "CHGMEDBRM VOL('$tape') SYSNAME('$server')"'

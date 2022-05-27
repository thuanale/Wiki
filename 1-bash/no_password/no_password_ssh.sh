#!/usr/bin/bash
#===================================================================================
# #
#FILE: no_PASSWORD_ssh.sh
# #
#USAGE: bash no_PASSWORD_ssh.sh -u <AS400 ID> -p <PASSWORD> -f <public key FILE> [-s <server> ]"
#
# DESCRIPTION: Create home folder, upload pubic key FILE, & set permission for specific server/all AS400 servers
# In case there is any changes, remove line which contains missed tape.
# CREATED: 08.Jul.2020 - 12:41:00
# REVISION: 30.Oct.2020
#===================================================================================
ER_BAD_ARGS=64
error() {
	echo "$@"
	echo "USAGE: bash "$(basename $0)" -u <AS400 ID> -p <PASSWORD> -f <public key FILE> [-s <server> ]"
	exit $ER_BAD_ARGS
}

if [[ "$#" = 0 ]]
then
	error "No input!"
else
	while [[ "$#" -gt 0 ]]
	do
		case "$1" in
			-u) [[ -z "$2" ]] && error "No username!" || {
					USER="$2"
					HOME_FOLDER="/home/$USER" 
			}
				;;
				
			-p) [[ -z "$2" ]] && error "No password!" || PASSWORD="$2" ;;
				
			-f) [[ -z "$2" ]] && error "No public key file." || FILE="$2"
				;;
				
			-s) [[ -z "$2" ]] && error "No server" || SERVER_LIST=( $2 )
				;;
			*)
				error "Invalid options."
				;;
		esac
		shift 2
	done
	[[ -z "$USER" || -z "$PASSWORD" || ! -s "$FILE" ]] && error "Oops!"
fi

upload_and_run()
{
	expect -c "
		spawn ssh "$USER"@"$server".dfs \"mkdir "$HOME_FOLDER"; chmod g-rwr,o-rwx "$HOME_FOLDER"; mkdir "$HOME_FOLDER"/.ssh; chmod g-rwr,o-rwx "$HOME_FOLDER"/.ssh\"
		expect {
		\"(yes/no)?\" { send \"yes\r\"; expect \"password:\"; send \"$PASSWORD\r\" }
		\"password:\" { send \"$PASSWORD\r\"}
		}
		interact
		"

	#copy FILE to folder
	expect -c "
		spawn scp "$FILE" "$USER"@"$server".dfs:"$HOME_FOLDER"/.ssh
		expect {
			\"password:\" { send \"$PASSWORD\r\" }
		}
		interact
	"	
}

if [[ -n "$SERVER_LIST" ]]
then
	for server in ${SERVER_LIST[@]}
	do
		upload_and_run
	done
else
	for server in CAM CATS CLUX DFSNZ1 DFSDEVD DRCAM DRCATS DRCLUX DRDFSNZ1 DRGDC DRGVA DRHKGA DRHNL DRINDO DRITL DRKOREA DRLAX1 DRMIDEST DRMIDPAC DRPAD1 DRPAX1 DRPRC DRSAP2PF DRSFO2 DRSIN2 DRSYD FRANCE GDC GVA HKGA HNL INDO ITL KOREA KSENV5U KSENV6 KSENV6U LAX1 MIDEAST MIDPAC PAD1 PAX1 PRC SAP2PFS SFO SFO2 SIN2 SYD
	do
		upload_and_run
	done
fi
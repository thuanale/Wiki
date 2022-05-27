#!/usr/bin/bash
#===================================================================================
# #
#FILE: crown_account_check.sh
# #
#USAGE: bash crown_account_check.sh <AS400 uid>
#
# DESCRIPTION: Check status of tapes in system & compare with its status at CROWN
# Produce list of tapes need to change account code.
# For Tape.txt: Please go to Crown to export all tapes under RD1005C - RD1066C account
# VERSION: 1.0
# CREATED: 04.01.2020 - 23:18:00
#==================================================================================
ER_BAD_INPUT=64
ER_NO_ARGS=65

error(){
  ER_CODE=$1
  case $ER_CODE in 
  64)
    echo "NO SPECIFIED AS400 ID" 
    exit $ER_BAD_INPUT
    ;;
  65) 
    echo "NO AVAIBLE TAPE.TXT FILE IN CURRENT FOLDER"
    exit $ER_NO_ARGS
    ;;
  esac
}

[[ -z $@ ]] && error 64 || USER_ID="${1^^}"

DIRECTORY="$HOME/CROWN/$(date +%Y)/$(date +%m)/"
[[ ! -d "$DIRECTORY" ]] && mkdir -p "$DIRECTORY"

CROWN_FILE="$HOME/TAPE.TXT"
[[ ! -s "$CROWN_FILE" ]] && error 65

CROWN_MODIFIED="$DIRECTORY/CROWN_MODIFIED.TXT"
PRTMOVRPT="$DIRECTORY/PRTMOVPRT.TXT"
FINAL="$DIRECTORY/FINAL.TXT"


#1. Modify Tape.txt (which get from CROWN): sorted, uniq (remove duplicate tape by comparing year)
awk -F, '/RD10.*55[0-9]{4}.*(In|[^Perm ]Out)/ {printf("%-8d%-10s\t",$3,$1);system("date -d "$5" +%F")}' "$CROWN_FILE" | sed -E 's/(A|L[4-7][A]?)//g' | sort -k1,1nr -k3,3r >"$CROWN_MODIFIED"
#2. Modify movement report which gets from INDO
ssh "$USER_ID"@INDO.DFS 'system "PRTMOVBRM LOC(LTO5DRT)"' | awk '/55[0-9]{4}.*MOVDRT.*NONE/ {printf("%-8d%-10s\n",$1,$4)}' | sed -E 's/MOVDRT(1YR|4WK)/RD1005C/g; s/MOVDRT(7|10)YR/RD1066C/g' | sort -k1,1n > "$PRTMOVRPT"
#compare & final.
printf "%-8s%-10s\n" TAPE ACCOUNT > "$FINAL"
while IFS= read -r LINE
do
  read tape account <<< $LINE
  crown_account=$(awk '/'$tape'/ {print $2}' "$CROWN_MODIFIED" | head -1)
  if [[ -n "$crown_account" && "$account" != "$crown_account" ]] 
  then
	printf "%-8d%-10s\n" "$tape" "$account" >> "$FINAL"
  fi
done < "$PRTMOVRPT"

echo "There are $(wc -l < "$FINAL") need to change account code."

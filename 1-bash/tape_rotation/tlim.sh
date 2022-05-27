#!/usr/bin/env bash

#############################################################################
#SCRIPT NAME: TLIB IMPROVED <TLIM>					    #
#USAGE: bash tlib.sh -u <UID> -p <PW> -tl <TL> -o <OPT>  -f <FILE>	    #
#OPTION:								    #
#    <UID> : TLIB USERID		 				    #
#    <PW>  : TLIB PASSWORD						    #
#    <TL>  : TLIB LOCATION						    #
#    <OPT> :								    #
#            removeTapes						    #
#    	     viewAllTapes						    #
#    	     viewIO							    #
#	     viewSystemSummary  					    #
#	 <FILE>: Path to file <mandatory when OPT is removeTapes	    #
#AUTHOR: THOMAS LE        						    #
#VERSION: 1.0             						    #
#LAST UPDATE: 17-MAR-2021						    #
#############################################################################

error(){
    ERR_CODE="$1"
    case "$ERR_CODE" in
    INVALID_INPUT)
        echo "USAGE: bash tlib.sh -u <UID> -p <PW> -tl <TL> -o <OPT>  -f <FILE>"
    	echo "    <UID> : TLIB USERID"
	echo "    <PW>  : TLIB PASSWORD"
	echo "    <PW>  : TLIB PASSWORD"
	echo "    <TL>  : TLIB LOCATION"
	echo "    <OPT> :"
	echo "            removeTapes"
	echo "            viewAllTapes"
	echo "            viewIO"
	echo "            viewSystemSummary"
	echo "    <FILE>: Path to file <mandatory when OPT is removeTapes"
    	exit 64
    	;;

    FILE_NOT_EXIST)
	    echo "File not existed or 0 size"
        exit 65
        ;;
 
    *)
	    return 0
	    ;;
        
    esac
}

if [[ -z "$*" ]]
then
	USER="t.le"
	PW="123456"
	TL="NTT"
	OPT="viewsystemstatus"
fi

while (( $# > 1 ))
do
    case "$1" in
        -o) 
	    OPT="${2,,}";;
	-tl)
	    TL="${2^^}";;
	-f)
	    FILE="$2";;
	-u)
	    USER="$2";;
	-p) 
	    PW="$2";;			
	*)
	    error "INVALID_INPUT";;
    esac
    shift 2
done

if [[ -z "$TL" || -z "$USER" || -z "$PW" || -z "$OPT" ]]
then
    error "INVALID_INPUT"
fi

case "$TL" in
    NTT)
        IP="10.176.232.45";;
    
    KDDI)
        IP="10.176.34.102";;
    
    *)
        error "INVALID_INPUT";;
esac
	
case "$OPT" in
viewio)
    EXT="--viewIoStation";;
	
removetapes)
    if [[ -e "$FILE" ]]
    then
        error "FILE_NOT_EXIST"
    else
	EXT="--removeDataCartridges $FILE"
    fi
    ;;
	
viewalltapes)
    EXT="--viewDataCartridges";;
		
viewsystemstatus)
    EXT="--viewSystemSummary";;
		
*)
    error "INVALID_INPUT";;
esac

java -jar /home/shared/bin/TS3500CLI.jar -a "$IP" -u "$USER" -p "$PW" "$EXT"

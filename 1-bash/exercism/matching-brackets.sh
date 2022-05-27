#!/usr/bin/env bash

declare -A brackets
brackets[']']='['
brackets['}']='{'
brackets[')']='('

string=${1}
string_len=${#string}
declare -a couple
reg='([|{|()'

for ((i=0;i<string_len;i++)); do
   char=${string:i:1}
   [[ $char =~ $reg && $i -lt $string_len ]] && couple+=( $char ) && continue;
   [[ -z $couple ]] && echo false && exit;
   [[ ${brackets[$char]} = ${couple[-1]} ]] && unset couple[-1] && continue; 
   echo false
   exit   
done

echo true

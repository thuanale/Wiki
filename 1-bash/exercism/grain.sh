#!/usr/bin/env bash
start_time=$(date +%s)
sum=0
square=${1}
squares=${2}
point=1

for ((i=1;i<=squares;i++));do
   sum=`echo $sum + $point | bc -l`
   (( i == square )) && echo "$point grains at $i"
   point=`echo $point * 2 | bc -l`
done

echo $sum
end_time=$(date +%s)

echo "run time: " $((end_time - start_time))

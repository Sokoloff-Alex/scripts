#!/bin/bash
#
# get availability of RINEX data in pseudographics
#
# 

inputfile=$1
sort $inputfile -k1.10 -k1.5 > list_file_tmp
input_file="list_file_tmp"


# get hames as header
cat $inputfile | cut -c1-4 | sort | uniq > names

length=$(cat names | wc -l )

rm -f numbers
rm -f spaces

for((i=1; i<=$length; i++))
do
	echo "$i" | awk '{printf "%03d\n", $1}' >> numbers
	echo -n ' ' >> spaces
done

echo ' ' >> spaces

echo '### Number ###' > t
cat numbers | cut -c1 | tr -d "\n" >> t
echo "" >> t
cat numbers | cut -c2 | tr -d "\n" >> t
echo "" >> t
cat numbers | cut -c3 | tr -d "\n" >> t
echo "" >> t
echo "### Station ID ###" >> t
cat names   | cut -c1 | tr -d "\n" >> t
echo "" >> t
cat names   | cut -c2 | tr -d "\n" >> t
echo "" >> t
cat names   | cut -c3 | tr -d "\n" >> t
echo "" >> t
cat names   | cut -c4 | tr -d "\n" >> t
echo "" >> t
echo "### Availability ###" >> t

echo "cat spaces " > job
echo "$length" | awk '{printf "| sed -r -e  \x27s/^.{%d}/&-/\x27  ", $1+4}'> job3

startYY=$(head -1 $inputfile | cut -c10-11)
endYY=$(  tail -1 $inputfile | cut -c10-11)

# parse list to plot availability
for((YY=$startYY; YY<=$endYY; YY++))
do {
	for((ddd=1;ddd<=366; ddd++))
	do {
		pattern=$(echo "$ddd $YY " | awk '{printf "%03d0.%02d", $1, $2}')	
		grep "$pattern" $inputfile | cut -c1-4 > tmp 
		grep -f tmp names --line-number | cut -d ':' -f1 | awk '{printf "| sed -r -e  \x27s/^.{%d}/&X/\x27  ", $1}' > job2
		paste job job2 job3 > job4
		cat job4 | sh | cut -c2-$(($length + 1)) > line
		num_occurrences=$(grep -o 'X' line | wc -l)
		echo "$num_occurrences $YY $ddd" | awk '{printf "%4d : 20%02d %03d", $1 , $2, $3}' > date_time
		paste line date_time > new_line
		cat new_line >> t
	} done
	cat spaces >> t
} done

# rm job job2 job3 job4  tmp line spaces numbers

cp t "$inputfile""_avaliability_table"

gedit $inputfile"_avaliability_table" &



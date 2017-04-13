#!/bin/bash
#
# Script to search for missing RINEX files in the Datapool ($D/RINEX/) and available on the FTP server
# Command:
# 	./search_missing_RINEX_2 inputfile ftp_dir GPSWeekStart [GPSWeekEng]
#
# Example :
# 	./search_missing_RINEX_2 list_IGS 1773 1896
#
# Alexandr Sokolov, KEG
# 10.05.2016


echo "DATAPOOL: $D"

rm -f list_in_DP
rm -f list_No_DP
rm -f list_probable
rm -f list_missing_rnx

list_sites=$1
GPSWeekStart=$2
GPSWeekEnd=$3


if (( $# == 2))
then
	GPSWeekEnd=$GPSWeekStart
fi

#find /VENUS/GPSDATA/ALPEN/DATAPOOL/RINEX/  -name "*D.Z" | xargs -n 1 basename > list_in_DP


while read site
do {
	for(( GPSWeek=GPSWeekStart; GPSWeek<=$GPSWeekEnd; GPSWeek++ ))
	do {
		for(( wd=0; wd<=6; wd++ ))
		do {
			date=$( ~/bin/gps_date -wd $GPSWeek $wd  -o "%Y %y %j")
			yyyy=$(echo "$date" | cut -f1 -d' ')
			yy=$(  echo "$date" | cut -f2 -d' ')
			ddd=$( echo "$date" | cut -f3 -d' ')
			echo "$site$ddd"0."$yy"d.Z >> list_probable
		} done
	} done

	## make faster scan of DP
	SITE=${site^^}
	#ls -1  $D/RINEX/$SITE*D.Z | xargs -n 1 basename > list_in_DP
	find $D/RINEX/  -name "$SITE*D.Z" | xargs -n 1 basename > list_in_DP
	grep --ignore-case --invert-match --file list_in_DP list_probable > list_No_DP
	cat list_No_DP >> list_missing_rnx
	rm list_probable
} done < $list_sites

# gedit list_missing_rnx &

#rm -f list_in_DP
#rm -f list_No_DP
#rm -f list_probable



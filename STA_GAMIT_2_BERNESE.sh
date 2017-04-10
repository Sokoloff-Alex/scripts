#!/bin/bash
#
# ScriptConverting GAMIT_station.info into Bernese format "*.STA"
#
# ./STA_GAMIT_2_BERNESE.sh InputFile [-options]
# 
# inputFile  (example) :   GAMITstation.info         : Station information file in GAMIT format
# outputFile (example) :   GAMITstation.info.STA     : Station information file in BERNESE format
# 
# Options:
#    -sw      : skip Receiver firmware changes
#  
# example (converting file and ignoring firmware changes):
#
#   ./STA_GAMIT_2_BERNESE.sh inputFile -sw
#
#
# Alexandr Sokolov
# 15.12.2015

inputFile="$1"
outputFile="$inputFile.STA"
flag="001"
REMARK='ORPHEON Fr., RENAG GNSS GSAC'
date_time=$(gps_date -t -o "%d-%B-%Y %H:%M")


echo "
Converting $inputFile into Bernese format $outputFile"

echo "ORPHEON Network, conv. STA_GAMIT2BERNESE.sh; BSW VERSION 5.2;  $date_time" > $outputFile
echo "--------------------------------------------------------------------------------

FORMAT VERSION: 1.01
TECHNIQUE:      GNSS

TYPE 001: RENAMING OF STATIONS
------------------------------

STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************" >> $outputFile


tail -n +6 $inputFile > GAMIT.STA
more GAMIT.STA | cut --characters=2-5 | uniq > stat_list

while read SITE
do {
    line=$(grep "$SITE" GAMIT.STA | head -1)

	YY_start=$(echo "$line" | cut --characters=26-29 )
	DOY_start=$(echo "$line" | cut --characters=31-33 )
	hh_start=$(echo "$line" | cut --characters=35-36 )
	mm_start=$(echo "$line" | cut --characters=38-39 )
	ss_start=$(echo "$line" | cut --characters=41-42 )	

	MM_start=$(gps_date -yd $(echo "$YY_start $DOY_start" | awk '{printf"%4d %03d", $1, $2}') -o  "%m")
	dd_start=$(gps_date -yd $(echo "$YY_start $DOY_start" | awk '{printf"%4d %03d", $1, $2}') -o  "%d")
	
	echo "$SITE $SITE             $flag  $YY_start $MM_start $dd_start $hh_start $mm_start $ss_start  2099 12 31 00 00 00  $SITE*                 ORPHEON, Fr.            " >> $outputFile

} done < stat_list

#SITE  Station Name      Session Start      Session Stop       Ant Ht   HtCod  Ant N    Ant E    Receiver Type         Vers                  SwVer  Receiver SN           Antenna Type     Dome   Antenna SN
#ALLE  ALLE              2011 345 19 00 00  2014  98 08 26 44   0.0000  -----   0.0000   0.0000  LEICA GRX1200+GNSS    8.10/4.007             8.10  496671                LEIAS10          NONE   UNKNOWN             
#VIGY  VIGY              2011 301 10 00 00  2015 344 14 09 18   0.0000  -----   0.0000   0.0000  LEICA GRX1200+GNSS    8.20/4.007             8.20  495809                LEIAX1203+GNSS   NONE   UNKNOWN             


echo " 

TYPE 002: STATION INFORMATION
-----------------------------

STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************" >> $outputFile

while read line 
do {
	SITE=$(echo "$line" | cut --characters=1-4 )
	Description=$(echo "$line" | cut --characters=7-22 )
	YY_start=$(echo "$line" | cut --characters=25-28 )
	DOY_start=$(echo "$line" | cut --characters=30-32 )
	hh_start=$(echo "$line" | cut --characters=34-35 )
	mm_start=$(echo "$line" | cut --characters=37-38 )
	ss_start=$(echo "$line" | cut --characters=40-41 )
	YY_end=$(echo "$line" | cut --characters=44-47)
	DOY_end=$(echo "$line" | cut --characters=49-51 )
	hh_end=$(echo "$line" | cut --characters=53-54 )
	mm_end=$(echo "$line" | cut --characters=56-57 )
	ss_end=$(echo "$line" | cut --characters=59-60 )
	Ant_Ht=$(echo "$line" | cut --characters=64-70 )
	Ant_N=$(echo "$line" | cut --characters=80-86 )
	Ant_E=$(echo "$line" | cut --characters=89-95 )
	Rec_Type=$(echo "$line" | cut --characters=97-117 )
	Rec_Vers=$(echo "$line" | cut --characters=119-140 )
	Rec_SwVer=$(echo "$line" | cut --characters=142-146 )
	Rec_SN=$(echo "$line" | cut --characters=148-168 )
	Ant_Type=$(echo "$line" | cut --characters=170-185 )
	Ant_DOME=$(echo "$line" | cut --characters=187-190 )
	Ant_SN=$(echo "$line" | cut --characters=194-204 )

	# echo "$SITE $Description $YY_start,$DOY_start,$hh_start,$mm_start,$ss_start,$YY_end,$DOY_end,$hh_end,$mm_end,$ss_end,$Ant_Ht,$Ant_N,$Ant_E,$Rec_Type,$Rec_Vers,$Rec_SwVer,$Rec_SN,$Ant_Type,$Ant_DOME,$Ant_SN"

	# convert date from "YYYY DoY" to "YYYY MM DD" 
	MM_start=$(gps_date -yd $(echo "$YY_start $DOY_start" | awk '{printf"%4d %03d", $1, $2}') -o  "%m")
	dd_start=$(gps_date -yd $(echo "$YY_start $DOY_start" | awk '{printf"%4d %03d", $1, $2}') -o  "%d")

	MM_end=$(gps_date -yd   $(echo "$YY_end   $DOY_end"   | awk '{printf"%4d %03d", $1, $2}') -o  "%m")
	dd_end=$(gps_date -yd   $(echo "$YY_end   $DOY_end"   | awk '{printf"%4d %03d", $1, $2}') -o  "%d")

	if [ "$Ant_DOME" = "----" ]
	then
		Ant_DOME="NONE"					
	fi
		
	Ant_SN=$( echo "$Ant_SN" | sed 's/ *//g')
	if (( "$Ant_SN" == "UNKNOWN" || "$Ant_SN" == "Unknown" || "$Ant_SN" == "unknown" ))
	then
		Ant_SN="999999"					
	fi

	Rec_SN_short="999999"	
	Ant_SN_short="999999"

	#if (( $(echo ${#Rec_SN}) < 6 ))
	#then
	#	Rec_SN_short=$Rec_SN
	#else
	#	Rec_SN_short=$(echo ${Rec_SN:(-6)})
	#fi 
	#
	#if (( $( echo ${#Ant_SN}) < 6 ))
	#then
	#	Ant_SN_short=$Ant_SN	
	#else
	#	Ant_SN_short=$(echo ${Ant_SN:(-6)}) 
	#fi
	
	format=( "%4s" " %-10s" "       %03d"    "  %4d"    " %2s"    " %2s"    " %2s"    " %2s"    " %2s" "  %4d"  " %2s"  " %2s"  " %2s"  " %2s"  " %2s"          "  %-20s"            "  %-20s"      "  %6s"             "  %-15s"    " %4s"            "  %20s"       "  %6s" "  %8s"  "  %8s" "  %8s"        "  %-22s"           '  %-24s \n')
	records=($SITE    $SITE         $flag  $YY_start $MM_start $dd_start $hh_start $mm_start $ss_start $YY_end $MM_end $dd_end $hh_end $mm_end $ss_end "$(echo $Rec_Type)"   "$(echo $Rec_SN)" "$Rec_SN_short" "$(echo $Ant_Type)" $Ant_DOME   "$(echo $Ant_SN)" $Ant_SN_short  $Ant_N   $Ant_E $Ant_Ht "$(echo $Description)" "$(echo $Rec_Vers)")


	# print to file
	for ((i=0; i<=27; i+=1)); 
	do { 	
		# echo "${format[$i]} ${records[$i]}"
	    # printf "${format[$i]}" "${records[$i]}" >> $outputFile
		printf "${format[$i]}" "${records[$i]}" >> type2Table
	} done

} done < GAMIT.STA


### Ignore Receiver Firmware changes

if [ "$2" == "-sw" ]
then
	more type2Table | cut --characters=-4 | uniq > newList
	while read SITE
	do {	
		grep $SITE type2Table > tableSite
		for ((i=1; i<=$(grep -c $SITE tableSite); i+=1)); 
		do {
			grep "$(head $(echo "-$i") tableSite | tail -1 | cut --characters=70-202)" tableSite > tableSiteCommon
			echo "$( head -1 tableSiteCommon | cut --characters=-47)" "$(tail -1 tableSiteCommon | cut --characters=49-226 )"  "$REMARK" >> tableReducedNew
		} done	
	} done < newList

	more tableReducedNew | uniq  >> $outputFile
else
	more type2Table >> $outputFile
fi

rm GAMIT.STA
rm stat_list
rm tableReducedNew
rm newList
rm type2Table
rm tableSite
rm tableSiteCommon


echo "

TYPE 003: HANDLING OF STATION PROBLEMS
--------------------------------------

STATION NAME          FLG          FROM                   TO         REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ************************************************************


TYPE 004: STATION COORDINATES AND VELOCITIES (ADDNEQ)
-----------------------------------------------------
                                            RELATIVE CONSTR. POSITION     RELATIVE CONSTR. VELOCITY
STATION NAME 1        STATION NAME 2        NORTH     EAST      UP        NORTH     EAST      UP
****************      ****************      **.*****  **.*****  **.*****  **.*****  **.*****  **.*****


TYPE 005: HANDLING STATION TYPES
--------------------------------

STATION NAME          FLG  FROM                 TO                   MARKER TYPE           REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************

" >> $outputFile

echo "Done"


gedit $outputFile &



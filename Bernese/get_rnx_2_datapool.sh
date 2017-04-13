#!/bin/bash
#
#
# load RINEX files to the datapool

current_week=$(gps_date -t -o "%W");
last_week=$(($current_week - 1 ))


# load RINEX files for ALP_NET network

get_ALP_NET_rnx $last_week 
get_ALP_NET_rnx $current_week

get_SAPOS_rnx   $last_week 
get_SAPOS_rnx   $current_week

cd $D/RINEX/
rename_to_UPPER_CASE

cd /home/AlpenCheck/MISSING_RINEX/

# search datapool for missing RINEX files
/home/gnssuser1/AlpenCheck/MISSIN_RINEX/search_missing_RINEX_2.sh /home/gnssuser1/AlpenCheck/MISSIN_RINEX/list_ALP_NET $last_week $current_week

# download missing RINEX files
/home/gnssuser1/AlpenCheck/MISSIN_RINEX/download_missing_rnx.sh /home/gnssuser1/AlpenCheck/MISSIN_RINEX/list_missing_rnx








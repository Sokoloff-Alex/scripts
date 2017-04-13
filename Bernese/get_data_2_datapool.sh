#!/bin/bash
#
#
# load weekly data to the datapool

current_week=$(gps_date -t -o "%W");
prelast_week=$(($current_week - 2 ))

# load EPH (daily) and ERP (weekly)
/home/gnssuser1/bin/get_code2Data $prelast_week

# load DCB
/home/gnssuser1/bin/get_code2BSW52 $prelast_week


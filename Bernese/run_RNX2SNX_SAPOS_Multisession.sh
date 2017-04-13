#!/bin/bash
#
# Run Bernese 5.2 in Non-interactive mode with RNX2SNX strategy
# for list of sessions from taken lile ($sessions_file in format yyyy ssss #comments...). 
#
# Processing of sessions is sequential.
#
# For defining correct BPE_CAMPAIGN and TASK_ID see ${U}/SCRIPT/rnx2snx_pcs_SAPOS.pl
# 
# The variables for strategy (PCF) must be updated manually in file ${U}/PCF/RNX2SNX.PCF
# (because the perl module runBPE.pm overwrites the "${U}/PAN/RUNBPE.INP" file with deafaults)
#
# example :
# 	./run_RNX2SNX_SAPOS_Multisession (sessions_file (yyyy ssss #comments...))
#
# Alexandr Sokolov, KEG
# 25.04.2016


echo "";
echo 'Run Bernese 5.2 in Non-interactive mode with RNX2SNX strategy for list of sessions';
echo "";

sessions_file=$1

while read line 
do	
	yyyy=$(echo "$line" | cut --characters=1-4)
	ssss=$(echo "$line" | cut --characters=6-9)
	#echo "$line"
	echo "Start processing : $line"
	echo "perl $U/SCRIPT/rnx2snx_pcs_SAPOS.pl" "$yyyy" "$ssss" 
	perl $U/SCRIPT/rnx2snx_pcs_SAPOS.pl "$yyyy" "$ssss"
	
	# save logs
	grep --before-context=2 --after-context=1 'PID_SUB     ' $P/SAPOS/BPE/SAPOS.OUT >> SAPOS_X_BPE.OUT
	grep Session $P/SAPOS/BPE/SAPOS.RUN >> SAPOS_X_BPE.RUN

	# clean memory to avoid overflow ::  1 day ~= 1 Gb
	echo "clean memory in $P/RAW and $P/OBS" 
	rm $P/SAPOS/RAW/*
	rm $P/SAPOS/OBS/*
	

done < $sessions_file #(format : yyyy ssss)

echo "Done"

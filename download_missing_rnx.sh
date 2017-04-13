#!/bin/bash
#
# try to download missing rinex fro ftp servers
#

list_missing_rnx=$1

echo DATAPOOL: $D

echo "
# EUREF (EPN)
ftp://igs.bkg.bund.de/EUREF/obs

# IGS
ftp://igs.bkg.bund.de/IGS/obs

# EPN (EUREF)
ftp://epncb.oma.be/pub/obs

# RENAG
ftp://renag.unice.fr/data_30s_v2
# ftp://webrenag.unice.fr/data_30s_v2

# RGP (incl RENAG) / IGN
ftp://rgpdata.ensg.ign.fr/pub/data
ftp://rgpdata.ign.fr/pub/data

# FRedNet
ftp://www.crs.inogs.it/pub/gps/rinex

# RING
ftp://gpsfree.gm.ingv.it/OUTGOING/RINEX30/RING

# GREF
ftp://igs.bkg.bund.de/GREF/obs

# OLG (Austria)
ftp://olggps.oeaw.ac.at/pub

# IGS
ftp://geodaf.mt.asi.it/GEOD/GPSD/RINEX

# IGS
ftp://igs.ensg.ign.fr/pub/igs/data
" > list_ftp_servers

# exclude comments and blank lines
more list_ftp_servers | grep -v '#\|^$' > list_ftp_servers_short

while read RNX_file_name
do { 
rnx_file_name=$( echo $RNX_file_name | awk '{printf "%s.Z", tolower(substr($1,1,12))}' )
	while read ftp_adr
	do {
		if [ ! -f $RNX_file_name ]; then
			file_adr=$(	echo $rnx_file_name $ftp_adr | awk '{printf "%s/20%02d/%03d/%s  \n", $2, substr($1,10,2), substr($1,5,3), $1 }' )
			wget -nv -N --timeout=10 $file_adr
			if [ -f $rnx_file_name ]; then
				mv -f  -- "$rnx_file_name" "${rnx_file_name^^}"
			#else
				# file_ADR=$(	echo $RNX_file_name $ftp_adr | awk '{printf "%s/20%02d/%03d/%s  \n", $2, substr($1,10,2), substr($1,5,3), $1 }' )
				# wget -nv -N $file_ADR
			fi
		fi
	} done < list_ftp_servers_short

	# only in # EPN (EUREF) ftp://epncb.oma.be/pub/obs filenames in UPPER_CASE
	if [ ! -f $RNX_file_name ]; then
		file_ADR=$(	echo $RNX_file_name | awk '{printf "ftp://epncb.oma.be/pub/obs/20%02d/%03d/%s  \n", substr($1,10,2), substr($1,5,3), $1 }' )
		wget -nv -N --timeout=10 $file_ADR
	fi

	# in ftp.geodesia.ign.es/ filename AAAA1230.45d.Z
	if [ ! -f $RNX_file_name ]; then
		file_ADR=$(	echo $RNX_file_name | awk '{printf "ftp.geodesia.ign.es/euref/obs/20%02d/%03d/%sd.Z  \n", substr($1,10,2), substr($1,5,3), substr($1,1,11) }' )
		wget -nv -N --timeout=10 $file_ADR
	fi

	if [ ! -f $RNX_file_name ]; then
		file_ADR=$(	echo $RNX_file_name | awk '{printf "ftp.geodesia.ign.es/igs/obs/20%02d/%03d/%sd.Z  \n", substr($1,10,2), substr($1,5,3), substr($1,1,11) }' )
		wget -nv -N --timeout=10 $file_ADR
	fi

} done < $list_missing_rnx

# rename RINEX to upper case
rename_to_UPPER_CASE

ls -1 *D.Z >> list_found
mv /home/gnssuser1/AlpenCheck/MISSIN_RINEX/*D.Z $D/RINEX/.









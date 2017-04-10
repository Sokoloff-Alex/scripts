#!/usr/bin/python

import os
import sys
if sys.version_info < (2, 6):
	sys.exit("must use python 2.6 or greater")

from ftplib import FTP

' Config '
basedir = "/BEK149/GNSS_DATA/EUREF/"

if not os.path.isdir(basedir):
	print "Der Zielpfad "+basedir+" existiert nicht."
	sys.exit(0)
	
year = None
day = None
stations = []

if len(sys.argv) != 4 and len(sys.argv) != 5:
	print "USAGE: download.py -Y<year> -D<day> -S<station>"
	print "       download.py -Y<year> -D<day> -L<list of stations>"
	print "       download.py -Y<year> -D<day> -S<station> -L<list of stations>"
	sys.exit(256)

for arg in sys.argv:
	if arg[0:2] == "-Y":
		year = arg[2:]
	if arg[0:2] == "-D":
		day = arg[2:]
	if arg[0:2] == "-S":
		stations.append(arg[2:])
	if arg[0:2] == "-L":
		input = open(arg[2:])
		for line in input:
			line = line.replace("\n","")
			stations.append(line)

if year == None:
	print "Year does not exist!"
	sys.exit(256)

if day == None:
	print "Day does not exist!"
	sys.exit(256)

if len(stations) == 0:
	print "Station does not exist!"
	sys.exit(256)

def download(year,day,station,ftp_url,ftp_dir,ftp_file,tout):

	global basedir
	global timeout
	
	print "-------------------------------------------------------"
#ftp_dir = ftp_dir.replace("<year>",year).replace("<day>",day)
        ftp_dir = ftp_dir.replace("<year>",year).replace("<day>",day).replace("<station>",station)
	
	' Connect to ftp'
	try:
		ftp = FTP(ftp_url,timeout=tout)
		ftp.login()
		print "Connection to '"+ftp_url+"' ... OK"
	except:
		print "Connection to '"+ftp_url+"' ... failed"
		return 0

	' Change directory '
	try:
		ftp.cwd(ftp_dir)
		print "Change directory to '"+ftp_dir+"' ... OK"
	except:
		print "Change directory to '"+ftp_dir+"' ... failed"
		return 0
	
	' Download file '
	try:
		ftp.retrbinary("RETR "+ftp_dir+ftp_file, open(basedir+year+"/"+day+"/"+ftp_file, 'wb').write)
		print "Downloading file '"+ftp_file+"' ... OK"
	except:
		print "Downloading file '"+ftp_file+"' ... failed"
		' Delete empty files '
		local_filesize = os.path.getsize(basedir+year+"/"+day+"/"+ftp_file)
		if local_filesize == 0:
			os.unlink(basedir+year+"/"+day+"/"+ftp_file)
		return 0

	' Check size '
	try:
		ftp_filesize = int(ftp.size(ftp_file))
		local_filesize = os.path.getsize(basedir+year+"/"+day+"/"+ftp_file)
		ftp_filesize,local_filesize
		if ftp_filesize == local_filesize:
			print "Checking downloaded filesize ("+str(local_filesize)+" Bytes)... OK"
			return 1
		else:
			print "Checking downloaded filesize (ftp:"+str(ftp_filesize)+" Bytes / local: "+str(local_filesize)+" Bytes)... not correct"			
			return 0
	except:
		print "Checking downloaded filesize ... failed"
		return 0

for station in stations:
	
	' Check Year-Dir '
	if os.path.isdir(basedir+year) == False:
		print "Creating "+basedir+year
		os.mkdir(basedir+year)

	' Check Day-Dir '
	if os.path.isdir(basedir+year+"/"+day) == False:
		print "Creating "+basedir+year+"/"+day
		os.mkdir(basedir+year+"/"+day)

	ftp_file = "<station><day>0."+year[-2:]+"d.Z"
	ftp_file = ftp_file.replace("<station>",station.lower()).replace("<day>",day)

	if os.path.isfile(basedir+year+"/"+day+"/"+ftp_file) == False:
		
		status = 0
		if status == 0:
			#BKG_E
			status = download(year,day,station,"igs.bkg.bund.de","/EUREF/obs/<year>/<day>/",ftp_file,3)
		if status == 0:
			#BKG_I
			status = download(year,day,station,"igs.bkg.bund.de","/IGS/obs/<year>/<day>/",ftp_file,3)
		if status == 0:
			#ASI
			status = download(year,day,station,"geodaf.mt.asi.it","/GEOD/GPSD/RINEX/<year>/<day>/",ftp_file,3)
		if status == 0:
			#IGNE
			status = download(year,day,station,"rgpdata.ensg.ign.fr","/pub/data/<year>/<day>/data_30/",ftp_file,3)
		if status == 0:
			#IGNI
			status = download(year,day,station,"igs.ensg.ign.fr","/pub/igs/data/<year>/<day>/",ftp_file,3)
		if status == 0:
			#OLG
			#status = download(year,day,station,"olggps.oeaw.ac.at","/pub/outdata/<station>/",ftp_file,59)
			status = download(year,day,station,"olggps.oeaw.ac.at","/pub/<year>/<day>/",ftp_file,59)
		if status == 0:
			#EPN-CB
			status = download(year,day,station,"epncb.oma.be","/pub/obs/<year>/<day>/",ftp_file,9)
		if status == 0:
			#CDDIS
			status = download(year,day,station,"cddis.gsfc.nasa.gov","/gps/data/daily/<year>/<day>/"+year[-2:]+"d/",ftp_file,10)
		
	else:
		print basedir+year+"/"+day+"/"+ftp_file+" already exists!"

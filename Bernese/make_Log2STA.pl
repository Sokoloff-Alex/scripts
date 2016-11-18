#!/usr/bin/perl
#
#   Generates STA file from gnss stations LOG files
#
#   station LOG files must be formated according to:
#	ftp://igscb.jpl.nasa.gov/pub/station/general/sitelog_instr.txt 
#
##### Command form:
#
#   make_Log2STA.pl [-option] [directory]
#
##### simple examples:
#
#	make_Log2STA.pl . 
# 		reads all available .log files in current directory
#	    and prints to the Standatr Output.
# 
# 	make_Log2STA.pl -fw LogFilesFolder 
# 		reads all avaliable .log files in LogFilesFolder directory
#	    and prints to the Standatr Output, neglecting firmware updates of receiver.  
#
##### options:
#
# 	-fw,  --ignore-firmware, -sw
#		generate Station Information File , neglecting firmware updates.
#
#	-nb,  --no-boundaries
#               set Install. and Remov. dates boundaries of station as empty
#
#       -df,  --no-first-boundary
#		set first Install. date as empty
#	-nl,  --no-last-boundary
#       	set last Remov. date as empty
#
#	-sb,  --stretch-boundaries
#		set first Install. date as '1980 01 06 00 00 00'
#		and last Remove date as    '2099 12 31 00 00 00'.  
#	-v,   --verbose : verbose mode, print to stderr additional info
#
#	-h, --help
#		show this help first
# 
####
#
# Author: Alexandr Sokolov, KEG
# e-mail: sokolovalexv@gmail.com
# 2016, (c)
#
##########################################################################


use strict;
use warnings;
use List::Util 'first';
use List::MoreUtils 'first_index'; 
use List::MoreUtils 'true';
use List::MoreUtils qw(uniq);
use POSIX qw(strftime);
use Data::Dumper qw(Dumper);

################################################################################
#			
#      subroutines / methods	
#			
################################################################################

sub GET_MARK_NAME {
	my $mark_name = substr $_[0],32,4;
	$mark_name =~ s/^\s+//;
	$mark_name =~ s/[\r\n]+$//;
	return($mark_name);
}

sub GET_MARK_NUMBER {
	my $mark_number = substr $_[0], 32,9;
	$mark_number =~ s/^\s+//;
	$mark_number =~ s/[\r\n]+$//;
	return($mark_number);
}

sub GET_Description {
	my $Description = substr $_[0], 32,20;
	$Description =~ s/^\s+//;
	$Description =~ s/[\r\n]+$//;
	return($Description);
}

sub GET_DATE {
	my $DateTimeISO_str = $_[0]; 
 	my $DateTimeISO = substr $DateTimeISO_str, 32,17; 
	$DateTimeISO =~ s/^\s+//;
	$DateTimeISO =~ s/[\r\n]+$//;
	my $DateTime;
	if ( $DateTimeISO ne 'CCYY-MM-DDThh:mmZ' && $DateTimeISO ne '(CCYY-MM-DDThh:mm' && $DateTimeISO ne "" ) {
		my $year  = substr $DateTimeISO, 0,4;
	 	my $month = substr $DateTimeISO, 5,2;
	 	my $day   = substr $DateTimeISO, 8,2;
		my $hh    = "00"; 
		my $mm    = "00"; 	
		my $ss    = "00";		
		if( length($DateTimeISO) eq "17" || length($DateTimeISO) eq "16"  ) {
			$hh = substr $DateTimeISO, 11,2;
	 		$mm = substr $DateTimeISO, 14,2;		
		}
		$DateTime = "$year $month $day $hh $mm $ss";
	} else {
		# print STDERR "$DateTimeISO\n";
		$DateTime = '2099 12 31 00 00 00';
#		$DateTime = '                   ';

	}
	return($DateTime);	
}

sub GetReceiver {
	my $Rec = $_[0];
	$Rec = substr $Rec, 32,19;	
	$Rec =~ s/^\s+//;
	$Rec =~ s/[\r\n]+$//;
	return($Rec);
}

sub GetReceiverNumber {
	my $RecSerNumber = $_[0];
	$RecSerNumber = substr $RecSerNumber, 32,20;
	$RecSerNumber =~ s/^\s+//;
	$RecSerNumber =~ s/[\r\n]+$//; 
	my $RecNumber = "999999"; 
	#if ($RecSerNumber ne "") {
	#	$RecNumber = " ";
	#} else {
	#	$RecNumber = "999999";
	#}
	return($RecSerNumber, $RecNumber);
}

sub GetFirmware {
	my $FirmWareVers = $_[0];
	$FirmWareVers = substr $FirmWareVers, 32,20;
	$FirmWareVers =~ s/^\s+//;
	$FirmWareVers =~ s/[\r\n]+$//;
	return($FirmWareVers);
}

sub GetAntenna {
	my $Antenna = $_[0];
	$Antenna = substr $Antenna, 32,20;	
	$Antenna =~ s/^\s+//;
	$Antenna =~ s/[\r\n]+$//;
	return($Antenna);
}

sub GetAntennaRadomType {
	my $AntennaRadomType = $_[0];
	$AntennaRadomType = substr $AntennaRadomType, 32,4;	
	$AntennaRadomType =~ s/^\s+//;
	$AntennaRadomType =~ s/[\r\n]+$//;
	if ($AntennaRadomType eq "") {
		#print STDERR "\n Radom is not specified!\n";
	}	
	return($AntennaRadomType);
}

sub GetAntennaSerialNumber {
	my $AntSerNumber = $_[0];
	$AntSerNumber = substr $AntSerNumber, 32,20;
	$AntSerNumber =~ s/^\s+//;
	$AntSerNumber =~ s/[\r\n]+$//;
	my $AntNumber = "999999";
	#if ($AntSerNumber ne "") {
	#	$AntNumber = $AntSerNumber;
	#	$AntNumber =~ s/\D//g;;
	#	$AntNumber = substr $AntNumber, -6;
	#} else {
	#	$AntNumber = "999999";
	#}
	return ($AntSerNumber, $AntNumber);
}

sub GetEccentricity {
	my $Eccentricity = $_[0];
	$Eccentricity = substr $Eccentricity, 32,8;
	$Eccentricity =~ s/^\s+//;
	$Eccentricity =~ s/[\r\n]+$//;
	if ($Eccentricity eq "" || $Eccentricity eq "(F8.4)") {
		$Eccentricity = 0.000;
	}
	return($Eccentricity);
}

sub getLaterDate {
	my $Date1 = $_[0];
	my $Date2 = $_[1];
	$Date1 = (substr$Date1,0,4).(substr $Date1,5,2).(substr $Date1,8,2).(substr $Date1,11,2).(substr $Date1,14,2).(substr $Date1,17,2);
	$Date2 = (substr$Date2,0,4).(substr $Date2,5,2).(substr $Date2,8,2).(substr $Date2,11,2).(substr $Date2,14,2).(substr $Date2,17,2);
	#print STDERR "Date1: $Date1\n";
	#print STDERR "Date2: $Date2\n";
	my $flagStart;
	my $NewDateStart;
	if ($Date1 gt $Date2) {
		$NewDateStart = $_[0];
		$flagStart = "AntRemains";	
	} elsif ($Date1 lt $Date2) {
		$NewDateStart = $_[1];
		$flagStart = "RecRemains";
	} else {
		$NewDateStart = $_[0];
		$flagStart = "Equal";	
	}
	#print STDERR "DateLater: $NewDateStart, $flagStart    \n\n";
	return($NewDateStart, $flagStart); #  return later date
}

sub getEarlierDate {
	my $Date1 = $_[0];
	my $Date2 = $_[1];
	$Date1 = (substr$Date1,0,4).(substr $Date1,5,2).(substr $Date1,8,2).(substr $Date1,11,2).(substr $Date1,14,2).(substr $Date1,17,2);
	$Date2 = (substr$Date2,0,4).(substr $Date2,5,2).(substr $Date2,8,2).(substr $Date2,11,2).(substr $Date2,14,2).(substr $Date2,17,2);
	#print STDERR "Date1: $Date1\n";
	#print STDERR "Date2: $Date2\n";
	my $flagEnd;
	my $NewDateEnd;
	if ($Date1 gt $Date2) {
		$NewDateEnd = $_[1];
		$flagEnd = "AntChange";	
	} elsif ($Date1 lt $Date2) {
		$NewDateEnd = $_[0];
		$flagEnd = "RecChange";
	} else {
		$NewDateEnd = $_[0];
		$flagEnd = "Equal";	
	}
	#print STDERR "DateEarlier: $NewDateEnd, $flagEnd\n\n";
	return($NewDateEnd, $flagEnd); #  return earlier date
}

sub checkDurationOfOverlap {
	my $Date1 = $_[0];
	my $Date2 = $_[1];
	$Date1 = (substr$Date1,0,4).(substr $Date1,5,2).(substr $Date1,8,2).(substr $Date1,11,2).(substr $Date1,14,2).(substr $Date1,17,2);
	$Date2 = (substr$Date2,0,4).(substr $Date2,5,2).(substr $Date2,8,2).(substr $Date2,11,2).(substr $Date2,14,2).(substr $Date2,17,2);
	#print STDERR "Date1: $Date1\n";
	#print STDERR "Date2: $Date2\n";
	my $flagOverlap;
	if ($Date1 eq $Date2) {
		$flagOverlap = "ZeroOverlap";	
		#print STDERR "block skiped : $flagOverlap\n\n";
	} elsif ($Date1 lt $Date2) {
		$flagOverlap = "PositiveOverlap";
		#print STDERR "block skiped : $flagOverlap\n\n";
	} else {
		$flagOverlap = "NegativeOverlap";	
	}
	return($flagOverlap); 
}


####### Filter Receiver array, skip Firmware updates #####

sub FilterReceiverArray {     
	# print STDERR "Neglecting Firmware Updates\n";
	my @ReceiversArray = @_; 
	my $NumberOfReceivers = @ReceiversArray;
	my $Remark = " ";	
	my @ReceiverArrayFiltered;	
	my @line1;
	my @line2;
	my $Counter = 0;
	my $indexNext;
	my @NewReceiverConfigLine;
	if ($NumberOfReceivers eq "1") {
		@ReceiverArrayFiltered = @ReceiversArray;
	} else {
		for (my $index=0; $index < $NumberOfReceivers; $index++) {
			@NewReceiverConfigLine = ([$ReceiversArray[$index][0], $ReceiversArray[$index][1],$ReceiversArray[$index][2], $ReceiversArray[$index][3],  $ReceiversArray[$index][4], $Remark]);
			@ReceiverArrayFiltered[$Counter] = @NewReceiverConfigLine;	
			$indexNext = $index + 1;
			while ( $indexNext < $NumberOfReceivers && ($ReceiversArray[$index][2] eq $ReceiversArray[$indexNext][2] && $ReceiversArray[$index][3] eq $ReceiversArray[$indexNext][3]) ) {
				@NewReceiverConfigLine = ([$ReceiversArray[$index][0], $ReceiversArray[$indexNext][1],$ReceiversArray[$index][2], $ReceiversArray[$index][3],  $ReceiversArray[$index][4], $Remark]);	
				@ReceiverArrayFiltered[$Counter] = @NewReceiverConfigLine;		
				#print STDERR "skip line # $indexNext\n";
				$indexNext++;
			}
			$index = $indexNext-1;
			$Counter++;	
		}
	}	
	# print to console
	my $ReceiverFilteredNumber = @ReceiverArrayFiltered;
	#print STDERR "ReceiverFilteredNumber: $ReceiverFilteredNumber\n";
	for (my $index=0; $index < $ReceiverFilteredNumber; $index++) {
		#printf STDERR "%20s %20s %20s %20s %10s %20s \n", $ReceiverArrayFiltered[$index][0], $ReceiverArrayFiltered[$index][1], $ReceiverArrayFiltered[$index][2], $ReceiverArrayFiltered[$index][3], $ReceiverArrayFiltered[$index][4], $ReceiverArrayFiltered[$index][5];
	}
	return (@ReceiverArrayFiltered)
}

##########################################################



sub AddHeaderOfType1 {
	my $datestring = strftime "%e-%b-%Y %H:%M", localtime;
	#printf("$datestring\n");
	my $String = "Auto Generated *.STA, using make_Log2STA.pl; BSW VERSION 5.2;  $datestring
--------------------------------------------------------------------------------

FORMAT VERSION: 1.01
TECHNIQUE:      GNSS

TYPE 001: RENAMING OF STATIONS
------------------------------

STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************
";
print STDOUT $String;
}


sub AddHeaderOfType2 {
	my $StringType2 = " 

TYPE 002: STATION INFORMATION
-----------------------------

STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************
";
print STDOUT $StringType2;   
}

sub AddHeaderOfTypes345 {
	my $String = "

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


";
print STDOUT $String;   
}

#########################################################
#
# subroutines / methods END
#
#########################################################
#
#print "Start generating STA file from Log files:\n\n";

my $FLG='001';
my $dir;
my $NumberOfArgs = @ARGV;
my @options = @ARGV;
if ($NumberOfArgs == 0) {
	print "Illegal Number of arguments!\n";
	die "Specify Directory with *.log files!\n";
} elsif ($NumberOfArgs <= 4) {
	$dir = $ARGV[$NumberOfArgs-1];
} else {
	die "Illegal Number of arguments!\n";	
}

## print help to SDTERR
if ( grep( /^-h$/, @options) || grep( /^--help$/, @options) ) {
	print STDERR "
################   Generates STA file from gnss station LOG files ##################
#
#	Station LOG files must be formated according to:
#	ftp://igscb.jpl.nasa.gov/pub/station/general/sitelog_instr.txt 
#
##### Command form:
#
#	make_Log2STA.pl [-option] [directory] > outputFile
#
##### simple examples:
#
#	make_Log2STA.pl . 
# 		reads all available .log files in current directory
#	    and prints to the Standatr Output.
# 
# 	make_Log2STA.pl -fw LogFilesFolder 
# 		reads all avaliable .log files in LogFilesFolder directory
#		and prints to the Standatr Output, neglecting firmware updates of receiver.
#
##### options:
#
# 	-fw,  --ignore-firmware, -sw
#		generate Station Information File , neglecting firmware updates.
#
#	-nb,  --no-boundaries
#		set Install. and Remov. dates boundaries of station as empty
#
#	-df,  --no-first-boundary
#		set first Install. date as empty
#
#	-nl,  --no-last-boundary
#		set last Remov. date as empty
#
#	-sb,  --stretch-boundaries
#		set first Install. date as '1980 01 06 00 00 00'
#		and last Remove date as    '2099 12 31 00 00 00'.  
#
#	-v,   --verbose : verbose mode, print to stderr additional info
#
#	-h, --help
#		show this help first
#
##########################################################################################\n" ;
	die "\n";
}

# verbose	
if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
	print STDERR "Verbose mode\n";
	print STDERR "Directory: $dir\n";
	print STDERR " --- file-list --- \n";
}

# fetch file names
my @files = glob("$dir/*.log");  # skan directory for *.log files and save full path to array
foreach my $file (@files) {      # list of *.log files

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		   print STDERR "$file\n";	
	}
}

# verbose	
if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR " --- end of list --- \n";
	    print STDERR "\n"; 
}

####
# Start writing to STDOUT
###

################# Generate TYPE 001: RENAMING OF STATIONS #####################################
#open(my $NewSTA, '>', "$dir/New.STA")  or die "Could not open file";


&AddHeaderOfType1();             # Add header TYPE 001
#&AddHeaderOfType1($NewSTA);

# Add info TYPE 001
foreach my $file (@files) {   	
	open (LogFile,"<$file" ) || die "LogFile not found\n";
	my @LogFile;
	while(<LogFile>) {
		push(@LogFile,$_);
	}
	close(LogFile);

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR " -------------------\n";			
		print STDERR "File: $file\n"; 
		print STDERR " -------------------\n";
	}

	my $string = first { /Four Character ID        :/ } @LogFile;		
	my $mark_name = GET_MARK_NAME($string);

	$string = first { /IERS DOMES Number        :/ } @LogFile;	
	my $mark_number = GET_MARK_NUMBER($string);
	if ( $mark_number eq "N/A" || $mark_number eq "(A9)" || $mark_number eq "NONE" || $mark_number eq "" )  {		
		$mark_number = $mark_name;
	}	
	$string = first { /Date Installed           :/ } @LogFile;
	my $DateInstalled = GET_DATE($string);
	if ( $DateInstalled eq '2099 12 31 00 00 00') {
		$DateInstalled = '                   ';
	}
	$DateInstalled = '                   ';

#	my $DateRemoved = '2099 12 31 00 00 00';
	my $DateRemoved = '                   ';

	my $Remark = substr $file, -17;
	
	printf STDOUT         "%4s %-11s %8s %20s %20s %5s*                 %-24s\n", $mark_name, $mark_number, $FLG, $DateInstalled, $DateRemoved, $mark_name, $Remark;
	
	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print  STDERR " --- TABLE TYPE 001 ---\n";		
		printf STDERR "%4s %-11s %8s %20s %20s %5s*                 %-24s\n", $mark_name, $mark_number, $FLG, $DateInstalled, $DateRemoved, $mark_name, $Remark;
		print  STDERR " -------------------\n";
	}
}

############################ Generate TYPE 002: STATION INFORMATION #########################


&AddHeaderOfType2;            # Add header
#&AddHeaderOfType2($NewSTA);

# Add info TYPE 002
foreach my $file (@files) {   	
	open (LogFile,"<$file" ) || die "LogFile not found\n";
	my @LogFile;
	while(<LogFile>) {
		push(@LogFile,$_);
	}
	close(LogFile);
	
	my $string = first { /Four Character ID        :/ } @LogFile;		
	my $mark_name = &GET_MARK_NAME($string);

	$string = first { /IERS DOMES Number        :/ } @LogFile;	
	my $mark_number = GET_MARK_NUMBER($string);
	if ( $mark_number eq "N/A" || $mark_number eq "(A9)" || $mark_number eq "NONE" || $mark_number eq "" )  {		
		$mark_number = $mark_name;
	}	

	$string = first { /Site Name                :/ } @LogFile;	
	my $Description = GET_Description($string);
	
	#################### Get Receivers SubArray #############################################

	my $FirstReceiverIndex = first_index { /3.1  Receiver Type            :/ } @LogFile;
	my $LastReceiverIndex  = first_index { /3.x  Receiver Type            :/ } @LogFile;
	if ($LastReceiverIndex == -1) {
		$LastReceiverIndex  = first_index { /4.   GNSS Antenna Information/ } @LogFile;     
	}
	# debug, if no "3.x" used in logfile
	my @ReceiversData = @LogFile[$FirstReceiverIndex..$LastReceiverIndex-2];

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR " --- Receiver Data ---\n";
		print STDERR "@ReceiversData";		
	}

	
	my @Rec               = grep { /Receiver Type            :/ } @ReceiversData;
	my @RecSerNumber      = grep { /Serial Number            :/ } @ReceiversData;
	my @FirmWareVers      = grep { /Firmware Version         :/ } @ReceiversData;
	my @DateInstalled     = grep { /Date Installed           :/ } @ReceiversData;
	my @DateRemoved       = grep { /Date Removed             :/ } @ReceiversData;	
	my $NumberOfReceivers = true { /Receiver Type            :/ } @ReceiversData;

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR "Number of Receivers: $NumberOfReceivers\n";	
		if ( $NumberOfReceivers == 0 ) {
			print STDERR "################################################\n";
			print STDERR "ERORR: NO RECEIVERS FOUNS in $file \n";
			print STDERR "################################################\n";
		}			
	}

	my @ReceiversArray;

	for (my $i=0; $i <= $NumberOfReceivers-1; $i++) {
		
		my $Rec = GetReceiver($Rec[$i]);
		(my $RecSerNumber, my $RecNumber) = GetReceiverNumber($RecSerNumber[$i]);
		my $FirmWareVers = GetFirmware($FirmWareVers[$i]);
		my $DateInstalled = GET_DATE($DateInstalled[$i]);
		my $DateRemoved   = GET_DATE($DateRemoved[$i]);

		$ReceiversArray[$i] = ([$DateInstalled, $DateRemoved, $Rec, $RecSerNumber, $RecNumber, $FirmWareVers]); ## Contains ALL Receivers DATA

	 	# verbose	
		if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
			printf STDERR "%20s %20s %-20s %-20s %10s %-20s \n", $DateInstalled, $DateRemoved, $Rec, $RecSerNumber, $RecNumber, $FirmWareVers; 	
		} 
	}
	#print STDERR "\n";

	########### Get ANTENNAS SubArray ###############################################

	my $FirstAntennaIndex = first_index { /4.1  Antenna Type             :/ } @LogFile;
	my $LastAntennaIndex  = first_index { /4.x  Antenna Type             :/ } @LogFile;
	if ($LastAntennaIndex == -1) {
		$LastAntennaIndex  = first_index { /5.   Surveyed Local Ties/ } @LogFile;
	}
	my @AntennasData = @LogFile[$FirstAntennaIndex..$LastAntennaIndex-2];

 	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR " --- Antenna Data ---\n";
		print STDERR "@AntennasData";
	} 
	
	# parse parameters
	my @Antenna = grep { /Antenna Type             :/ } @AntennasData;
	my @AntennaRadomType = grep  { /Antenna Radome Type      :/}  @AntennasData;
	my @AntSerNumber = grep { /Serial Number            :/ } @AntennasData;
	my @Eccentricity_U = grep { /Up Ecc/ } @AntennasData;
	@Eccentricity_U = grep { /(m)/ } @Eccentricity_U; # correction of bag above due to special charracters combination
	my @Eccentricity_N = grep { /North Ecc/ } @AntennasData;
	my @Eccentricity_E = grep { /East Ecc/ } @AntennasData;
	@DateInstalled= grep { /Date Installed           :/ } @AntennasData;
	@DateRemoved = grep { /Date Removed             :/ } @AntennasData;	
	my $NumberOfAntennas = true { /Antenna Type             :/ } @AntennasData;

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR "Number of Antennas: $NumberOfAntennas\n";
		if ( $NumberOfAntennas == 0 ) {
			print STDERR "################################################\n";
			print STDERR "ERORR: NO ANTENNAS FOUNS in $file \n";
			print STDERR "################################################\n";
		}
	}

	
	my @AntennasArray;
	for (my $i=0; $i <= $NumberOfAntennas-1; $i++) {		
		my $Antenna = GetAntenna($Antenna[$i]);	
		my $AntennaRadomType = GetAntennaRadomType($AntennaRadomType[$i]);
		(my $AntSerNumber, my $AntNumber ) = GetAntennaSerialNumber($AntSerNumber[$i]);	
		my $Eccentricity_U = GetEccentricity($Eccentricity_U[$i]);
		my $Eccentricity_N = GetEccentricity($Eccentricity_N[$i]);
		my $Eccentricity_E = GetEccentricity($Eccentricity_E[$i]);
		my $DateInstalled  = GET_DATE($DateInstalled[$i]);		
		my $DateRemoved    = GET_DATE($DateRemoved[$i]);

		if ( length($Antenna) ne 20 ) {	

			# verbose	
			if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
				print STDERR "\nAntenna Error:\n";
				print STDERR "$Antenna\n";
				print STDERR "$AntennaRadomType\n";
			}

			$Antenna = substr $Antenna, 0,15;
			$Antenna = sprintf ("%-15s %4s", $Antenna, $AntennaRadomType);
		} 	

		$AntennasArray[$i] = ([$DateInstalled, $DateRemoved, $Antenna, $AntSerNumber, $AntNumber, $Eccentricity_U, $Eccentricity_N, $Eccentricity_E]);
		
		# verbose	
		if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
			printf STDERR "%20s %20s %22s %10s %10s %8.4f %8.4f %8.4f \n", $DateInstalled, $DateRemoved, $Antenna, $AntSerNumber, $AntNumber, $Eccentricity_U, $Eccentricity_N, $Eccentricity_E; 	 
		}	
	}	

	# verbose	
	if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
		print STDERR "\n";
	}

	### Filter Receiver array, skip Firmware updates ######
	if ( grep( /^-fw$/, @options) || grep( /^--ignore-firmware$/, @options) || grep( /^-sw$/, @options)  ) {
		# verbose	
		if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
			print STDERR "option: skip firmware updates\n";
		}
		@ReceiversArray = FilterReceiverArray(@ReceiversArray);
	}		

	###################### MERGE Antenna and Receiver subarrays hronologically ############################
	
	my @Records;
	$NumberOfReceivers = @ReceiversArray;
	my $NewDateStart;
	my $NewDateEnd;
	my $flagStart;	
	my $flagEnd;	
	my $flagOverlap;	
	my $counterRec = 0;
	my $counterAnt = 0;
	my $index = 0;

	while (($counterRec < $NumberOfReceivers) && ($counterAnt < $NumberOfAntennas)) {

		($NewDateStart, $flagStart) = getLaterDate(   $ReceiversArray[$counterRec][0], $AntennasArray[$counterAnt][0]);
		($NewDateEnd,   $flagEnd)   = getEarlierDate( $ReceiversArray[$counterRec][1], $AntennasArray[$counterAnt][1]);
		$flagOverlap = checkDurationOfOverlap($NewDateStart, $NewDateEnd);
		if ( $flagOverlap eq "PositiveOverlap" ) {
			$Records[$index] = ([$mark_name, $mark_number, $FLG, $NewDateStart, $NewDateEnd, $ReceiversArray[$counterRec][2], $ReceiversArray[$counterRec][3],  $ReceiversArray[$counterRec][4], $ReceiversArray[$counterRec][5], $AntennasArray[$counterAnt][2], $AntennasArray[$counterAnt][3], $AntennasArray[$counterAnt][4],$AntennasArray[$counterAnt][5], $AntennasArray[$counterAnt][6],  $AntennasArray[$counterAnt][7], $Description ]);		
			$index++;	
		} else {
			# verbose	
			if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
				print STDERR  "flagOverlap: $flagOverlap \n"; 
			}
		}

		if ($flagEnd eq "RecChange" ) {
			$counterRec++;
		} elsif ($flagEnd eq "AntChange" ) {
			$counterAnt++;
		} elsif ($flagEnd eq "Equal" ) {
			$counterRec++;
			$counterAnt++;
		} else {
			print STDERR "\n ERROR : Cannot distinguish dates of equipment changes\n\n"; 
		} 
	}

 	#### adjust epoch boundaries ########
	my $RecordsNumber = @Records;
	if (      grep( /^-nb$/, @options) || grep( /^--no-boundaries$/,     @options) ) {
		$Records[0][3] = '                   ';
		$Records[$RecordsNumber-1][4] = '                   ';
	} elsif ( grep( /^-nf$/, @options) || grep( /^--no-first-boundary$/, @options) ) {
		$Records[0][3] = '                   ';
	} elsif ( grep( /^-nl$/, @options) || grep( /^--no-last-boundary$/,  @options) ) {
		$Records[$RecordsNumber-1][4] = '                   ';
	} elsif ( grep( /^-sb$/, @options) || grep( /^-stretch-boundaries$/, @options) ) {
		$Records[0][3] = '1980 01 06 00 00 00';
	}

	####  print in TYPE 2 table  to STDOUT ####
	my @format = ("%4s"," %-12s ","    %3s"," %20s"," %20s "," %-20s "," %-20s "," %6s "," %-20s "," %-20s ", " %6s "," %8.4f ", " %8.4f ", " %8.4f ", " %-22s ", " %-24s\n");
	my @line;	
	for (my $row = 0; $row < $RecordsNumber; $row++) {	
		@line = ($Records[$row][0], $Records[$row][1], $Records[$row][2], $Records[$row][3], $Records[$row][4], $Records[$row][5],$Records[$row][6], $Records[$row][7], $Records[$row][9], $Records[$row][10], $Records[$row][11], $Records[$row][13], $Records[$row][14], $Records[$row][12], $Records[$row][15], $Records[$row][8]) ;
		for (my $col = 0; $col <= 15; $col++) {
			printf ($format[$col], $line[$col]) ;
	
			# verbose	
			if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
				printf STDERR ( $format[$col], $line[$col]); 
			}
		}		
	}
}

&AddHeaderOfTypes345(); # Add headers for types 3, 4 and 5 to standart output
#&AddHeaderOfTypes345($NewSTA); # Add headers for types 3, 4 and 5 to the file

#close $NewSTA;

# verbose	
if ( grep( /^-v$/, @options) || grep( /^--verbose$/, @options) ) {
	#print "\nNew STA file saved in: $dir/New.STA";
	print STDERR "\nDone\n\n"; 
}

###########
# The End 
###########

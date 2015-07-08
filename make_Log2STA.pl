#!/usr/bin/perl
# Generate STA file from Log files

use strict;
use warnings;
use List::Util 'first';
use List::MoreUtils 'first_index'; 
use List::MoreUtils 'true';
use List::MoreUtils qw(uniq);
use POSIX qw(strftime);

print "\n";
print "Start generating STA file from Log files:\n\n";
my $FLG='001';
my $dir;
my $NumberOfArgs = @ARGV;
if ($NumberOfArgs == 2) {
	$dir = $ARGV[1];
} elsif ($NumberOfArgs == 1) {
	$dir = $ARGV[0];	
} else {
	print "Illegal Number of arguments!\n";	
}

print "Directory: $dir\n";
print "file-list\n";


my @files = glob("$dir/*.log");  # skan directory for *.log files and save full path to array
foreach my $file (@files) {  ## list of *.log files
    print "$file\n";
}
print "\n"; 

################# Generate TYPE 001: RENAMING OF STATIONS #####################################
open(my $NewSTA, '>', "$dir/New.STA")  or die "Could not open file";


&AddHeaderOfType1();             # Add header TYPE 001
&AddHeaderOfType1($NewSTA);

# Add info TYPE 001
foreach my $file (@files) {   	
	open (LogFile,"<$file" ) || die "LogFile not found\n";
	my @LogFile;
	while(<LogFile>) {
		push(@LogFile,$_);
	}
	close(LogFile);

	my $string = first { /Four Character ID        :/ } @LogFile;		
	my $mark_name = GET_MARK_NAME($string);

	$string = first { /IERS DOMES Number        :/ } @LogFile;	
	my $mark_number = GET_MARK_NUMBER($string);
	
	$string = first { /Date Installed           :/ } @LogFile;
	my $DateInstalled = GET_DATE($string);

	my $DateRemoved ='2099 12 31 00 00 00';

	my $Remark = substr $file, -17;
	
	printf "%4s %-11s %8s %20s %20s %5s*                 %-24s\n", $mark_name, $mark_number, $FLG,$DateInstalled, $DateRemoved, $mark_name, $Remark;
	printf $NewSTA "%4s %-11s %8s %20s %20s %5s*                 %-24s\n", $mark_name, $mark_number, $FLG, $DateInstalled, $DateRemoved, $mark_name, $Remark;
}

############################ Generate TYPE 002: STATION INFORMATION #########################


&AddHeaderOfType2;            # Add header
&AddHeaderOfType2($NewSTA);

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

	$string = first { /Site Name                :/ } @LogFile;	
	my $Description = GET_Description($string);
	
	#################### Get Recievers SubArray #############################################

	my $FirstReceiverIndex = first_index { /3.1  Receiver Type            :/ } @LogFile;
	my $LastReceiverIndex  = first_index { /3.x  Receiver Type            :/ } @LogFile;
    if ($LastReceiverIndex == -1) {
       $LastReceiverIndex  = first_index { /4.   GNSS Antenna Information/ } @LogFile;     
    }
	my @ReceiversData = @LogFile[$FirstReceiverIndex..$LastReceiverIndex-2];
	#print "@ReceiversData";
	
	my @Rec = grep { /Receiver Type            :/ } @ReceiversData;
	my @RecSerNumber = grep { /Serial Number            :/ } @ReceiversData;
	my @FirmWareVers = grep { /Firmware Version         :/ } @ReceiversData;
	my @DateInstalled = grep { /Date Installed           :/ } @ReceiversData;
	my @DateRemoved = grep { /Date Removed             :/ } @ReceiversData;	
	my $NumberOfReceivers = true { /Receiver Type            :/ } @ReceiversData;
	#print "Number of Receivers: $NumberOfReceivers\n";
	my @RecieversArray;

	for (my $i=0; $i <= $NumberOfReceivers-1; $i++) {
		
		my $Rec = GetReceiver($Rec[$i]);
		(my $RecSerNumber, my $RecNumber) = GetReceiverNumber($RecSerNumber[$i]);
		my $FirmWareVers = GetFirmware($FirmWareVers[$i]);
		my $DateInstalled = GET_DATE($DateInstalled[$i]);
		my $DateRemoved   = GET_DATE($DateRemoved[$i]);

		@RecieversArray[$i] = ([$DateInstalled, $DateRemoved, $Rec, $RecSerNumber, $RecNumber, $FirmWareVers]); ## Contains ALL Receivers DATA 
		#printf "%20s %20s %20s %20s %10s %20s \n", $DateInstalled, $DateRemoved, $Rec, $RecSerNumber, $RecNumber, $FirmWareVers; 	 
    }
	#print "\n";

	########### Get ANTENNAS SubArray ###############################################

	my $FirstAntennaIndex = first_index { /4.1  Antenna Type             :/ } @LogFile;
	my $LastAntennaIndex  = first_index { /4.x  Antenna Type             :/ } @LogFile;
    if ($LastAntennaIndex == -1) {
        $LastAntennaIndex  = first_index { /5.   Surveyed Local Ties/ } @LogFile;
    }
	my @AntennasData = @LogFile[$FirstAntennaIndex..$LastAntennaIndex-2];
	#print "@AntennasData";
	
	my @Antenna = grep { /Antenna Type             :/ } @AntennasData;
	my @AntSerNumber = grep { /Serial Number            :/ } @AntennasData;
	my @Eccentricity_U = grep { /Up Ecc/ } @AntennasData;
	@Eccentricity_U = grep { /(m)/ } @Eccentricity_U; # correction of bag above
	my @Eccentricity_N = grep { /North Ecc/ } @AntennasData;
	my @Eccentricity_E = grep { /East Ecc/ } @AntennasData;
	my @DateInstalled= grep { /Date Installed           :/ } @AntennasData;
	my @DateRemoved = grep { /Date Removed             :/ } @AntennasData;	
	my $NumberOfAntennas = true { /Antenna Type             :/ } @AntennasData;
	#print "Number of Antennas: $NumberOfAntennas\n";
	
	my @AntennasArray;
	for (my $i=0; $i <= $NumberOfAntennas-1; $i++) {		
		my $Antenna = GetAntenna($Antenna[$i]);	
		(my $AntSerNumber, my $AntNumber ) = GetAntennaSerialNumber($AntSerNumber[$i]);	
		my $Eccentricity_U = GetEccentricity($Eccentricity_U[$i]);
		my $Eccentricity_N = GetEccentricity($Eccentricity_N[$i]);
		my $Eccentricity_E = GetEccentricity($Eccentricity_E[$i]);
		my $DateInstalled  = GET_DATE($DateInstalled[$i]);		
		my $DateRemoved    = GET_DATE($DateRemoved[$i]);		

		@AntennasArray[$i] = ([$DateInstalled, $DateRemoved, $Antenna, $AntSerNumber, $AntNumber, $Eccentricity_U, $Eccentricity_N, $Eccentricity_E]);
		#printf "%20s %20s %22s %10s %10s %8.4f %8.4f %8.4f \n", $DateInstalled, $DateRemoved,   $Antenna, $AntSerNumber, $AntNumber, $Eccentricity_U, $Eccentricity_N, $Eccentricity_E; 	 
	}	
	
	### Filter Reciever array, skip Firmware updates ######
	if ($ARGV[0] eq "-sw") {
		@RecieversArray = FilterReceiverArray(@RecieversArray);	
	}		

	###################### MERGE Antenna and Receiver subarrays hronologically ############################
	
	my @Records;
	my $NumberOfReceivers = @RecieversArray;
	my $counterAnt = @AntennasArray;
	my $NewDateStart;
	my $NewDateEnd;
	my $flagStart;	
	my $flagEnd;	
	my $counterRec = 0;
	my $counterAnt = 0;
	my $index = 0;

    while (($counterRec < $NumberOfReceivers) && ($counterAnt < $NumberOfAntennas)) {

       ($NewDateStart, $flagStart) = getLaterDate(  $RecieversArray[$counterRec][0], $AntennasArray[$counterAnt][0]);
       ($NewDateEnd,   $flagEnd)   = getEarlierDate($RecieversArray[$counterRec][1], $AntennasArray[$counterAnt][1]);
        
        @Records[$index] = ([$mark_name, $mark_number, $FLG, $NewDateStart, $NewDateEnd, $RecieversArray[$counterRec][2], $RecieversArray[$counterRec][3],  $RecieversArray[$counterRec][4], $RecieversArray[$counterRec][5], $AntennasArray[$counterAnt][2], $AntennasArray[$counterAnt][3], $AntennasArray[$counterAnt][4],$AntennasArray[$counterAnt][5], $AntennasArray[$counterAnt][6],  $AntennasArray[$counterAnt][7], $Description ]);		
		$index++;	
        if ($flagEnd eq "RecChange" ) {
	        $counterRec++;
        } elsif ($flagEnd eq "AntChange" ) {
	        $counterAnt++;
        } else {
	        $counterRec++;
	        $counterAnt++;
		}
	}
	#print "\n";

    ####  print in TYPE 3 format to console and to the file #### 
	my @format = ("%4s"," %-12s ","    %3s"," %20s"," %20s "," %-20s "," %-20s "," %6s "," %-20s "," %20s ", " %6s "," %8.4f ", " %8.4f ", " %8.4f ", " %-22s ", " %-24s\n");
	my @line;
	my $RecordsNumber = @Records;
	for (my $row = 0; $row < $RecordsNumber; $row++) {	
		@line = ($Records[$row][0], $Records[$row][1], $Records[$row][2], $Records[$row][3], $Records[$row][4], $Records[$row][5],$Records[$row][6], $Records[$row][7], $Records[$row][9], $Records[$row][10], $Records[$row][11], $Records[$row][13], $Records[$row][14], $Records[$row][12], $Records[$row][15], $Records[$row][8]) ;
		for (my $col = 0; $col <= 15; $col++) {
			printf (@format[$col], @line[$col]) ;
			printf ($NewSTA @format[$col], @line[$col]);
		}		
	}
}

&AddHeaderOfTypes345($NewSTA); # Add headers for types 3, 4 and 5 to the file

close $NewSTA;
print "New STA file saved in: $dir/New.STA";
             
print "\nDone\n\n"; 

########################
#
#      subroutines
#
########################

sub GET_MARK_NAME() {
	my $mark_name = substr $_[0],32,4;
	$mark_name =~ s/^\s+//;
	return($mark_name);
}

sub GET_MARK_NUMBER() {
	my $mark_number = substr $_[0], 32,9;
	$mark_number =~ s/^\s+//;
	return($mark_number);
}

sub GET_Description() {
	my $Description = substr $_[0], 32,20;
	$Description =~ s/^\s+//;
	$Description =~ s/[\r\n]+$//;
	return($Description);
}

sub GET_DATE() {
	my $DateTimeISO = $_[0]; 
 	$DateTimeISO = substr $DateTimeISO, 32,17; 

	my $DateTime;
	if ( $DateTimeISO ne 'CCYY-MM-DDThh:mmZ' && $DateTimeISO ne '(CCYY-MM-DDThh:mm' ) {
	#print "$DateTimeISO\n";
		my $year  = substr $DateTimeISO, 0,4;
	 	my $month = substr $DateTimeISO, 5,2;
	 	my $day   = substr $DateTimeISO, 8,2;
		my $hh = "00";
		my $mm = "00";
		my $ss = "00";
		if( length($DateTimeISO) == 17  ) {
			$hh = substr $DateTimeISO, 11,2;
	 		$mm = substr $DateTimeISO, 14,2;		
		}
		$DateTime = "$year $month $day $hh $mm $ss";
	} else {
		$DateTime = '2099 12 31 00 00 00';

	}
	return($DateTime);	
}

sub GetReceiver() {
	my $Rec = $_[0];
	$Rec = substr $Rec, 32,19;	
	$Rec =~ s/^\s+//;
	$Rec =~ s/[\r\n]+$//;
	return($Rec);
}

sub GetReceiverNumber() {
	my $RecSerNumber = $_[0];
	$RecSerNumber = substr $RecSerNumber, 32,20;
	$RecSerNumber =~ s/^\s+//;
	$RecSerNumber =~ s/[\r\n]+$//; 
	my $RecNumber;   
	if ($RecSerNumber ne "") {
		$RecNumber = " ";
	} else {
		$RecNumber = "999999";
	}
	return($RecSerNumber, $RecNumber);
}

sub GetFirmware() {
	my $FirmWareVers = $_[0];
	$FirmWareVers = substr $FirmWareVers, 32,20;
	$FirmWareVers =~ s/^\s+//;
	$FirmWareVers =~ s/[\r\n]+$//;
	return($FirmWareVers);
}

sub GetAntenna() {
	my $Antenna = $_[0];
	$Antenna = substr $Antenna, 32,20;	
	$Antenna =~ s/^\s+//;
	$Antenna =~ s/[\r\n]+$//;
	return($Antenna);
}

sub GetAntennaSerialNumber() {
	my $AntSerNumber = $_[0];
	$AntSerNumber = substr $AntSerNumber, 32,20;
	$AntSerNumber =~ s/^\s+//;
	$AntSerNumber =~ s/[\r\n]+$//;
	my $AntNumber;
	if ($AntSerNumber ne "") {
		$AntNumber = $AntSerNumber;
		$AntNumber =~ s/\D//g;;
		$AntNumber = substr $AntNumber, -6;
	} else {
		$AntNumber = "999999";
	}
	return ($AntSerNumber, $AntNumber);
}

sub GetEccentricity() {
	my $Eccentricity = $_[0];
	$Eccentricity = substr $Eccentricity, 32,8;
	$Eccentricity =~ s/^\s+//;
	$Eccentricity =~ s/[\r\n]+$//;
	if ($Eccentricity eq "") {
		$Eccentricity = 0.000;
	}
	return($Eccentricity);
}

sub getEarlierDate {
	my $Date1 = $_[0];
	my $Date2 = $_[1];
	$Date1 = (substr$Date1,0,4).(substr $Date1,5,2).(substr $Date1,8,2).(substr $Date1,11,2).(substr $Date1,14,2).(substr $Date1,17,2);
	$Date2 = (substr$Date2,0,4).(substr $Date2,5,2).(substr $Date2,8,2).(substr $Date2,11,2).(substr $Date2,14,2).(substr $Date2,17,2);
	#print "Date1: $Date1\n";
	#print "Date2: $Date2\n";
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
	return($NewDateEnd, $flagEnd); #  return earlier date
}

sub getLaterDate() {
	my $Date1 = $_[0];
	my $Date2 = $_[1];
	$Date1 = (substr$Date1,0,4).(substr $Date1,5,2).(substr $Date1,8,2).(substr $Date1,11,2).(substr $Date1,14,2).(substr $Date1,17,2);
	$Date2 = (substr$Date2,0,4).(substr $Date2,5,2).(substr $Date2,8,2).(substr $Date2,11,2).(substr $Date2,14,2).(substr $Date2,17,2);
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
	return($NewDateStart, $flagStart); #  return later date
}

####### Filter Reciever array, skip Firmware updates #####
sub FilterReceiverArray() {     
	my @RecieversArray = @_; 
	my $NumberOfReceivers = @RecieversArray;
	#print "Neglecting Firmware Updates\n";
	my $Remark = " ";	
	#my $file =@_[1];
	#my $Remark = substr $file, -17;
	my @RecieverArrayFiltered;	
	my @line1;
	my @line2;
	my $Counter = 0;
	my @NewRecieverConfigLine = ([$RecieversArray[0][0], $RecieversArray[0][1],$RecieversArray[0][2], $RecieversArray[0][3],  $RecieversArray[0][4], $Remark]);
	@RecieverArrayFiltered[0] = @NewRecieverConfigLine;
	for (my $index=0; $index < $NumberOfReceivers; $index++) {
		my $indexIN = $index+1;
		if ($indexIN < $NumberOfReceivers) { # Get initial lines to compare 
			@line1 = ($RecieversArray[$index][2], $RecieversArray[$index][3], $RecieversArray[$index][4]);
			@line2 = ($RecieversArray[$indexIN][2], $RecieversArray[$indexIN][3], $RecieversArray[$indexIN][4]);
			#print "Outer loop : index : $index : Line1: @line1\n";
			#print "Inner loop : index : $indexIN : Line2: @line2\n";
		}			

		while (("@line1" eq "@line2") && ($indexIN < $NumberOfReceivers)) {		# iterate over equal lines => skip equal	 	
			@line2 = ($RecieversArray[$indexIN][2], $RecieversArray[$indexIN][3], $RecieversArray[$indexIN][4]);
			#print "Inner loop : index : $indexIN : Line2: @line2\n";
			$indexIN++;
		}

		if ($indexIN <= $NumberOfReceivers) {   # write next unique line
			@NewRecieverConfigLine = ([$RecieversArray[$index][0], $RecieversArray[$indexIN-1][1],$RecieversArray[$index][2], $RecieversArray[$index][3],  $RecieversArray[$index][4], $Remark]);
			@RecieverArrayFiltered[$Counter] = @NewRecieverConfigLine;	
			$Counter++;
			$index = $indexIN-1;	
		}
	}
	# print to console
	my $ReceiverFilteredNumber = @RecieverArrayFiltered;
	#print "ReceiverFilteredNumber: $ReceiverFilteredNumber\n";
	for (my $index=0; $index < $ReceiverFilteredNumber; $index++) {
		#printf "%20s %20s %20s %20s %10s %20s \n", $RecieverArrayFiltered[$index][0], $RecieverArrayFiltered[$index][1], $RecieverArrayFiltered[$index][2], $RecieverArrayFiltered[$index][3], $RecieverArrayFiltered[$index][4], $RecieverArrayFiltered[$index][5];
	}
	@RecieversArray = @RecieverArrayFiltered;
	$NumberOfReceivers = $ReceiverFilteredNumber;
	return (@RecieversArray)
}


sub AddHeaderOfType1() {
	my $FileName = $_[0];
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

	if (!defined($FileName) || $FileName eq '') {
		print $String;   
	} else {
		print $FileName $String;
	}
}


sub AddHeaderOfType2() {
	my $FileName = $_[0];
	my $StringType2 = " 

TYPE 002: STATION INFORMATION
-----------------------------

STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK
****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************
";

	if (!defined($FileName) || $FileName eq '') {
		print $StringType2;   
	} else {
		print $FileName $StringType2;
	}
}

sub AddHeaderOfTypes345() {
	my $FileName = $_[0];
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

	if (!defined($FileName) || $FileName eq '') {
		print $String;   
	} else {
		print $FileName $String;
	}
}

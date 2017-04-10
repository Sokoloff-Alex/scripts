#!/usr/bin/perl 
#
#-------------------------------------------------------------------
#
# Script : SiteLog2RNX.pl
#
# Usage : SiteLog2RNX.pl -i RNXObsFile -l SiteLogFile [-o CorrectedRNXObsFile -r ReportFile -s -m -no_correction_for_the_antenna_ADVNULLANTENNA]
#
# Author : Royal Observatory of Belgium
#
# Disclaimer : No responsibility is accepted by or on behalf of the ROB for any script errors.
#              The ROB will under no circumstances be held liable for any direct or indirect consequences,
#              nor for any damages that may occur from the use of this script (or any required other script).
#
# Purpose : RINEX observation file correction using information available from a log file (-l).
#           The correction can be made into the input file (-i) ... or into an optional output
#           file (-o). Reporting is optional (-r). Correction can be suppressed (-s). Suppression
#           of the message "HEADER CHANGED BY EPN CB ON ..." is possible (-m). Correction of the
#           antenna ADVNULLANTENNA is possible (-no_correction_for_the_antenna_ADVNULLANTENNA).
#
# Created : 2009-06-26
# Updated : 2009-11-23
# Updated : 2010-04-20 : OBSERVER / AGENCY corrected (if unknown)
# Updated : 2011-03-11 : receiver FV from log file limited to the 20 last characters (if necessary)
# Updated : 2012-03-02 : possibility to avoid adding the message "HEADER CHANGED BY EPN CB ON ..."
# Updated : 2012-07-19 : APPROX POSITION XYZ only corrected when the difference is higher than 10km
# Updated : 2012-08-21 : option added to avoid correction of the antenna ADVNULLANTENNA
#------------------------------------------------------------------------

use Getopt::Long;
use Cwd;
use Time::Local;
use Time::localtime;
use File::Basename;
use File::Copy;
use File::Temp qw/ tempfile tempdir /;
#use strict;
#use warnings;

sub usage()
{

 print STDERR << "EOF";
***************************************************************************
 usage: SiteLog2RNX.pl [-h] -i RINEXObservationFile -l SiteLogFile [-o CorrectedRINEXObservationFile] [-r ReportFile] [-s] [-m]

 -h                               : this (help) message
 -i RinexObservationFile          : the RINEX observation file as input for correction
 -l SiteLogFile                   : the site log file which will help to correct the RINEX observation file
 -o CorrectedRinexObservationFile : the RINEX observation file as output for correction (optional)
 -r ReportFile                    : the report file (optional)
 -s                               : suppress the correction (optional)
 -m                               : suppress the message "HEADER CHANGED BY EPN CB ON ..." (optional)
 -no_correction_for_the_antenna_ADVNULLANTENNA : no explanation needed (optional)

 example : SiteLog2RNX.pl -i /home/data/BRUS0520.99O -l /home/data/log/brus.log -o /home/data/corr/BRUS0520.99O -r /home/data/rep/report.txt
***************************************************************************

EOF
}



# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

my $login=`whoami`;
chop($login);

require "/home/${login}/scripts/ReadSiteLog.pl";  #path has to modified if necessary

my %option;
GetOptions (\%option, 'h', 'i=s','l=s', 'o=s', 'r=s', 's', 'm','no_correction_for_the_antenna_ADVNULLANTENNA');

my $rinexobservationfile;
my $doy_rinexfile;
my $year_rinexfile;
my $correctedrinexobservationfile;
my $path;
my $reportfile;
my $reportfile_action;
my $correction;

my $tm = localtime;
#print($tm->mday . "-" . ($tm->mon+1) . "-" . ($tm->year+1900) . "\n");

print("\n***************************************************************************\n");

#######################################################################
# DEFINE PROGRAM USER NAME
#######################################################################
my $user_id = 'EPN CB'; # operator/agency name limited to 20 characters
#######################################################################


#######################################################################
# CHECK FOR HELP OPTION
#######################################################################
if (defined($option{h})) # $opt_h
 {
  usage();
  exit;
 }
#######################################################################


#######################################################################
# CHECK FOR RINEX OBSERVATION FILE AS INPUT
#######################################################################
if (defined($option{i})) # $opt_i
{
   $rinexobservationfile = ($option{i});  # $opt_i
    if( -e $rinexobservationfile )
     {
	print("RINEX OBS. FILE (input)  : " . $rinexobservationfile . " exists\n");
        $doy_rinexfile = substr(basename($rinexobservationfile),4,3);
        $year_rinexfile = substr(basename($rinexobservationfile),9,2);
        if ($year_rinexfile < 80) { $year_rinexfile += 2000; }
        else { $year_rinexfile += 1900; }
     }
   else  
     {
	print("RINEX OBS. FILE (input)  : " . $rinexobservationfile . " does not exist\n");
        usage();
        exit;
     }
}
else
{
   print("RINEX OBS. FILE (input)  : missing mandatory option -i\n");
   usage();
   exit;
}
#######################################################################


#######################################################################
# CHECK FOR SITE LOG FILE
#######################################################################
if (defined($option{l}))   # $opt_l
{
   $sitelogfilename = ($option{l}); # $opt_l
    if( -e $sitelogfilename )
     {
	print("SITE LOG FILE            : " . $sitelogfilename . " exists\n");
     }
   else  
     {
	print("SITE LOG FILE            : " . $sitelogfilename . " does not exist\n");
        usage();
        exit;
     }
}
else
{
   print("SITE LOG FILE            : missing mandatory option -l\n");
   usage();
   exit;
}
#######################################################################


#######################################################################
# CHECK FOR RINEX OBSERVATION FILE AS OUTPUT
#######################################################################
if (defined($option{o}))  # $opt_o
{
   $correctedrinexobservationfile = ($option{o}); # $opt_o
   $path = dirname($correctedrinexobservationfile);

    if( -d $path )
     {
	print("RINEX OBS. DIR. (output) : " . $path . " exists\n");
     }
   else  
     {
	print("RINEX OBS. DIR. (output) : " . $path . " does not exist\n");
        usage();
        exit;
     }
}
else
{
   $correctedrinexobservationfile = $rinexobservationfile;
}
#######################################################################


#######################################################################
# CHECK FOR REPORTING
#######################################################################
if (defined($option{r}))  # $opt_r
{

   $reportfile = ($option{r});   # $opt_r
   $path = dirname($reportfile);

    if( -d $path )
     {
	#print("REPORT DIRECTORY      : " . $path . " exists\n");
        if(-e $reportfile) #APPEND
          {
            print("REPORT FILE              : " . $reportfile . " exists (appending)\n");
            $reportfile_action = 'append';
          }
        else #CREATE FILE
          {
            print("REPORT FILE              : " . $reportfile . " does not yet exist (creating)\n");
            $reportfile_action = 'create';
          }
     }
   else  
     {
	print("REPORT DIRECTORY         : " . $path . " does not exist\n");
        usage();
        exit;
     }
}
else
{
   $reportfile_action = '';
}
#######################################################################


#######################################################################
# CHECK FOR SUPPRESSING CORRECTION
#######################################################################
if (defined($option{s}))  # $opt_s
{
  print("SUPPRESS CORRECTION      : yes\n");
  $correction = 'no';
}
else
{
  print("SUPPRESS CORRECTION      : no\n");
  $correction = 'yes';
}
#######################################################################


#######################################################################
# CHECK FOR SUPPRESSING THE MESSAGE "HEADER CHANGED BY EPN CB ON ..."
#######################################################################
if (defined($option{m}))
{
  print("HEADER CHANGED MESSAGE   : no\n");
  $headerchangemessage = 'no';
}
else
{
  print("HEADER CHANGED MESSAGE   : yes\n");
  $headerchangemessage = 'yes';
}
#######################################################################

#######################################################################
# CHECK FOR AVOIDING THE CORRECTION OF THE ANTENNA ADVNULLANTENNA
#######################################################################
if (defined($option{no_correction_for_the_antenna_ADVNULLANTENNA}))
{
  print("AVOID CORRECTION OF THE ANTENNA ADVNULLANTENNA : yes\n");
  $correction_for_the_antenna_ADVNULLANTENNA = 'no';
}
else
{
  print("AVOID CORRECTION OF THE ANTENNA ADVNULLANTENNA : no\n");
  $correction_for_the_antenna_ADVNULLANTENNA = 'yes';
}
#######################################################################





print("***************************************************************************\n");


#######################################################################
# OPEN REPORT FILE (IF ASKED)
#######################################################################
if($reportfile_action eq 'append')
  {
    open (REPORTFile, ">>$reportfile");
  }

if($reportfile_action eq 'create')
  {
    open (REPORTFile, ">$reportfile");
  }

#######################################################################


#######################################################################
# CREATE TEMPORARY FILE
#######################################################################
my ($fh_temp, $file_temp) = tempfile("temporary_file_XXXX", UNLINK => 1); 
#######################################################################


#######################################################################
# READ HEADER OF INPUT FILE AND DETECT MISSING LINES
#######################################################################
my $observer_found = 'false';
my $xyz_found = 'false';
my $markername_found = 'false';
my $markernumber_found = 'false';
my $receiver_found = 'false';
my $antenna_found = 'false';
my $hen_found = 'false';

my @header;
my $numberlines = 0;
my $line;

open (INPUTFile, "$rinexobservationfile");
$line = <INPUTFile>;
while( (substr($line,60,13) ne 'END OF HEADER') && (!eof(INPUTFile)) )
 {
   if (
      ( substr($line,0,17) ne 'This observation ') &&
      ( substr($line,0,27) ne 'HEADER CHANGED BY EPN CB ON') &&
      ( substr($line,0,37) ne 'TO BE CONFORM WITH THE INFORMATION IN') &&
      ( substr($line,0,67) ne '                                                            COMMENT') &&
      ( substr($line,0,35) ne 'ftp://epncb.oma.be/pub/station/log/') &&
      ( substr($line,63,19) ne 'REC # / TYPE / VERS') # special case --> begin wrongly at position 63
      )
     {
       if (substr($line,60,11) eq 'MARKER NAME')         { $markername_found = 'true'; }
       if (substr($line,60,13) eq 'MARKER NUMBER')       { $markernumber_found = 'true'; }
       if (substr($line,60,17) eq 'OBSERVER / AGENCY')   { $observer_found = 'true'; }
       if (substr($line,60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) { $receiver_found = 'true'; }
       if (substr($line,60,20) =~ /\s*ANT\s*\#\s*\/\s*TYPE\s*/i ) { $antenna_found = 'true'; }
       if (substr($line,60,19) eq 'APPROX POSITION XYZ') { $xyz_found = 'true'; }
       if (substr($line,60,20) eq 'ANTENNA: DELTA H/E/N') { $hen_found = 'true'; }
       $numberlines++;
       $header[$numberlines] = $line;
     }
   $line = <INPUTFile>;
 }
close(INPUTFile);
#######################################################################



#######################################################################
# READ SITE LOG FILE
#######################################################################
&sitelogfilereading;

my $i;
my $receivertype_logfile;
my $receiverSN_logfile;
my $receiverFV_logfile;
my $receiver_foundinlog = 'false';
my $antennatype_logfile;
my $antennaSN_logfile;
my $antennaUP_logfile;
my $antennaNO_logfile;
my $antennaEA_logfile;
my $antennaradome_logfile;
my $antenna_foundinlog = 'false';

my $Agency;
my $Observer;

# OBSERVER - AGENCY
if ( ($agency_section12 ne '') && ($agency_section12 ne '(multiple lines)') ) { $Agency = $agency_section12; }
if ( ($preferredabbreviation_section12 ne '') && ($preferredabbreviation_section12 ne '(A10)') ) { $Agency = $preferredabbreviation_section12; }
if ( ($agency_section11 ne '') && ($agency_section11 ne '(multiple lines)') ) { $Agency = $agency_section11; }
if ( ($preferredabbreviation_section11 ne '') && ($preferredabbreviation_section11 ne '(A10)') ) { $Agency = $preferredabbreviation_section11; }
if (length($Agency) > 39) { $Agency = substr($Agency,0,37) . '..'; }

$Agency =~s/ç/c/g;
$Agency =~s/ø/o/g;
$Agency =~s/ó/o/g;
$Agency =~s/á/a/g;
$Agency =~s/ñ/n/g;
$Agency =~s/Ç/C/g;
$Agency =~s/Ø/O/g;
$Agency =~s/Ó/O/g;
$Agency =~s/Á/A/g;
$Agency =~s/Ñ/N/g;
$Agency =~s/È/E/g;
$Agency =~s/é/e/g;

for($counterletter=0;$counterletter<length($Agency);$counterletter++)
 {
   if ( (ord(substr($Agency,$counterletter,1)) < 32) or (ord(substr($Agency,$counterletter,1)) > 126) )
    { $Agency = substr($Agency,0,$counterletter-1) . '_' . substr($Agency,$counterletter+1,length($Agency)-$counterletter); }
 }

if ($primarycontact_contactname_section12 ne '') { $Observer = $primarycontact_contactname_section12; }
if ($primarycontact_contactname_section11 ne '') { $Observer = $primarycontact_contactname_section11; }
if (length($Observer) > 19) { $Observer = substr($Observer,0,17) . '..'; }

$Observer =~s/ç/c/g;
$Observer =~s/ø/o/g;
$Observer =~s/ó/o/g;
$Observer =~s/á/a/g;
$Observer =~s/ñ/n/g;
$Observer =~s/Ç/C/g;
$Observer =~s/Ø/O/g;
$Observer =~s/Ó/O/g;
$Observer =~s/Á/A/g;
$Observer =~s/Ñ/N/g;
$Observer =~s/È/E/g;
$Observer =~s/é/e/g;

for($counterletter=0;$counterletter<length($Observer);$counterletter++)
 {
   if ( (ord(substr($Observer,$counterletter,1)) < 32) or (ord(substr($Observer,$counterletter,1)) > 126) )
    { $Observer = substr($Observer,0,$counterletter-1) . '_' . substr($Observer,$counterletter+1,length($Observer)-$counterletter); }
 }

# RECEIVER
#print $doy_rinexfile . " - " . $year_rinexfile . "\n" . $number_receivers . " receivers\n";
for($i=1;$i<=$number_receivers;$i++)
  {
    if (
       ( $receiver{year_installed}[$i] . sprintf("%03d",$receiver{doy_installed}[$i])  le $year_rinexfile . sprintf("%03d",$doy_rinexfile) ) &&
       (
       ( $receiver{year_removed}[$i] . sprintf("%03d",$receiver{doy_removed}[$i])  ge $year_rinexfile . sprintf("%03d",$doy_rinexfile) ) ||
       ( $receiver{year_removed}[$i] . sprintf("%03d",$receiver{doy_removed}[$i])  eq "0000000" )
       )
       )
      {
        $receivertype_logfile = $receiver{type}[$i];
        $receiverSN_logfile = $receiver{serial_number}[$i];
        $receiverFV_logfile = $receiver{firmware_version}[$i];
        if (length($receiverFV_logfile) > 20) { $receiverFV_logfile = substr($receiverFV_logfile,length($receiverFV_logfile)-20,20); }
#        print($receiver{year_installed}[$i] . sprintf("%03d",$receiver{doy_installed}[$i]) .
#              " <= " . $year_rinexfile . sprintf("%03d",$doy_rinexfile) . " <= " .
#              $receiver{year_removed}[$i] . sprintf("%03d",$receiver{doy_removed}[$i]) . " --> receiver found\n");
        $receiver_foundinlog = 'true';

      }
    else
      {
#        print($receiver{year_installed}[$i] . sprintf("%03d",$receiver{doy_installed}[$i]) .
#              " <= " . $year_rinexfile . sprintf("%03d",$doy_rinexfile) . " <= " .
#              $receiver{year_removed}[$i] . sprintf("%03d",$receiver{doy_removed}[$i]) . " --> receiver not found\n");
      }

  }

# ANTENNA
for($i=1;$i<=$number_antennae;$i++)
  {
    if (
       ( $antenna{year_installed}[$i] . sprintf("%03d",$antenna{doy_installed}[$i])  le $year_rinexfile . sprintf("%03d",$doy_rinexfile) ) &&
       (
       ( $antenna{year_removed}[$i] . sprintf("%03d",$antenna{doy_removed}[$i])  ge $year_rinexfile . sprintf("%03d",$doy_rinexfile) ) ||
       ( $antenna{year_removed}[$i] . sprintf("%03d",$antenna{doy_removed}[$i])  eq "0000000" )
       )
       )
      {
        $antennatype_logfile = $antenna{type}[$i];
        $antennaSN_logfile = $antenna{serial_number}[$i];
        $antennaUP_logfile = $antenna{arp_up_ecc}[$i];
        $antennaNO_logfile = $antenna{arp_north_ecc}[$i];
        $antennaEA_logfile = $antenna{arp_east_ecc}[$i];
        $antennaradome_logfile = $antenna{antenna_radome_type}[$i];
#        print($antenna{year_installed}[$i] . sprintf("%03d",$antenna{doy_installed}[$i]) .
#              " <= " . $year_rinexfile . sprintf("%03d",$doy_rinexfile) . " <= " .
#              $antenna{year_removed}[$i] . sprintf("%03d",$antenna{doy_removed}[$i]) . " --> antenna found\n");
        $antenna_foundinlog = 'true';
      }
    else
      {
#        print($antenna{year_installed}[$i] . sprintf("%03d",$antenna{doy_installed}[$i]) .
#              " <= " . $year_rinexfile . sprintf("%03d",$doy_rinexfile) . " <= " .
#              $antenna{year_removed}[$i] . sprintf("%03d",$antenna{doy_removed}[$i]) . " --> antenna not found\n");
      }

  }

if ( (length($antennatype_logfile) < 20) && (length($antennaradome_logfile) == 4) )
  { $antennatype_logfile = sprintf("%-16s%4s",$antennatype_logfile,$antennaradome_logfile); }

if ( (length($antennatype_logfile) < 20) && (length($antennaradome_logfile) < 4) )
  { $antennatype_logfile = sprintf("%-16sNONE",$antennatype_logfile); }

if (length(trim($antennaNO_logfile)) == 0) { $antennaNO_logfile = '000.0000'; }
if (length(trim($antennaEA_logfile)) == 0) { $antennaEA_logfile = '000.0000'; }
if (length(trim($antennaUP_logfile)) == 0) { $antennaUP_logfile = '000.0000'; }
#######################################################################





#######################################################################
# CORRECT HEADER
#######################################################################
my $filename_extracted;
my @correctedheader;

#The first line has to remain the first
my $nb_lines_corr_head = 1;
$correctedheader[$nb_lines_corr_head] = $header[1];

#Message for notifying the header check/correction
if ($headerchangemessage eq 'yes')
{
$nb_lines_corr_head++;
$correctedheader[$nb_lines_corr_head] = sprintf("HEADER CHANGED BY EPN CB ON %0.4d-%0.2d-%0.2d                      COMMENT\n", ($tm->year+1900), ($tm->mon+1), $tm->mday);

$nb_lines_corr_head++;
$correctedheader[$nb_lines_corr_head] = "TO BE CONFORM WITH THE INFORMATION IN                       COMMENT\n";

$nb_lines_corr_head++;
$filename_extracted = basename($sitelogfilename);
$correctedheader[$nb_lines_corr_head] = sprintf("ftp://epncb.oma.be/pub/station/log/%-25sCOMMENT\n", $filename_extracted);

$nb_lines_corr_head++;
$correctedheader[$nb_lines_corr_head] = "                                                            COMMENT\n";
}

my $counterlines;


my $observer_corrected = 'false';
my $wrong_observer;
my $agency_corrected = 'false';
my $wrong_agency;

my $markername_corrected = 'false';
my $wrong_markername;
my $markernumber_corrected = 'false';
my $wrong_markernumber;
my $receivertype_corrected = 'false';
my $wrong_receivertype;
my $receiverSN_corrected = 'false';
my $wrong_receiverSN;
my $receiverFV_corrected = 'false';
my $wrong_receiverFV;
my $antennatype_corrected = 'false';
my $wrong_antennatype;
my $antennaSN_corrected = 'false';
my $wrong_antennaSN;
my $x_coordinate_corrected = 'false';
my $wrong_x_coordinate;
my $y_coordinate_corrected = 'false';
my $wrong_y_coordinate;
my $z_coordinate_corrected = 'false';
my $wrong_z_coordinate;
my $antennaNO_corrected = 'false';
my $wrong_antennaNO;
my $antennaEA_corrected = 'false';
my $wrong_antennaEA;
my $antennaUP_corrected = 'false';
my $wrong_antennaUP;
my $hen_added = 'false';


for($counterlines=2;$counterlines<=$numberlines;$counterlines++)
{
#print($header[$counterlines]);

# CORRECT LINES (IF NECESSARY)
# marker name
if (
   (substr($header[$counterlines],60,11) eq 'MARKER NAME') &&
   (substr($header[$counterlines],0,4) ne $four_character_id)
   )
  {
    $markername_corrected = 'true';
    $wrong_markername = substr($header[$counterlines],0,4);
#    $header[$counterlines] = $four_character_id . substr($header[$counterlines],4,56) . "MARKER NAME\n";
    $header[$counterlines] = sprintf("%-60sMARKER NAME\n",$four_character_id);
  }

# marker number
if (
   (substr($header[$counterlines],60,13) eq 'MARKER NUMBER') &&
   (substr($header[$counterlines],0,9) ne $iers_domes_number)
   )
  {
    $markernumber_corrected = 'true';
    $wrong_markernumber = substr($header[$counterlines],0,9);
    #$header[$counterlines] = $iers_domes_number . substr($header[$counterlines],9,51) . "MARKER NUMBER\n";
    $header[$counterlines] = sprintf("%-60sMARKER NUMBER\n",$iers_domes_number);
  }

# observer + agency
if (
   (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') &&
   (substr($header[$counterlines],0,20) =~ /\s*unknown\s*/i )
   )
  { $observer_corrected = 'true'; $wrong_observer = trim(substr($header[$counterlines],0,20)); }

if (
   (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') &&
   (substr($header[$counterlines],20,40) =~ /\s*unknown\s*/i )
   )
  { $agency_corrected = 'true'; $wrong_agency = trim(substr($header[$counterlines],20,40)); }

if (
   (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') &&
   ($observer_corrected eq 'true') &&
   ($agency_corrected eq 'true')
   )
  { $header[$counterlines] = sprintf("%-20s%-40sOBSERVER / AGENCY\n",$Observer,$Agency); }

if (
   (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') &&
   ($observer_corrected eq 'true') &&
   ($agency_corrected eq 'false')
   )
  { $header[$counterlines] = sprintf("%-20s%-40sOBSERVER / AGENCY\n",$Observer,trim(substr($header[$counterlines],20,40))); }

if (
   (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') &&
   ($observer_corrected eq 'false') &&
   ($agency_corrected eq 'true')
   )
  { $header[$counterlines] = sprintf("%-20s%-40sOBSERVER / AGENCY\n",trim(substr($header[$counterlines],0,20)),$Agency); }

# receiver type + SN + FV
if (
   (substr($header[$counterlines],60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) &&
   (trim(substr($header[$counterlines],20,20)) ne $receivertype_logfile) &&
   ($receiver_foundinlog eq 'true')
   )
  { $receivertype_corrected = 'true'; $wrong_receivertype = trim(substr($header[$counterlines],20,20)); }

if (
   (substr($header[$counterlines],60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) &&
   (trim(substr($header[$counterlines],0,20)) ne $receiverSN_logfile) &&
   ($receiver_foundinlog eq 'true')
   )
  { $receiverSN_corrected = 'true'; $wrong_receiverSN = trim(substr($header[$counterlines],0,20)); }

if (
   (substr($header[$counterlines],60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) &&
   (trim(substr($header[$counterlines],40,20)) ne $receiverFV_logfile) &&
   ($receiver_foundinlog eq 'true')
   )
  { $receiverFV_corrected = 'true'; $wrong_receiverFV = trim(substr($header[$counterlines],40,20)); }

if (
   (substr($header[$counterlines],60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) &&
   (
   ($receivertype_corrected eq 'true') ||
   ($receiverSN_corrected eq 'true') ||
   ($receiverFV_corrected eq 'true')
   )
   )
  { $header[$counterlines] = sprintf("%-20s%-20s%-20sREC # / TYPE / VERS",$receiverSN_logfile,$receivertype_logfile,$receiverFV_logfile) . "\n"; }     

# antenna type + SN
if (
   (substr($header[$counterlines],60,20) =~ /\s*ANT\s*\#\s*\/\s*TYPE\s*/i ) &&
   (trim(substr($header[$counterlines],20,20)) ne $antennatype_logfile) &&
   ($antenna_foundinlog eq 'true')
   )
  {
    if (
        ($correction_for_the_antenna_ADVNULLANTENNA eq 'yes') or
        (
         ($correction_for_the_antenna_ADVNULLANTENNA eq 'no') and
         (trim(substr($header[$counterlines],20,20)) ne 'ADVNULLANTENNA')
        )
       )
      { $antennatype_corrected = 'true'; $wrong_antennatype = trim(substr($header[$counterlines],20,20)); }
  }

if (
   (substr($header[$counterlines],60,20) =~ /\s*ANT\s*\#\s*\/\s*TYPE\s*/i ) &&
   (trim(substr($header[$counterlines],0,20)) ne $antennaSN_logfile) &&
   ($antenna_foundinlog eq 'true')
   )
  { $antennaSN_corrected = 'true'; $wrong_antennaSN = trim(substr($header[$counterlines],0,20)); }

if (
   (substr($header[$counterlines],60,20) =~ /\s*ANT\s*\#\s*\/\s*TYPE\s*/i ) &&
   (
   ($antennatype_corrected eq 'true') ||
   ($antennaSN_corrected eq 'true')
   )
   )
  { $header[$counterlines] = sprintf("%-20s%-20s                    ANT # / TYPE",$antennaSN_logfile,$antennatype_logfile) . "\n"; }

# XYZ
if (
   (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') &&
   (abs(trim(substr($header[$counterlines],0,14)) - $x_coordinate) >= 10000)
   )
   { $x_coordinate_corrected = 'true';  $wrong_x_coordinate = trim(substr($header[$counterlines],0,14));
   }
   
if (
   (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') &&
   (abs(trim(substr($header[$counterlines],14,14)) - $y_coordinate) >= 10000)
   )
   { $y_coordinate_corrected = 'true'; $wrong_y_coordinate = trim(substr($header[$counterlines],14,14));
   }

if (
   (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') &&
   (abs(trim(substr($header[$counterlines],28,14)) - $z_coordinate) >= 10000)
   )
   { $z_coordinate_corrected = 'true'; $wrong_z_coordinate = trim(substr($header[$counterlines],28,14));
   }
  
if (
   (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') &&
   (
   ($x_coordinate_corrected eq 'true') ||
   ($y_coordinate_corrected eq 'true') ||
   ($z_coordinate_corrected eq 'true')
   )
   )
   { $header[$counterlines] = sprintf("%14.4f%14.4f%14.4f                  APPROX POSITION XYZ",$x_coordinate,$y_coordinate,$z_coordinate) . "\n"; }

# XYZ - if x = 0, y = 0, z = 0
if (
   (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') &&
   (trim(substr($header[$counterlines],0,14)) == 0.0) &&
   (trim(substr($header[$counterlines],14,14)) == 0.0) &&
   (trim(substr($header[$counterlines],28,14)) == 0.0)
   )
   {
     $x_coordinate_corrected = 'true';  $wrong_x_coordinate = trim(substr($header[$counterlines],0,14));
     $y_coordinate_corrected = 'true'; $wrong_y_coordinate = trim(substr($header[$counterlines],14,14));
     $z_coordinate_corrected = 'true'; $wrong_z_coordinate = trim(substr($header[$counterlines],28,14));
     $header[$counterlines] = sprintf("%14.4f%14.4f%14.4f                  APPROX POSITION XYZ",$x_coordinate,$y_coordinate,$z_coordinate) . "\n";
   }

# HEN
if (
   (substr($header[$counterlines],60,20) eq 'ANTENNA: DELTA H/E/N') &&
   (trim(substr($header[$counterlines],28,14)) != $antennaNO_logfile) &&
   ($antenna_foundinlog eq 'true')
   )
  { $antennaNO_corrected = 'true'; $wrong_antennaNO = trim(substr($header[$counterlines],28,14)); }

if (
   (substr($header[$counterlines],60,20) eq 'ANTENNA: DELTA H/E/N') &&
   (trim(substr($header[$counterlines],14,14)) != $antennaEA_logfile) &&
   ($antenna_foundinlog eq 'true')
   )
  { $antennaEA_corrected = 'true'; $wrong_antennaEA = trim(substr($header[$counterlines],14,14)); }   

if (
   (substr($header[$counterlines],60,20) eq 'ANTENNA: DELTA H/E/N') &&
   (trim(substr($header[$counterlines],0,14)) != $antennaUP_logfile) &&
   ($antenna_foundinlog eq 'true')
   )
  { $antennaUP_corrected = 'true'; $wrong_antennaUP = trim(substr($header[$counterlines],0,14)); }

if (
   (substr($header[$counterlines],60,20) eq 'ANTENNA: DELTA H/E/N') &&
   (
   ($antennaNO_corrected eq 'true') ||
   ($antennaEA_corrected eq 'true') ||
   ($antennaUP_corrected eq 'true')
   )
   )
   { $header[$counterlines] = sprintf("%14.4f%14.4f%14.4f                  ANTENNA: DELTA H/E/N",$antennaUP_logfile, $antennaEA_logfile, $antennaNO_logfile) . "\n"; }

#print($header[$counterlines]);

# COPY FROM OLD LINES TO NEW LINES
$nb_lines_corr_head++;
$correctedheader[$nb_lines_corr_head] = $header[$counterlines];

#print($correctedheader[$nb_lines_corr_head]);

# ADD MISSING LINES
# after 'PGM / RUN BY / DATE'
if ( ($markername_found eq 'false') && (substr($header[$counterlines],60,19) eq 'PGM / RUN BY / DATE') )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = $four_character_id . "                                                        MARKER NAME\n"; }

# after 'MARKER NAME'
if ( ($markernumber_found eq 'false') && (substr($header[$counterlines],60,11) eq 'MARKER NAME') )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = $iers_domes_number . "                                                   MARKER NUMBER\n"; }

# after 'MARKER NUMBER'
if ( ($observer_found eq 'false') && (substr($header[$counterlines],60,13) eq 'MARKER NUMBER') )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = sprintf("%-20s%-40sOBSERVER / AGENCY",$Observer,$Agency) . "\n"; }

# after 'OBSERVER / AGENCY'
if ( ($receiver_found eq 'false') && (substr($header[$counterlines],60,17) eq 'OBSERVER / AGENCY') )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = sprintf("%-20s%-20s%-20sREC # / TYPE / VERS\n",$receiverSN_logfile,$receivertype_logfile,$receiverFV_logfile); }

# after 'REC # / TYPE / VERS'
if ( ($antenna_found eq 'false') && (substr($header[$counterlines],60,20) =~ /\s*REC\s*\#\s*\/\s*TYPE\s*\/\s*VERS\s*/i ) )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = sprintf("%-20s%-20s                    ANT # / TYPE\n",$antennaSN_logfile,$antennatype_logfile); }

# after 'ANT # / TYPE'
if ( ($xyz_found eq 'false') && (substr($header[$counterlines],60,20) =~ /\s*ANT\s*\#\s*\/\s*TYPE\s*/i ) )
{ $nb_lines_corr_head++; $correctedheader[$nb_lines_corr_head] = sprintf("%14.4f%14.4f%14.4f                  APPROX POSITION XYZ\n",$x_coordinate,$y_coordinate,$z_coordinate); }

# after 'APPROX POSITION XYZ'
if ( ($hen_found eq 'false') && (substr($header[$counterlines],60,19) eq 'APPROX POSITION XYZ') )
{
 $hen_added = 'true';
 $nb_lines_corr_head++;
 $correctedheader[$nb_lines_corr_head] = sprintf("%14.4f%14.4f%14.4f                  ANTENNA: DELTA H/E/N\n",$antennaUP_logfile, $antennaEA_logfile, $antennaNO_logfile);
}

#print($correctedheader[$nb_lines_corr_head]);

}



# ADD MISSING LINES IF NOT YET ADDED (IF NORMAL PREVIOUS LINE WAS MISSING )
if ( ($hen_found eq 'false') && ($hen_added eq 'false') )
{
 $correctedheader[$nb_lines_corr_head] = sprintf("%14.4f%14.4f%14.4f                  ANTENNA: DELTA H/E/N\n",$antennaUP_logfile, $antennaEA_logfile, $antennaNO_logfile);
 $nb_lines_corr_head++;
 $correctedheader[$nb_lines_corr_head] = "                                                            END OF HEADER\n";
}

#######################################################################



#######################################################################
# WRITE CORRECTED HEADER TO TEMPORARY FILE
#######################################################################
for($counterlines=1;$counterlines<=$nb_lines_corr_head;$counterlines++)
{
  print $fh_temp $correctedheader[$counterlines];
  #print $correctedheader[$counterlines];
}
#######################################################################



#######################################################################
# READ AND CORRECT BODY OF RINEX INPUT FILE
#######################################################################
my $body_corrected = 'false';

open (INPUTFile, "$rinexobservationfile");

$line = <INPUTFile>;
while( (substr($line,60,13) ne 'END OF HEADER') && (!eof(INPUTFile)) )
 { $line = <INPUTFile>; }

while (!eof(INPUTFile))
 {
   if ( substr($line,0,29) ne '                            4' )
     {
       print $fh_temp $line;
     }
   else
     {
       my $numberlines2remove = trim(substr($line,29,3));
       $body_corrected = 'true';
       for($counterlines=1;$counterlines<=$numberlines2remove;$counterlines++)
         {
           $line = <INPUTFile>;
           #print "$counterlines $line";
         }
     }
   $line = <INPUTFile>;
 }

print $fh_temp $line;
close(INPUTFile);
#######################################################################


#######################################################################
# DELETE TEMPORARY FILE
#######################################################################
close($fh_temp);
#######################################################################


#######################################################################
# COPY INSTANCE VERS OUTPUT (IF ASKED)
#######################################################################
if ($correction eq 'yes')
{
#rename($file_temp,$correctedrinexobservationfile);  # $fh_temp
copy($file_temp,$correctedrinexobservationfile) or die "$file_temp cannot be copied to $correctedrinexobservationfile.";
}
#######################################################################




#######################################################################
# WRITE REPORT ON SCREEN
#######################################################################
#my $extracted_rinexfilename = basename($correctedrinexobservationfile);
my $extracted_rinexfilename = basename($rinexobservationfile);
my $inconsistency_found = 'false';

if ($body_corrected eq 'true')         { $inconsistency_found = 'true'; print "$extracted_rinexfilename | OBSERVATIONS         | double header removed\n"; }
if ($markername_corrected eq 'true')   { $inconsistency_found = 'true'; print "$extracted_rinexfilename | MARKER NAME          | corrected ($wrong_markername -> $four_character_id)\n"; }
if ($markernumber_corrected eq 'true') { $inconsistency_found = 'true'; print "$extracted_rinexfilename | MARKER NUMBER        | corrected ($wrong_markernumber -> $iers_domes_number)\n"; }
if ($observer_corrected eq 'true')     { $inconsistency_found = 'true'; print "$extracted_rinexfilename | OBSERVER             | corrected ($wrong_observer -> $Observer)\n"; }
if ($agency_corrected eq 'true')       { $inconsistency_found = 'true'; print "$extracted_rinexfilename | AGENCY               | corrected ($wrong_agency -> $Agency)\n"; }
if ($receivertype_corrected eq 'true') { $inconsistency_found = 'true'; print "$extracted_rinexfilename | RECEIVER TYPE        | corrected ($wrong_receivertype -> $receivertype_logfile)\n"; }
if ($receiverSN_corrected eq 'true')   { $inconsistency_found = 'true'; print "$extracted_rinexfilename | RECEIVER SER. NO.    | corrected ($wrong_receiverSN -> $receiverSN_logfile)\n"; }
if ($receiverFV_corrected eq 'true')   { $inconsistency_found = 'true'; print "$extracted_rinexfilename | RECEIVER FIRM. VERS. | corrected ($wrong_receiverFV -> $receiverFV_logfile)\n"; }
if ($antennatype_corrected eq 'true')  { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA TYPE         | corrected ($wrong_antennatype -> $antennatype_logfile)\n"; }
if ($antennaSN_corrected eq 'true')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA SER. NO.     | corrected ($wrong_antennaSN -> $antennaSN_logfile)\n"; }
if ($x_coordinate_corrected eq 'true') { $inconsistency_found = 'true'; print "$extracted_rinexfilename | APPROX POSITION X    | corrected ($wrong_x_coordinate -> $x_coordinate)\n"; }
if ($y_coordinate_corrected eq 'true') { $inconsistency_found = 'true'; print "$extracted_rinexfilename | APPROX POSITION Y    | corrected ($wrong_y_coordinate -> $y_coordinate)\n"; }
if ($z_coordinate_corrected eq 'true') { $inconsistency_found = 'true'; print "$extracted_rinexfilename | APPROX POSITION Z    | corrected ($wrong_z_coordinate -> $z_coordinate)\n"; }
if ($antennaNO_corrected eq 'true')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA DELTA NORTH  | corrected ($wrong_antennaNO -> $antennaNO_logfile)\n"; }
if ($antennaEA_corrected eq 'true')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA DELTA EAST   | corrected ($wrong_antennaEA -> $antennaEA_logfile)\n"; }
if ($antennaUP_corrected eq 'true')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA DELTA UP     | corrected ($wrong_antennaUP -> $antennaUP_logfile)\n"; }

if ($receiver_foundinlog eq 'false')   { $inconsistency_found = 'true'; print "$extracted_rinexfilename | SITE LOG             | receiver not installed\n"; }
if ($antenna_foundinlog eq 'false')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | SITE LOG             | antenna not installed\n"; }

if ($observer_found eq 'false')        { $inconsistency_found = 'true'; print "$extracted_rinexfilename | OBSERVER / AGENCY    | line added\n"; }
if ($xyz_found eq 'false')             { $inconsistency_found = 'true'; print "$extracted_rinexfilename | APPROX POSITION XYZ  | line added\n"; }
if ($markername_found eq 'false')      { $inconsistency_found = 'true'; print "$extracted_rinexfilename | MARKER NAME          | line added\n"; }
if ($markernumber_found eq 'false')    { $inconsistency_found = 'true'; print "$extracted_rinexfilename | MARKER NUMBER        | line added\n"; }
if ($receiver_found eq 'false')        { $inconsistency_found = 'true'; print "$extracted_rinexfilename | REC # / TYPE / VERS  | line added\n"; }
if ($antenna_found eq 'false')         { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANT # / TYPE         | line added\n"; }
if ($hen_found eq 'false')             { $inconsistency_found = 'true'; print "$extracted_rinexfilename | ANTENNA: DELTA H/E/N | line added\n"; }

if ($inconsistency_found eq 'false')   { print "$extracted_rinexfilename | No inconsistency     |\n"; }
#######################################################################


#######################################################################
# WRITE AND CLOSE REPORT FILE (IF ASKED)
#######################################################################
if ($reportfile_action ne '')
  {
    $report_time = sprintf("%0.4d-%0.2d-%0.2d %0.2d:%0.2d UTC", ($tm->year+1900), ($tm->mon+1), $tm->mday, $tm->hour, $tm->min);

    if ($body_corrected eq 'true')         { print REPORTFile "$report_time | $extracted_rinexfilename | OBSERVATIONS         | double header removed\n"; }
    if ($markername_corrected eq 'true')   { print REPORTFile "$report_time | $extracted_rinexfilename | MARKER NAME          | corrected ($wrong_markername -> $four_character_id)\n"; }
    if ($markernumber_corrected eq 'true') { print REPORTFile "$report_time | $extracted_rinexfilename | MARKER NUMBER        | corrected ($wrong_markernumber -> $iers_domes_number)\n"; }
    if ($observer_corrected eq 'true')     { print REPORTFile "$report_time | $extracted_rinexfilename | OBSERVER             | corrected ($wrong_observer -> $Observer)\n"; }
    if ($agency_corrected eq 'true')       { print REPORTFile "$report_time | $extracted_rinexfilename | AGENCY               | corrected ($wrong_agency -> $Agency)\n"; }
    if ($receivertype_corrected eq 'true') { print REPORTFile "$report_time | $extracted_rinexfilename | RECEIVER TYPE        | corrected ($wrong_receivertype -> $receivertype_logfile)\n"; }
    if ($receiverSN_corrected eq 'true')   { print REPORTFile "$report_time | $extracted_rinexfilename | RECEIVER SER. NO.    | corrected ($wrong_receiverSN -> $receiverSN_logfile)\n"; }
    if ($receiverFV_corrected eq 'true')   { print REPORTFile "$report_time | $extracted_rinexfilename | RECEIVER FIRM. VERS. | corrected ($wrong_receiverFV -> $receiverFV_logfile)\n"; }
    if ($antennatype_corrected eq 'true')  { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA TYPE         | corrected ($wrong_antennatype -> $antennatype_logfile)\n"; }
    if ($antennaSN_corrected eq 'true')    { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA SER. NO.     | corrected ($wrong_antennaSN -> $antennaSN_logfile)\n"; }
    if ($x_coordinate_corrected eq 'true') { print REPORTFile "$report_time | $extracted_rinexfilename | APPROX POSITION X    | corrected ($wrong_x_coordinate -> $x_coordinate)\n"; }
    if ($y_coordinate_corrected eq 'true') { print REPORTFile "$report_time | $extracted_rinexfilename | APPROX POSITION Y    | corrected ($wrong_y_coordinate -> $y_coordinate)\n"; }
    if ($z_coordinate_corrected eq 'true') { print REPORTFile "$report_time | $extracted_rinexfilename | APPROX POSITION Z    | corrected ($wrong_z_coordinate -> $z_coordinate)\n"; }
    if ($antennaNO_corrected eq 'true')    { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA DELTA NORTH  | corrected ($wrong_antennaNO -> $antennaNO_logfile)\n"; }
    if ($antennaEA_corrected eq 'true')    { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA DELTA EAST   | corrected ($wrong_antennaEA -> $antennaEA_logfile)\n"; }
    if ($antennaUP_corrected eq 'true')    { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA DELTA UP     | corrected ($wrong_antennaUP -> $antennaUP_logfile)\n"; }

    if ($receiver_foundinlog eq 'false')   { print REPORTFile "$report_time | $extracted_rinexfilename | SITE LOG             | receiver not installed\n"; }
    if ($antenna_foundinlog eq 'false')    { print REPORTFile "$report_time | $extracted_rinexfilename | SITE LOG             | antenna not installed\n"; }

    if ($observer_found eq 'false')        { print REPORTFile "$report_time | $extracted_rinexfilename | OBSERVER / AGENCY    | line added\n"; }
    if ($xyz_found eq 'false')             { print REPORTFile "$report_time | $extracted_rinexfilename | APPROX POSITION XYZ  | line added\n"; }
    if ($markername_found eq 'false')      { print REPORTFile "$report_time | $extracted_rinexfilename | MARKER NAME          | line added\n"; }
    if ($markernumber_found eq 'false')    { print REPORTFile "$report_time | $extracted_rinexfilename | MARKER NUMBER        | line added\n"; }
    if ($receiver_found eq 'false')        { print REPORTFile "$report_time | $extracted_rinexfilename | REC # / TYPE / VERS  | line added\n"; }
    if ($antenna_found eq 'false')         { print REPORTFile "$report_time | $extracted_rinexfilename | ANT # / TYPE         | line added\n"; }
    if ($hen_found eq 'false')             { print REPORTFile "$report_time | $extracted_rinexfilename | ANTENNA: DELTA H/E/N | line added\n"; }

    if ($inconsistency_found eq 'false')   { print REPORTFile "$report_time | $extracted_rinexfilename | No inconsistency     |\n"; }
    
    close(REPORTFile);
  }
#######################################################################

print("***************************************************************************\n\n");

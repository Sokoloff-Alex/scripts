#!/usr/bin/perl 
#-------------------------------------------------------------------
#
# script : CheckStationLogs.pl
#
# usage : CheckStationLogs.pl -l StationLogsDirectory -r ReferencesDirectory
#
# Author : Royal Observatory of Belgium
#
# Disclaimer : No responsibility is accepted by or on behalf of the ROB for any script errors.
#              The ROB will under no circumstances be held liable for any direct or indirect consequences,
#              nor for any damages that may occur from the use of this script (or any required other script).
#
# Purpose : checks all information from the station log files available from a directory (-l) using
#           mandatory reference files (-r) (antenna.gra, rcvr_ant.tab ... and epn_08.atx if optional EPN-strict)
#
# Created : 2016-01-05
# Updated : 
#------------------------------------------------------------------------

select(STDERR); $| = 1;         # flush output buffer (STDERR)
select(STDOUT); $| = 1;         # flush output buffer (STDOUT)

use Getopt::Long;
use Getopt::Std;
use Cwd;
use Time::Local;
use Time::localtime;
use File::Basename;
use File::Copy;
use File::Temp qw/ tempfile tempdir /;
use File::Spec;
#use strict;
#use warnings;
use Date::Calc qw(:all);


sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub usage()
{

 print STDERR << "EOF";
***************************************************************************
 usage: CheckStationLogs.pl [-h] -l StationLogsDirectory -r ReferencesDirectory [-c CurrentLogDirectory] [-s]

 -h                               : this (help) message
 -l StationLogsDirectory          : the station logs directory -> MANDATORY
 -r ReferencesDirectory           : the reference files (antenna.gra, rcvr_ant.tab) directory -> MANDATORY
 -c CurrentLogDirectory           : the current station logs directory -> OPTIONAL
 -s                               : the check of the logs will be EPN-strict -> OPTIONAL

 example : CheckStationLogs.pl -l /home/user/logs -r /home/user/references
***************************************************************************

EOF
}

sub check_stationlogdate
{
my $stationlogdate = $_[0]; #print('-' . $stationlogdate . "-\n");

my $tm = localtime;
my $day = $tm->mday;
my $month = $tm->mon+1;
my $year = $tm->year+1900;

$error_stationlogdate = '';

if (
   ($stationlogdate !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z$/ )
   &&
   ($stationlogdate !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ )
   )
    {
      $error_stationlogdate = 'missing (or incomplete) input. Complete date --> CCYY-MM-DD ... or date/time --> CCYY-MM-DDThh:mmZ';
    }
else
    {



      if (
         (substr($stationlogdate,0,4) < 1800 ) ||
         (substr($stationlogdate,0,4) > $year) ||
         !(check_date(substr($stationlogdate,0,4), substr($stationlogdate,5,2), substr($stationlogdate,8,2))) ||
	 (
           (length($stationlogdate) == 17) &&
           (
           (substr($stationlogdate,11,2) < '00') ||
           (substr($stationlogdate,11,2) > '23') ||
           (substr($stationlogdate,14,2) < '00') ||
           (substr($stationlogdate,14,2) > '59')
           )
         )	 	
         ) 
          {
             $error_stationlogdate = 'senseless date';
          }
    }

return $error_stationlogdate;
}	 	 














my %option;
GetOptions (\%option, 'h', 'l=s', 'r=s', 'c=s', 's');

my $line;
my $i;

my $tm = localtime;
my $day = $tm->mday;
my $month = $tm->mon+1;
my $year = $tm->year+1900;

#######################################################################
# CHECK FOR HELP OPTION
#######################################################################
if (defined($option{h}))
 {
  usage();
  exit;
 }
#######################################################################


#######################################################################
# CHECK FOR THE EPN-STRICT OPTION --> OPTIONAL
#######################################################################
if (defined($option{s}))
 {
   $epnstrict = 'true';
 }
else
 {
   $epnstrict = 'false';
 }
#######################################################################




print("\n" . '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' . "\n");

#######################################################################
# CHECK FOR STATION LOGS DIRECTORY --> MANDATORY
#######################################################################
if (defined($option{l}))
{
   $stationlogsdirectory = ($option{l});

    if( -d $stationlogsdirectory )
     {
        if(substr($stationlogsdirectory,-1,1) ne '/') { $stationlogsdirectory = $stationlogsdirectory . '/'; }
	print("STATION LOGS DIRECTORY              : " . $stationlogsdirectory . " exists\n");
        @logfiles = glob($stationlogsdirectory . '*.log');
        #foreach (@logfiles) { print "$_\n"; }
     }
   else  
     {
	print("STATION LOGS DIRECTORY              : " . $stationlogsdirectory . " does not exist\n");
        usage();
        exit;
     }
}
else
{
  usage();
  exit;
}
#######################################################################

#######################################################################
# CHECK FOR REFERENCE FILES --> MANDATORY
#######################################################################
if (defined($option{r}))
{
   $referencefilesdirectory = ($option{r});
   if( -d $referencefilesdirectory )
     {
        if(substr($referencefilesdirectory,-1,1) ne '/') { $referencefilesdirectory = $referencefilesdirectory . '/'; }
	print("REFERENCE FILES DIRECTORY           : " . $referencefilesdirectory . " exists\n");
        $hardwaretablesfile = $referencefilesdirectory . 'rcvr_ant.tab';
        $antennareferencepointsfile = $referencefilesdirectory . 'antenna.gra';
        #$receiversatsysinfofile = $referencefilesdirectory . 'rec_info.txt';
        $atxfile = $referencefilesdirectory . 'epn_08.atx';


        if(-e $hardwaretablesfile)
          {
            print("HARDWARE TABLES FILE (rcvr-ant.tab) : " . $hardwaretablesfile . " exists\n");
          }
        else
          {
            print("HARDWARE TABLES FILE (rcvr-ant.tab) : " . $hardwaretablesfile . " does not exist\n");
            usage();
            exit;
          }

        if(-e $antennareferencepointsfile)
          {
            print("ARP FILE (antenna.gra)              : " . $antennareferencepointsfile . " exists\n");
          }
        else
          {
            print("ARP FILE (antenna.gra)              : " . $antennareferencepointsfile . " does not exist\n");
            usage();
            exit;
          }

=pod
        if(-e $receiversatsysinfofile)
          {
            print("RECEIVER INFO FILE (rec_info.txt)   : " . $receiversatsysinfofile . " exists\n");
          }
        else
          {
            print("RECEIVER INFO FILE (rec_info.txt)   : " . $receiversatsysinfofile . " does not exist\n");
            usage();
            exit;
          }
=cut

        if ($epnstrict eq 'true')
        {
        if(-e $atxfile)
          {
            print("ATX FILE (epn_08.atx)                          : " . $atxfile . " exists\n");
          }
        else
          {
            print("ATX FILE (epn_08.atx)                          : " . $atxfile . " does not exist\n");
            usage();
            exit;
          }
        }




     }
   else  
     {
	print("REFERENCE FILES DIRECTORY           : " . $referencefilesdirectory . " does not exist\n");
        usage();
        exit;
     }
}
else
{
  usage();
  exit;
}
#######################################################################





#######################################################################
# CHECK FOR CURRENT STATION LOGS DIRECTORY --> OPTIONAL
#######################################################################
if (defined($option{c}))
{
   $currentstationlogsdirectory = ($option{c});

    if( -d $currentstationlogsdirectory )
     {
        if(substr($currentstationlogsdirectory,-1,1) ne '/') { $currentstationlogsdirectory = $currentstationlogsdirectory . '/'; }
	print("CURRENT STATION LOGS DIRECTORY      : " . $currentstationlogsdirectory . " exists\n");
     }
   else  
     {
	print("CURRENT STATION LOGS DIRECTORY              : " . $currentstationlogsdirectory . " does not exist\n");
        usage();
        exit;
     }
}
else
{
$currentstationlogsdirectory = '';
}
#######################################################################


print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' . "\n");




foreach (@logfiles)
 {
  $encounteredproblem = '';

  $logfile=basename("$_");
  
  $fourid = uc(substr($logfile,0,4));

  print("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\nLog file: $_\n\n");

  open (LogFile, "$_") || die "Cannot open $_";

  #######################################################################
  # READ SECTION 0.
  #######################################################################
  #print (" read 0\n");
  $markername_firstline = '';
  while ( ( $line !~ /^1.\s*Site\s*Identification\s*of\s*the\s*GNSS\s*Monument\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;

       my @test_firstline = split(/\s+/,$line); #print $test_firstline[1]  . "\n";
       if ( ($test_firstline[2] eq 'Site') && ($test_firstline[3] eq 'Information') && ($test_firstline[4] eq 'Form') ) { $markername_firstline = $test_firstline[1]; }
       if (substr($line,0,32) =~ /\s*SitePrepared\s*by\s*\(full name\)\s*/i ) { $prepared_by = trim(substr($line,32,length($line)-33)); } 

       if (substr($line,0,32) =~ /\s*Prepared\s*by\s*\(full name\)\s*/i ) { $prepared_by = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Date\s*Prepared\s*/i )               { $date_prepared = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Report\s*Type\s*/i )                 { $report_type = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Previous\s*Site\s*Log\s*/i )         { $previous_site_log = trim(substr($line,32,length($line)-33)); } 

       if (substr($line,0,32) =~ /\s*Modified\/Added\s*Sections\s*/i )
              {
                  $modified_added_sections = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $modified_added_sections .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Sections 0 and 1 - no empty line between these two sections'; }

              } 

     }

   $prepared_by =~s/ç/&ccedil;/g;
   $prepared_by =~s/Ã§/&ccedil;/g;
   $prepared_by =~s/ó/&oacute;/g;
   $prepared_by =~s/Ã³/&oacute;/g;

   $prepared_by =~s/é/&eacute;/g;
   $prepared_by =~s/Ã©/&eacute;/g;
   
   $prepared_by =~s/á/&aacute;/g;
   $prepared_by =~s/Ã¡/&aacute;/g;
  
   $prepared_by =~s/\'/&#39;/g;
   $prepared_by =~s/"/&#39;/g;

#   if($prepared_by =~s/ü/&uuml;/g)  { print "\nPrepared by  : $prepared_by"; } #
   $prepared_by =~s/ü/&uuml;/g;

   $prepared_by =~s/ñ/&ntilde;/g;

   if ($markername_firstline ne $fourid)
    {
      print('Header - ' . $markername_firstline . ' Site Information Form (site log) : missing or wrong marker name' . "\n");
    }

   if (length(trim($prepared_by)) == 0)
    {
      #print "Prepared by  : $prepared_by\n";
      print('Section 0 - Prepared by : missing input (full name)' . "\n");
    }

   if ($date_prepared !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ )
    {
      #print "Date Prepared : $date_prepared\n";
      print('Section 0 - Date Prepared : missing (or incomplete) input. Complete date (CCYY-MM-DD)' . "\n");
    }
   else
    {
      if (
         (substr($date_prepared,0,4) < 1800 ) ||
         (substr($date_prepared,0,4) > $year) ||
         !(check_date(substr($date_prepared,0,4), substr($date_prepared,5,2), substr($date_prepared,8,2)))
         )				 
          {
           #print "Date Prepared : $date_prepared\n";
           print('Section 0 - Date Prepared : senseless date' . "\n");
          }
    }

   if ( ($report_type ne 'NEW') && ($report_type ne 'UPDATE') )
    {
      print('Section 0 - Report Type : invalid format. Use NEW or UPDATE.' . "\n");
    }



   if (
      ( ($previous_site_log !~ /^[a-z0-9]{4}_[0-9]{8}\.log$/ ) || (substr($previous_site_log,0,4) ne lc($fourid) ) ) &&
      ($report_type ne 'NEW')
      ) 
       {
         print('Section 0 - Previous Site Log : invalid format. Use ssss_yyyymmdd.log.' . "\n");
       }
   else
       {
        if($currentstationlogsdirectory ne '')
         {
           if(@filename = glob($currentstationlogsdirectory . lc($fourid) . "*.log"))
            {
              #print($currentstationlogsdirectory . lc($fourid) . "*.log\n" . $filename[0] . "\n");

             if (basename($filename[0]) ne $previous_site_log)
              {
               print('Section 0 - Previous Site Log : expected ' . basename($filename[0]) . "\n");
              }

            }

         }
       }

    if (substr($previous_site_log,5,8) eq sprintf("%04d%02d%02d",$year,$month,$day))
     {
       print('Today, a station log file for ' . $fourid . ' already has been submitted successfully. Please contact the EPN CB!' . "\n");
     }








#  print "$fourid\n";
#  print "$date_prepared\n";
#  print "$report_type\n";
#  print "$previous_site_log\n";
#  print "$modified_added_sections\n";

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 1 - title of that section not found.'; }

  #######################################################################
  # READ SECTION 1.
  #######################################################################
  #print (" read 1\n");
  while ( ($line !~ /^2.\s*Site\s*Location\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if (substr($line,0,32) =~ /\s*Site\s*Name\s*/i )                  { $site_name = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Four\s*Character\s*ID\s*/i )        { $four_character_id = trim(substr($line,32,4)); } 
       if (substr($line,0,32) =~ /\s*Monument\s*Inscription\s*/i )       { $monument_inscription = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*IERS\s*DOMES\s*Number\s*/i )        { $iers_domes_number = trim(substr($line,32,9)); } 
       if (substr($line,0,32) =~ /\s*CDP\s*Number\s*/i )                 { $cdp_number = trim(substr($line,32,4)); } 
       if (substr($line,0,32) =~ /\s*Monument\s*Description\s*/i )       { $monument_description = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Height\s*of\s*the\s*Monument\s*/i ) { $height_of_the_monument = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Monument\s*Foundation\s*/i )        { $monument_foundation = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Foundation\s*Depth\s*/i )           { $foundation_depth = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Marker\s*Description\s*/i )         { $marker_description = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Date\s*Installed\s*/i )             { $date_installed = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Geologic\s*Characteristic\s*/i )    { $geologic_characteristic = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Bedrock\s*Type\s*/i )               { $bedrock_type = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Bedrock\s*Condition\s*/i )          { $bedrock_condition = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Fracture\s*Spacing\s*/i )           { $fracture_spacing = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Fault\s*zones\s*nearby\s*/i )       { $fault_zones_nearby = trim(substr($line,32,length($line)-33)); } 

       if (substr($line,0,32) =~ /\s*Distance\/activity\s*/i )
              {
                  $distance_activity = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( ($line !~ /\s*Additional\s*Information\s*/i ) && (!eof(LogFile)) )
                    {
                      $distance_activity .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 1 - field "Additional Information" not found'; }
              }    
       if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section1 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $additional_information_section1 .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Sections 1 and 2 - no empty line between these two sections'; }
              } 
     }



#   if($site_name =~s/ü/&uuml;/g)   { print "\nSite name : $site_name"; } #$site_name =~s/ü/&uuml;/g;
   $site_name =~s/ü/&uuml;/g;
   $site_name =~s/\'/&#39;/g;
   $site_name =~s/"/&#39;/g;

   $site_name =~s/ç/&ccedil;/g;
   $site_name =~s/Ã§/&ccedil;/g;

   $site_name =~s/ó/&oacute;/g;
   $site_name =~s/Ã³/&oacute;/g;

   $site_name =~s/é/&eacute;/g;
   $site_name =~s/Ã©/&eacute;/g;

   $site_name =~s/õ/&otilde;/g;
   $site_name =~s/Ãµ/&otilde;/g;

   $site_name =~s/á/&aacute;/g;
   $site_name =~s/Ã¡/&aacute;/g;

   $site_name =~s/ö/&ouml;/g;
   $site_name =~s/Ã¶/&ouml;/g;

   $site_name =~s/ñ/&ntilde;/g;

   
   $monument_inscription =~s/\'/&#39;/g;
   $monument_inscription =~s/"/&#39;/g;
   $height_of_the_monument =~s/m$//;
   $height_of_the_monument =~s/\(m\)$//;
   $height_of_the_monument =~s/M$//;
   $height_of_the_monument =~s/meter$//;
   $height_of_the_monument =~ s/,/\./;
   $height_of_the_monument = trim($height_of_the_monument);
   $foundation_depth =~s/\(approximately\)$//;
   $foundation_depth = trim($foundation_depth);
   $foundation_depth =~s/^approx\.//;
   $foundation_depth =~s/^approximately//;
   $foundation_depth =~s/^approximatly//;
   $foundation_depth =~s/m$//;
   $foundation_depth =~s/\(m\)$//;
   $foundation_depth =~s/M$//;
   $foundation_depth =~ s/,/\./;
   $foundation_depth = trim($foundation_depth);
   $marker_description =~s/\'/&#39;/g;
   $marker_description =~s/"/&#39;/g;
   $bedrock_type = uc($bedrock_type);
   $bedrock_condition = uc($bedrock_condition);
   $fracture_spacing = lc($fracture_spacing);
   $distance_activity =~s/\'/&#39;/g;
   $distance_activity =~s/"/&#39;/g;
   $additional_information_section1 =~s/\'/&#39;/g;
   $additional_information_section1 =~s/"/&#39;/g;


   if ($height_of_the_monument eq '') { $height_of_the_monument = '(m)'; }
   if ($foundation_depth eq '') { $foundation_depth = '(m)'; }
   if ($geologic_characteristic eq '') { $geologic_characteristic = '(BEDROCK/CLAY/CONGLOMERATE/GRAVEL/SAND/etc)'; }
   if ($bedrock_type eq '') { $bedrock_type = '(IGNEOUS/METAMORPHIC/SEDIMENTARY)'; }
   if ($bedrock_condition eq '') { $bedrock_condition = '(FRESH/JOINTED/WEATHERED)'; }
   if ($fracture_spacing eq '(1-10 cm/11-50 cm/51-200 cm/over 200 cm)') { $fracture_spacing = '(0 cm/1-10 cm/11-50 cm/51-200 cm/over 200 cm)'; }
   if ($fracture_spacing eq '') { $fracture_spacing = '(0 cm/1-10 cm/11-50 cm/51-200 cm/over 200 cm)'; }
   if ($fault_zones_nearby eq '') { $fault_zones_nearby = '(YES/NO/Name of the zone)';} 



   if (length(trim($site_name)) == 0)
    {
       print('Section 1 - Site Name : missing input' . "\n");
    }

   if ( ($four_character_id !~ /^[A-Z0-9]{4}$/ ) || (length(trim($four_character_id)) != 4) )
    {
       print('Section 1 - Four Character ID : invalid format. Use A4.' . "\n");
    }

   if ($iers_domes_number !~ /^[0-9]{5}[M,S]{1}[0-9]{3}$/ )
    {
       print('Section 1 - IERS DOMES Number : invalid format. Use A9.' . "\n");
    }




   if (
      ($height_of_the_monument !~ /^[0-9]{1,2}\.[0-9]{1,3}$/ )
      &&
      ($height_of_the_monument !~ /^[0-9]{1,2}$/ )
      &&
      (trim($height_of_the_monument) ne '(m)')	 
      )
       {
         print('Section 1 - Height of the Monument : invalid format. Use F6.3 (or blank).' . "\n");
       }



   if (
      ($foundation_depth !~ /^[0-9]{1,2}\.[0-9]{1,2}$/ )
      &&
      ($foundation_depth !~ /^[0-9]{1,2}$/ )
      &&
      (trim($foundation_depth) ne '(m)')
      )
       {
         #print('Section 1 - Foundation Depth : -' . $foundation_depth . "-\n");
         print('Section 1 - Foundation Depth : invalid format. Use F5.2 (or blank).' . "\n");
       }

   $error_date_installed = check_stationlogdate($date_installed);
   if($error_date_installed ne '')
    {
      #print('Section 1 - Date Installed : ' . $date_installed . "\n");
      print('Section 1 - Date Installed : ' . $error_date_installed . "\n");
    }
   
   if (
      ($bedrock_type ne '(IGNEOUS/METAMORPHIC/SEDIMENTARY)') &&
      ($bedrock_type ne 'IGNEOUS') &&
      ($bedrock_type ne 'METAMORPHIC') &&
      ($bedrock_type ne 'SEDIMENTARY')
      )
    {
      print('Section 1 - Bedrock Type : wrong input. Choose IGNEOUS or METAMORPHIC or SEDIMENTARY or ... nothing "(IGNEOUS/METAMORPHIC/SEDIMENTARY)"' . "\n");
    }

   if (
      ($bedrock_condition ne '(FRESH/JOINTED/WEATHERED)') &&
      ($bedrock_condition ne 'FRESH') &&
      ($bedrock_condition ne 'JOINTED') &&
      ($bedrock_condition ne 'WEATHERED')
      )
    {
      print('Section 1 - Bedrock Condition : wrong input. Choose FRESH or JOINTED or WEATHERED or ... nothing "(FRESH/JOINTED/WEATHERED)"' . "\n");
    }

   if (
      ($fracture_spacing ne '(0 cm/1-10 cm/11-50 cm/51-200 cm/over 200 cm)') &&
      ($fracture_spacing ne '0 cm') &&
      ($fracture_spacing ne '1-10 cm') &&
      ($fracture_spacing ne '11-50 cm') &&
      ($fracture_spacing ne '51-200 cm') &&
      ($fracture_spacing ne 'over 200 cm')
      )
    {
      print('Section 1 - Fracture Spacing : wrong input. Choose "0 cm" or "1-10 cm" or "11-50 cm" or "51-200 cm" or "over 200 cm" or ... nothing "(0 cm/1-10 cm/11-50 cm/51-200 cm/over 200 cm)"' . "\n");
    }




#  print "Site Name : $site_name\n";
#  print "$four_character_id\n";
#  print "$monument_inscription\n";
#  print "$iers_domes_number\n";
#  print "$cdp_number\n";
#  print "$monument_description\n";
#  print "$height_of_the_monument\n";
#  print "$monument_foundation\n";
#  print "$foundation_depth\n";
#  print "$marker_description\n";
#  print "$date_installed\n";
#  print "$geologic_characteristic\n";
#  print "$bedrock_type\n";
#  print "$bedrock_condition\n";
#  print "$fracture_spacing\n";
#  print "$fault_zones_nearby\n";
#  print "$distance_activity\n";
#  print "$additional_information_section1\n";

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 2 - title of that section not found.'; }



  #######################################################################
  # READ SECTION 2.
  #######################################################################
  #print (" read 2\n");
  while ( ( $line !~ /^3.\s*GNSS\s*Receiver\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if (substr($line,0,32) =~ /\s*City\s*or\s*Town\s*/i )            { $city_or_town = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*State\s*or\s*Province\s*/i )       { $state_or_province = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Country\s*/i )                     { $country = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Tectonic\s*Plate\s*/i )            { $tectonic_plate = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*X\s*coordinate\s*/i )              { $x_coordinate = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Y\s*coordinate\s*/i )              { $y_coordinate = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Z\s*coordinate\s*/i )              { $z_coordinate = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Latitude\s*\(N is \+\)\s*/i )       { $latitude = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Longitude\s*\(E is \+\)\s*/i )      { $longitude = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Elevation\s*\(m,ellips.\)\s*/i )   { $elevation = trim(substr($line,32,length($line)-33)); } 

       if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section2 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $additional_information_section2 .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Sections 2 and 3 - no empty line between these two sections'; }

              } 
     }

   #if ($fourid eq 'ARGI') {   print "City : $city_or_town\n"; }

   $city_or_town =~s/\'/&#39;/g;
   $city_or_town =~s/"/&#39;/g;

   $city_or_town =~s/ç/&ccedil;/g;
   $city_or_town =~s/Ã§/&ccedil;/g;

   $city_or_town =~s/ó/&oacute;/g; #  if($city_or_town =~s/ó/&oacute;/g) { print "City : $city_or_town\n"; }

   $city_or_town =~s/é/&eacute;/g;
   $city_or_town =~s/Ã©/&eacute;/g;

   $city_or_town =~s/õ/&otilde;/g;
   $city_or_town =~s/Ãµ/&otilde;/g;

   $city_or_town =~s/ü/&uuml;/g;

   $city_or_town =~s/á/&aacute;/g;
   $city_or_town =~s/Ã¡/&aacute;/g;

   $city_or_town =~s/ö/&ouml;/g;
   $city_or_town =~s/Ã¶/&ouml;/g;

   $city_or_town =~s/ñ/&ntilde;/g;

   $state_or_province =~s/\'/&#39;/g;
   $state_or_province =~s/"/&#39;/g;
#if ($fourid eq 'AUTN') { print "$state_or_province\n"; }
   $state_or_province =~s/ô/&ocirc;/g;
#if ($fourid eq 'AUTN') { print "$state_or_province\n"; }


   if ($country eq 'Russia') { $country = 'Russian Federation'; }
=pod
   $tectonic_plate =~s/^EURA[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Eura[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^eura[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^EUR-ASIAN/EURASIAN/;
   $tectonic_plate =~s/^AFRI[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^Afri[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^afri[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^IBER[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Iber[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^iber[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^AMER[a-zA-Z0-9_\-() \/]*/NORTH AMERICAN/;
   $tectonic_plate =~s/^Amer[a-zA-Z0-9_\-() \/]*/NORTH AMERICAN/;
   $tectonic_plate =~s/^amer[a-zA-Z0-9_\-() \/]*/NORTH AMERICAN/;
   $tectonic_plate =~s/^North Amer[a-zA-Z0-9_\-() \/]*/NORTH AMERICAN/;
   $tectonic_plate =~s/^ADRI[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Adri[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^adri[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^SINA[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^Sina[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^sina[a-zA-Z0-9_\-() \/]*/AFRICAN/;
   $tectonic_plate =~s/^AEGE[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Aege[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^aege[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^ANOT[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Anot[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^anot[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^ANAT[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^Anat[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^anat[a-zA-Z0-9_\-() \/]*/EURASIAN/;
   $tectonic_plate =~s/^East-European[a-zA-Z0-9_\-() \/]*/EURASIAN/;
=cut
   $additional_information_section2 =~s/\'/&#39;/g;
   $additional_information_section2 =~s/"/&#39;/g;

   if (length(trim($city_or_town)) == 0)
    {
       print('Section 2 - City or Town : missing input' . "\n");
    }

   my @countries = ('Afghanistan','Aland Islands','Albania','Algeria','American Samoa',
                    'Andorra','Angola','Anguilla','Antarctica','Antigua and Barbuda',
                    'Argentina','Armenia','Aruba','Australia','Austria','Azerbaijan',
                    'Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium',
                    'Belize','Benin','Bermuda','Bhutan','Bolivia','Bosnia and Herzegovina',
                    'Botswana','Bouvet Island','Brazil','British Indian Ocean Territory',
                    'Brunei Darussalam','Bulgaria','Burkina Faso','Burundi','Cambodia',
                    'Cameroon','Canada','Cape Verde','Cayman Islands','Central African Republic',
                    'Chad','Chile','China','Christmas Island','Cocos (Keeling) Islands',
                    'Colombia','Comoros','Congo','Congo, The Democratic Republic of The',
                    'Cook Islands','Costa Rica','Côte d\'Ivoire','Croatia','Cuba','Cyprus',
                    'Czech Republic','Denmark','Djibouti','Dominica','Dominican Republic',
                    'Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia',
                    'Ethiopia','Falkland Islands (Malvinas)','Faroe Islands','Fiji','Finland',
                    'France','French Guiana','French Polynesia','French Southern Territories',
                    'Gabon','Gambia','Georgia','Germany','Ghana','Gibraltar','Greece','Greenland',
                    'Greenland (Denmark)','Grenada','Guadeloupe','Guam','Guatemala','Guernsey',
                    'Guinea','Guinea-Bissau','Guyana','Haiti','Heard Island and Mcdonald Islands',
                    'Holy See (Vatican City State)','Honduras','Hong Kong','Hungary','Iceland',
                    'India','Indonesia','Iran, Islamic Republic of','Iraq','Ireland','Isle of Man',
                    'Israel','Italy','Jamaica','Japan','Jersey','Jordan','Kazakhstan','Kenya',
                    'Kiribati','Korea, Democratic People\'s Republic of','Korea, Republic of',
                    'Kuwait','Kyrgyzstan','Lao People\'s Democratic Republic','Latvia',
                    'Lebanon','Lesotho','Liberia','Libyan Arab Jamahiriya','Liechtenstein',
                    'Lithuania','Luxembourg','Macao','Macedonia','Madagascar','Malawi',
                    'Malaysia','Maldives','Mali','Malta','Marshall Islands','Martinique',
                    'Mauritania','Mauritius','Mayotte','Mexico','Micronesia, Federated States of',
                    'Monaco','Mongolia','Montenegro','Montserrat','Morocco','Mozambique',
                    'Myanmar','Namibia','Nauru','Nepal','Netherlands','Netherlands Antilles',
                    'New Caledonia','New Zealand','Nicaragua','Niger','Nigeria','Niue',
                    'Norfolk Island','Northern Mariana Islands','Norway','Oman','Pakistan',
                    'Palau','Palestinian Territory','Panama','Papua New Guinea','Paraguay',
                    'Peru','Philippines','Pitcairn','Poland','Portugal','Puerto Rico','Qatar',
                    'Republic of Moldova','Réunion','Romania','Russian Federation','Rwanda',
                    'Saint Barthélemy','Saint Helena','Saint Kitts and Nevis','Saint Lucia',
                    'Saint Martin','Saint Pierre and Miquelon','Saint Vincent and The Grenadines',
                    'Samoa','San Marino','Sao Tome and Principe','Saudi Arabia','Senegal','Serbia',
                    'Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands',
                    'Somalia','South Africa','South Georgia and The South Sandwich Islands','Spain',
                    'Sri Lanka','Sudan','Suriname','Svalbard and Jan Mayen','Swaziland','Sweden',
                    'Switzerland','Syrian Arab Republic','Taiwan, Province of China','Tajikistan',
                    'Tanzania, United Republic of','Thailand','Timor-Leste','Togo','Tokelau','Tonga',
                    'Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Turks and Caicos Islands',
                    'Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States',
                    'United States Minor Outlying Islands','Uruguay','Uzbekistan','Vanuatu','Venezuela',
                    'Viet Nam','Virgin Islands, British','Virgin Islands, U.s.','Wallis and Futuna',
                    'Western Sahara','Yemen','Zambia','Zimbabwe');

   $countryfound = 'false';
   foreach my $value (@countries) { if($country eq $value) { $countryfound = 'true'; } }
   if ($countryfound eq 'false') { print('Section 2 - Country : "' . $country . '" -- > wrong or missing input (see http://unstats.un.org/unsd/methods/m49/m49alpha.htm).' . "\n"); }

   my @tectonic_plates = ('AFRICAN','ANTARTIC','ARABIAN','AUSTRALIAN','CARIBBEAN','COCOS','EURASIAN',
                          'INDIAN','JUAN DE FUCA','NAZCA','NORTH AMERICAN','PACIFIC','PHILIPPINE','SCOTIA','SOUTH AMERICAN');

   $tectonicplatefound = 'false';
   $tmp_tp = '';
   foreach my $value (@tectonic_plates)
    {
      if($tectonic_plate eq $value) { $tectonicplatefound = 'true'; }
      $tmp_tp .= $value . ', ';
    }
   if ($tectonicplatefound eq 'false')
    {
      print('Section 2 - Tectonic Plate : "' . $tectonic_plate . '" -- > wrong or missing input. Choose between ' . substr($tmp_tp,0,-2) . "\n");
    }




   if (length(trim($x_coordinate)) == 0)
    {
      print('Section 2 - X coordinate (m) : missing input. Use integer or float.' . "\n");
    }

  if (
      ($x_coordinate !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ )
      &&
      ($x_coordinate !~ /^[-]{0,1}[0-9]{1,}$/ )
      &&
      (trim($x_coordinate) ne '')
      )
    {
      print('Section 2 - X coordinate (m) : invalid format. Use integer or float.' . "\n");
    }




   if (length(trim($y_coordinate)) == 0)
    {
      print('Section 2 - Y coordinate (m) : missing input. Use integer or float.' . "\n");
    }

  if (
      ($y_coordinate !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ )
      &&
      ($y_coordinate !~ /^[-]{0,1}[0-9]{1,}$/ )
      &&
      (trim($y_coordinate) ne '')
      )
    {
      print('Section 2 - Y coordinate (m) : invalid format. Use integer or float.' . "\n");
    }





   if (length(trim($z_coordinate)) == 0)
    {
      print('Section 2 - Z coordinate (m) : missing input. Use integer or float.' . "\n");
    }

   if (
      ($z_coordinate !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ )
      &&
      ($z_coordinate !~ /^[-]{0,1}[0-9]{1,}$/ )
      &&
      (trim($z_coordinate) ne '')
      )
    {
      print('Section 2 - Z coordinate (m) : invalid format. Use integer or float.' . "\n");
    }


   if (
      ($latitude !~ /^[+,-]{1}[0-9]{1}[0-9]{1}[0-5]{1}[0-9]{1}[0-5]{1}[0-9]{1}\.[0-9]{2}$/ ) ||
      (substr($latitude,1,2) gt '90' ) ||
      (
        (substr($latitude,1,2) eq '90') &&
        (substr($latitude,3,7) ne '0000.00')
      )
      )	
    {
      print('Section 2 - Latitude (N is +) : invalid format. Use +/-DDMMSS.SS.' . "\n");
    }


   if (
      ($longitude !~ /^[+,-]{1}[0-1]{1}[0-9]{1}[0-9]{1}[0-5]{1}[0-9]{1}[0-5]{1}[0-9]{1}\.[0-9]{2}$/ ) ||
      (substr($longitude,1,3) gt '180' ) ||
      (
        (substr($longitude,1,3) eq '180') &&
        (substr($longitude,3,7) ne '0000.00')
      )
      )	
    {
      print('Section 2 - Longitude (E is +) : invalid format. Use +/-DDDMMSS.SS.' . "\n");
    }


   if (length(trim($elevation)) == 0)
    {
      print('Section 2 - Elevation (m,ellips.) : missing input' . "\n");
    }


   if (
      ($elevation !~ /^[-0-9]{0,1}[0-9]{1,4}\.[0-9]{1}$/ ) &&
      (length(trim($elevation)) > 0)
      )
    {
      print('Section 2 - Elevation (m,ellips.) : invalid format. Use F7.1.' . "\n");
    }






#  print "City : $city_or_town\n";
#  print "$state_or_province\n";
#  print "$country\n";
#  print "$tectonic_plate\n";
#  print "$x_coordinate\n";
#  print "$y_coordinate\n";
#  print "$z_coordinate\n";
#  print "$latitude\n";
#  print "$longitude\n";
#  print "$elevation\n";
#  print "$additional_information_section2\n";

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 3 - title of that section not found.'; }



  #######################################################################
  # READ SECTION 3.
  #######################################################################
  #print (" read 3\n");

  $number_receivers = 0;
  
  while ( ( $line !~ /^4.\s*GNSS\s*Antenna\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Receiver\s*Type\s*/i ) && ($line !~ /\s*3.x\s*/i ) )
          {
            $number_receivers++;   
            $receiver{type}[$number_receivers] = uc(trim(substr($line,32,length($line)-33)));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Satellite\s*System\s*/i )           { $receiver{satellite_system}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Serial\s*Number\s*:\s*/i )              { $receiver{serial_number}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Firmware\s*Version\s*/i )           { $receiver{firmware_version}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Elevation\s*Cutoff\s*Setting\s*/i ) { $receiver{elevation_cutoff_setting}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Date\s*Installed\s*:\s*/i )             { $receiver{date_installed}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Date\s*Removed\s*:\s*/i )               { $receiver{date_removed}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Temperature\s*Stabiliz\.\s*/i )     { $receiver{temperature_stabilization}[$number_receivers] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $receiver{additional_information}[$number_receivers] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $receiver{additional_information}[$number_receivers] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 3.' . $number_receivers . ' - no empty line after that subsection'; }

                 } 

              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 3.' . $number_receivers . ' - no empty line after that subsection'; }

          }  
     }

  $previous_error_date_removed = '';
  for($i=1;$i<=$number_receivers;$i++)
   {
#      print("$receiver{type}[$i] $receiver{serial_number}[$i] $receiver{date_installed}[$i] $receiver{date_removed}[$i]\n");
#      print("$receiver{firmware_version}[$i] $receiver{elevation_cutoff_setting}[$i] $receiver{temperature_stabilization}[$i]\n");
#      print("$receiver{additional_information}[$i]\n");

     $receiver{additional_information}[$i] =~s/\'/&#39;/g;
     $receiver{additional_information}[$i] =~s/"/&#39;/g;

     $receiver{elevation_cutoff_setting}[$i] =~ s/deg$//;
     $receiver{elevation_cutoff_setting}[$i] = trim($receiver{elevation_cutoff_setting}[$i]);

     #if (uc($receiver{temperature_stabilization}[$i]) ne 'NONE') { print("$four_character_id $receiver{temperature_stabilization}[$i]\n"); }
     $receiver{temperature_stabilization}[$i] =~s/\(none or tolerance in degrees C\)/\(deg C\) \+\/\- \(deg C\)/g;
#     $receiver{temperature_stabilization}[$i] =~s/none/\(deg C\) \+\/\- \(deg C\)/gi;
     $receiver{temperature_stabilization}[$i] =~s/=B0C//g;
     $receiver{temperature_stabilization}[$i] =~s/B0C//g;
     $receiver{temperature_stabilization}[$i] =~s/°C//g;
     $receiver{temperature_stabilization}[$i] =~s/degrees C//g;
     $receiver{temperature_stabilization}[$i] =~s/deg\. C//g;
     $receiver{temperature_stabilization}[$i] =~s/degr C//g;
     $receiver{temperature_stabilization}[$i] =~s/\+\-/\+\/\-/g;
     $receiver{temperature_stabilization}[$i] =~s/^\+//g;
     $receiver{temperature_stabilization}[$i] =~s/ //g;
     if (($receiver{temperature_stabilization}[$i] !~ /[a-zA-Z0-9()]*\+\/\-[a-zA-Z0-9()]*/i ) && ($receiver{temperature_stabilization}[$i] ne 'none'))
         { $receiver{temperature_stabilization}[$i] = '(degC)+/-' . $receiver{temperature_stabilization}[$i]; }
     $receiver{temperature_stabilization}[$i] =~s/degC/deg C/g;
     $receiver{temperature_stabilization}[$i] =~s/\+\/\-/ \+\/\- /g;
     #if ($receiver{temperature_stabilization}[$i] ne '(deg C) +/- (deg C)') { print("$four_character_id $receiver{temperature_stabilization}[$i]\n"); }


     if (
         ($receiver{type}[$i] ne '(A20, from rcvr_ant.tab; see instructions)') or
         ($receiver{satellite_system}[$i] ne '(GPS/GLONASS/GPS+GLONASS)') or
         ($receiver{serial_number}[$i] ne '(A20, but note the first A5 is used in SINEX)') or
         ($receiver{firmware_version}[$i] ne '(A11)') or
         ($receiver{elevation_cutoff_setting}[$i] ne '(deg)') or
         ($receiver{date_installed}[$i] ne '(CCYY-MM-DDThh:mmZ)') or
         ($receiver{date_removed}[$i] ne '(CCYY-MM-DDThh:mmZ)') or
         ($receiver{temperature_stabilization}[$i] ne '(deg C) +/- (deg C)') or
         ($receiver{additional_information}[$i] ne '(multiple lines)')
         )
      {
      if ($receiver{date_installed}[$i] eq '(CCYY-MM-DDThh:mmZ)')
       {
         $receiver{date_installed}[$i] = 'CCYY-MM-DDThh:mmZ';
       }
      if ($receiver{date_removed}[$i] eq '(CCYY-MM-DDThh:mmZ)')
       {
         if ($i == $number_receivers) { print('Section 3.' . $i . ' - Date Removed : wrong format. Remove the brackets : CCYY-MM-DDThh:mmZ in place of (CCYY-MM-DDThh:mmZ)' . "\n"); }
         $receiver{date_removed}[$i] = 'CCYY-MM-DDThh:mmZ';
       }
      }


    # RECEIVER TYPE
    if ( (length(trim($receiver{type}[$i])) == 0) || ($receiver{type}[$i] eq '(A20, from rcvr_ant.tab; see instructions)') )
     {
      print('Section 3.' . $i . ' - Receiver Type : missing input' . "\n");
     }

    $recfound = 'false';
    open (RECTABFile, $hardwaretablesfile) || die "Cannot open $_";
    while (!eof(RECTABFile))
     {
       $line = <RECTABFile>;
       if (length($line) >= 22)
        {
          if ($receiver{type}[$i] eq trim(substr($line,2,20)))
           {
             $recfound = 'true';
           }
        }       
     }
    close(RECTABFile);
    if ($recfound eq 'false')
     {
      print('Section 3.' . $i . ' - Receiver Type : wrong input. ' . $receiver{type}[$i] . ' is not available from ' . $hardwaretablesfile . "\n");
     }



    # SATELLITE SYSTEM
    if (length(trim($receiver{satellite_system}[$i])) == 0)
     {
      print('Section 3.' . $i . ' - Satellite System : missing input' . "\n");
     }

    @satsys_list = split(/\+/,$receiver{satellite_system}[$i]);
    foreach my $value (@satsys_list)
     {
       if(index('GPS+GLO+GAL+BDS+QZSS+SBAS', $value) == -1)
        {
           print('Section 3.' . $i . ' - Satellite System : wrong input. ' . $value . ' is not a valid satellite system.' . "\n");
        }
     }

=pod
    $satsys_info = '';
    open (BRIFile, $receiversatsysinfofile) || die "Cannot open $_";
    $line = <BRIFile>; $line = <BRIFile>; $line = <BRIFile>; $line = <BRIFile>; $line = <BRIFile>;

    while (!eof(BRIFile))
     {
       $line = <BRIFile>;
       if (length($line) >= 50)
        {
          if ($receiver{type}[$i] eq trim(substr($line,0,20)))
           {
             $satsys_info = trim(substr($line,49,5));

             if ( ( $satsys_info !~ /G/g ) && ( $receiver{satellite_system}[$i] =~ /GPS/g ) )
              { print('Section 3.' . $i . ' - Satellite System : the receiver ' . $receiver{type}[$i] . ' cannot provide GPS data.' . "\n"); }
 
             if ( ( $satsys_info !~ /R/g ) && ( $receiver{satellite_system}[$i] =~ /GLO/g ) )
              { print('Section 3.' . $i . ' - Satellite System : the receiver ' . $receiver{type}[$i] . ' cannot provide GLONASS data.' . "\n"); }

             if ( ( $satsys_info !~ /E/g ) && ( $receiver{satellite_system}[$i] =~ /GAL/g ) )
              { print('Section 3.' . $i . ' - Satellite System : the receiver ' . $receiver{type}[$i] . ' cannot provide GALILEO data.' . "\n"); }
          }
        }
     }
    close(BRIFile);
=cut

    # RECEIVER SERIAL NUMBER
    if ( (length(trim($receiver{serial_number}[$i])) == 0) || ($receiver{serial_number}[$i] eq '(A20, but note the first A5 is used in SINEX)') )
     {
       print('Section 3.' . $i . ' - Serial Number : missing input' . "\n");
     }

    if ( (length(trim($receiver{serial_number}[$i])) > 20) && ($receiver{serial_number}[$i] ne '(A20, but note the first A5 is used in SINEX)') )
     {
       print('Section 3.' . $i . ' - Serial Number :  invalid format. Use A20.' . "\n");
     }

    # RECEIVER FIRMWARE VERSION
    if ( (length(trim($receiver{firmware_version}[$i])) == 0) || ($receiver{firmware_version}[$i] eq '(A11)') )
     {
       print('Section 3.' . $i . ' - Firmware Version : missing input' . "\n");
     }

    if ( (length(trim($receiver{firmware_version}[$i])) > 11) && ($receiver{firmware_version}[$i] ne '(A11)') )
     {
       print('Section 3.' . $i . ' - Firmware Version :  invalid format. Use A11.' . "\n");
     }

    # ELEVATION CUTOFF SETTING
    if ( (length(trim($receiver{elevation_cutoff_setting}[$i])) == 0) || ($receiver{elevation_cutoff_setting}[$i] eq '(deg)') )
     {
       print('Section 3.' . $i . ' - Elevation Cutoff Setting : missing input' . "\n");
     }

    if (
       ($receiver{elevation_cutoff_setting}[$i] !~ /^[0-9]{1,2}$/ ) &&
       (length(trim($receiver{elevation_cutoff_setting}[$i])) > 0)
       )
     {
       print('Section 3.' . $i . ' - Elevation Cutoff Setting : wrong format. Use A2.' . "\n");
     }

    if (
       ($receiver{elevation_cutoff_setting}[$i] =~ /^[0-9]{1,2}$/ ) &&
       (length(trim($receiver{elevation_cutoff_setting}[$i])) > 0) &&
       ($receiver{elevation_cutoff_setting}[$i] > 5)
       )
     {
       print('Section 3.' . $i . ' - Elevation Cutoff Setting : EPN guidelines recommend a cut off of 0 deg.' . "\n");
     }

    # TEMPERATURE STABILIZATION
    if (
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\.[0-9]{1}\s*\+\/\-$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\s*\+\/\-$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^\+\/\-\s*[0-9]{1,2}$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^\+\/\-\s*[0-9]{1,2}\.[0-9]{1}$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\.[0-9]{1}\s*\+\/\-\s*[0-9]{1,2}\.[0-9]{1}$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\s*\+\/\-\s*[0-9]{1,2}\.[0-9]{1}$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\.[0-9]{1}\s*\+\/\-\s*[0-9]{1,2}$/ ) &&
       ($receiver{temperature_stabilization}[$i] !~ /^[0-9]{1,2}\s*\+\/\-\s*[0-9]{1,2}$/ ) &&
       (trim($receiver{temperature_stabilization}[$i]) ne '+/-') &&
       (trim($receiver{temperature_stabilization}[$i]) ne '') &&
       (trim($receiver{temperature_stabilization}[$i]) ne 'none') &&
       (trim($receiver{temperature_stabilization}[$i]) ne 'none+/-none')
       )
     {
       print('Section 3.' . $i . ' - Temperature Stabiliz. : Invalid format.  Use F4.1 +/- F3.1 (or blank or "none").' . "\n");
     }

    # DATE INSTALLED
    $error_date_installed = check_stationlogdate($receiver{date_installed}[$i]);
    if($error_date_installed ne '')
     {
       print('Section 3.' . $i . ' - Date Installed : ' . $error_date_installed . "\n");
     }

    # DATE REMOVED
    if($i < $number_receivers)
    {
    $error_date_removed = check_stationlogdate($receiver{date_removed}[$i]);
    if($error_date_removed ne '')
     {
       print('Section 3.' . $i . ' - Date Removed : ' . $error_date_removed . "\n");
     }
    }

    if(
      ($i == $number_receivers) &&
      ($receiver{date_removed}[$i] ne "CCYY-MM-DDThh:mmZ") &&
      ($receiver{date_removed}[$i] ne "CCYY-MM-DD") &&
      ($receiver{date_removed}[$i] ne "(CCYY-MM-DDThh:mmZ)") &&
      ($receiver{date_removed}[$i] ne "(CCYY-MM-DDThh:mm") &&
      ($receiver{date_removed}[$i] ne "")
      )
    {
    $error_date_removed = check_stationlogdate($receiver{date_removed}[$i]);
    if($error_date_removed ne '')
     {
       print('Section 3.' . $i . ' - Date Removed : ' . $error_date_removed . "\n");
     }
    }

=pod
// necessary reinitialization
if (
     ($dateremovedreceiver[$counterRec] == "(CCYY-MM-DDThh:mmZ)") or
     ($dateremovedreceiver[$counterRec] == "(CCYY-MM-DDThh:mm") or
     ($dateremovedreceiver[$counterRec] == "")
   )
     { $dateremovedreceiver[$counterRec] = 'CCYY-MM-DDThh:mmZ'; }
=cut




    # DATE INSTALLED and DATE REMOVED : chronology comparison
    if (
       ($error_date_installed eq "") &&
       ($error_date_removed eq "") &&
       ($receiver{date_installed}[$i] gt $receiver{date_removed}[$i] )
       )
     {
       if (!(
            (substr($receiver{date_installed}[$i],0,10) eq substr($receiver{date_removed}[$i],0,10) ) &&
            (length($receiver{date_removed}[$i]) == 10) &&
            (substr($receiver{date_installed}[$i],10,7) eq 'T00:00Z')
            )
          )
        {
          print('Section 3.' . $i . ' - Date Removed precedes Date Installed' . "\n");
        }
     }


    # DATE INSTALLED (current installation) and DATE REMOVED (previous installation) : chronology comparison
    if (
       ($error_date_installed eq "") &&
       ($previous_error_date_removed eq "") &&
       ($receiver{date_installed}[$i] lt $receiver{date_removed}[($i-1)] )
       )
      {
       if (!(
            (substr($receiver{date_installed}[$i],0,10) eq substr($receiver{date_removed}[($i-1)],0,10) ) &&
            (length($receiver{date_installed}[$i]) == 10) &&
            (substr($receiver{date_removed}[($i-1)],10,7) eq 'T00:00Z')
            )
          )
        {
          print('Sections 3.' . ($i-1) . ' and 3.' . $i . ' - Date Installed (subsection 3.' . $i . ') precedes Date Removed (subsection 3.' . ($i-1) . ')' . "\n");
        }
      }


    $previous_error_date_removed = $error_date_removed;











   }   


  if ($number_receivers == 0)
   {
      print('Section 3 - GNSS Receiver Information : missing section' . "\n");
   }



  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 4 - title of that section not found'; }



  #######################################################################
  # READ SECTION 4.
  #######################################################################
#  print (" read 4\n");
  $number_antennae = 0;
  
  while ( ( $line !~ /^5.\s*Surveyed\s*Local\s*Ties\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Antenna\s*Type\s*/i ) && ($line !~ /\s*4.x\s*/i ) )
          {
            $number_antennae++;   
            $antenna{type}[$number_antennae] = uc(trim(substr($line,32,length($line)-33)));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if ( (substr($line,0,32) =~ /\s*Serial\s*Number\s*:\s*/i ) && ($line !~ /\s*Radome\s*/i ) )              { $antenna{serial_number}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Antenna\s*Reference\s*Point\s*/i )      { $antenna{antenna_reference_point}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Marker->ARP\s*Up\s*/i )      { $antenna{arp_up_ecc}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Marker->ARP\s*North\s*Ecc\(m\)\s*/i )      { $antenna{arp_north_ecc}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Marker->ARP\s*East\s*Ecc\(m\)\s*/i )      { $antenna{arp_east_ecc}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Alignment\s*from\s*True\s*N\s*/i )      { $antenna{alignment_from_true_n}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if ( (substr($line,0,32) =~ /\s*Antenna\s*Radome\s*Type\s*/i ) && ( $line !~ /\s*Additional Information\s*/i ) && (substr($line,0,20) ne "                    ") )    { $antenna{antenna_radome_type}[$number_antennae] = uc(trim(substr($line,32,length($line)-33))); } 
                 if (substr($line,0,32) =~ /\s*Radome\s*Serial\s*Number\s*/i )      { $antenna{radome_serial_number}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Antenna\s*Cable\s*Type\s*/i )      { $antenna{antenna_cable_type}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Antenna\s*Cable\s*Length\s*/i )      { $antenna{antenna_cable_length}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Date\s*Installed\s*:\s*/i )             { $antenna{date_installed}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Date\s*Removed\s*:\s*/i )               { $antenna{date_removed}[$number_antennae] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $antenna{additional_information}[$number_antennae] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $antenna{additional_information}[$number_antennae] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 4.' . $number_antennae . ' . - no empty line after that subsection'; }

                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 4.' . $number_antennae . ' . - no empty line after that subsection'; }
          }  
     }

  $previous_error_date_removed = '';
  for($i=1;$i<=$number_antennae;$i++)
   {
#      print("$antenna{type}[$i] $antenna{serial_number}[$i] $antenna{date_installed}[$i] $antenna{date_removed}[$i]\n");
#      print("$antenna{antenna_reference_point}[$i] $antenna{alignment_from_true_n}[$i]\n");
#      print("$antenna{arp_up_ecc}[$i] $antenna{arp_north_ecc}[$i]  $antenna{arp_east_ecc}[$i]\n");
#      print("$antenna{antenna_radome_type}[$i] $antenna{radome_serial_number}[$i] $antenna{antenna_cable_type}[$i] $antenna{antenna_cable_length}[$i]\n");
#      print("$antenna{radome_serial_number}[$i]\n");
#      print("$antenna{additional_information}[$i]\n");

      $antenna{alignment_from_true_n}[$i] =~ s/deg$//;
      $antenna{alignment_from_true_n}[$i] = trim($antenna{alignment_from_true_n}[$i]);
      $antenna{antenna_cable_length}[$i] =~ s/\(m\)$//;
      $antenna{antenna_cable_length}[$i] =~ s/m$//;
      $antenna{antenna_cable_length}[$i] =~ s/^~//;
      $antenna{antenna_cable_length}[$i] =~ s/^UNDEFINED//;
      $antenna{antenna_cable_length}[$i] = trim($antenna{antenna_cable_length}[$i]);
      $antenna{additional_information}[$i] =~ s/\'/&#39;/g;
      $antenna{additional_information}[$i] =~ s/"/&#39;/g;

      if (
          ($antenna{type}[$i] ne '(A20, from rcvr_ant.tab; see instructions)') or
          ($antenna{serial_number}[$i] ne '(A*, but note the first A5 is used in SINEX)') or
          ($antenna{antenna_reference_point}[$i] ne '(BPA/BCR/XXX from "antenna.gra"; see instr.)') or
          ($antenna{arp_up_ecc}[$i] ne '(F8.4)') or
          ($antenna{arp_north_ecc}[$i] ne '(F8.4)') or
          ($antenna{arp_east_ecc}[$i] ne '(F8.4)') or
          ($antenna{alignment_from_true_n}[$i] ne '(deg; + is clockwise/east)') or
          ($antenna{antenna_radome_type}[$i] ne '(A4 from rcvr_ant.tab; see instructions)') or
          ($antenna{radome_serial_number}[$i] ne '') or
          ($antenna{antenna_cable_type}[$i] ne '(vendor & type number)') or
          ($antenna{antenna_cable_length}[$i] ne '(m)') or
          ($antenna{date_installed}[$i] ne '(CCYY-MM-DDThh:mmZ)') or
          ($antenna{date_removed}[$i] ne '(CCYY-MM-DDThh:mmZ)') or
          ($antenna{additional_information}[$i] ne '(multiple lines)')
          )
      {
      if ($antenna{date_installed}[$i] eq '(CCYY-MM-DDThh:mmZ)') { $antenna{date_installed}[$i] = 'CCYY-MM-DDThh:mmZ'; }
      if ($antenna{date_removed}[$i] eq '(CCYY-MM-DDThh:mmZ)')
       {
         if ($i == $number_antennae) { print('Section 4.' . $i . ' - Date Removed : wrong format. Remove the brackets : CCYY-MM-DDThh:mmZ in place of (CCYY-MM-DDThh:mmZ)' . "\n"); }
         $antenna{date_removed}[$i] = 'CCYY-MM-DDThh:mmZ';
       }

      }

    # ANTENNA TYPE
    $error_antennatype = 'false';
    if ( (length(trim($antenna{type}[$i])) == 0) || ($antenna{type}[$i] eq '(A20, from rcvr_ant.tab; see instructions)') )
     {
      print('Section 4.' . $i . ' - Antenna Type : missing input' . "\n");
     }

    $antfound = 'false';
    open (RECTABFile, $hardwaretablesfile) || die "Cannot open $_";
    while (!eof(RECTABFile))
     {
       $line = <RECTABFile>;
       if (length($line) >= 22)
        {
          if (trim(substr($antenna{type}[$i],0,16)) eq trim(substr($line,2,20)))
           {
             $antfound = 'true';
           }
        }       
     }
    close(RECTABFile);
    if ($antfound eq 'false')
     {
      print('Section 4.' . $i . ' - Antenna Type : wrong input. ' . trim(substr($antenna{type}[$i],0,16)) . ' is not available from ' . $hardwaretablesfile . "\n");
      $error_antennatype = 'true';
     }

    # ANTENNA RADOME TYPE
    $error_radometype = 'false';
    if ( (length(trim(substr(sprintf("%-20s",$antenna{type}[$i]),16,4))) == 0) || ($antenna{type}[$i] eq '(A20, from rcvr_ant.tab; see instructions)') )
     {
      print('Section 4.' . $i . ' - Antenna Type : missing input for the radome (cols 17-20)' . "\n");
      $error_radometype = 'true';
     }

    if ( (length(trim($antenna{antenna_radome_type}[$i])) == 0) || ($antenna{antenna_radome_type}[$i] eq '(A4 from rcvr_ant.tab; see instructions)') )
     {
      print('Section 4.' . $i . ' - Antenna Radome Type : missing input' . "\n");
      $error_radometype = 'true';
     }

    if ( trim(substr(sprintf("%-20s",$antenna{type}[$i]),16,4)) ne trim($antenna{antenna_radome_type}[$i]) )
     {
      print('Section 4.' . $i . ' - Antenna Radome Type and Antenna Type (cols 17-20) : not equal' . "\n");
      $error_radometype = 'true';
     }
    else
     {
       $radomefound = 'false';
       open (RECTABFile, $hardwaretablesfile) || die "Cannot open $_";
       while ( (!eof(RECTABFile)) && (substr($line,0,24) ne '| Antenna Domes        |') ) { $line = <RECTABFile>; }

       if (substr($line,0,24) eq '| Antenna Domes        |')
        {
          while ( (!eof(RECTABFile)) && (substr($line,0,24) ne '| Previously valid     |') )
           {
             $line = <RECTABFile>;
             if (trim($antenna{antenna_radome_type}[$i]) eq trim(substr($line,18,4))) { $radomefound = 'true'; }
           }
        }
       close(RECTABFile);
       if ($radomefound eq 'false')
        {
         print('Section 4.' . $i . ' - Antenna Radome Type : wrong input. ' . trim($antenna{antenna_radome_type}[$i]) . ' is not available from ' . $hardwaretablesfile . "\n");
         $error_radometype = 'true';
        }
     }

    # ANTENNA REFERENCE POINT
    $ARP_found = '';
    open (RECTABFile, $antennareferencepointsfile) || die "Cannot open $_";
    while ( (!eof(RECTABFile)) && ( $line !~ /Machine-readable/g ) ) { $line = <RECTABFile>; }

       if ( $line !~ /Machine-readable/g )
        {
          while (!eof(RECTABFile))
           {
             $line = <RECTABFile>;
             if (trim($line) ne '')
              {
                ($antennareferencepointtable_antenna,$antennareferencepointtable_ARP, $antennareferencepointtable_NRP) = split(/\s+/,trim($line));
                if (trim(substr($antenna{type}[$i],0,16)) eq $antennareferencepointtable_antenna) { $ARP_found = $antennareferencepointtable_ARP; }
              }
           }
        }
    close(RECTABFile);

    #print(trim(substr($antenna{type}[$i],0,16)) . ' ' . $ARP_found . "\n");

    if (
       (trim($antenna{antenna_reference_point}[$i]) eq '') ||
       (trim($antenna{antenna_reference_point}[$i]) eq '(BPA/BCR/XXX from "antenna.gra"; see instr.)')
       )
      {
         print('Section 4.' . $i . ' - Antenna Reference Point : missing input' . "\n");
      }

    if (
       (trim($antenna{antenna_reference_point}[$i]) ne '') &&
       (trim($antenna{antenna_reference_point}[$i]) ne '(BPA/BCR/XXX from "antenna.gra"; see instr.)') &&
       (trim($antenna{antenna_reference_point}[$i]) ne $ARP_found)
       )
      {
        if ($ARP_found ne '')
         {
           print('Section 4.' . $i . ' - Antenna Reference Point : wrong input. Replace ' . trim($antenna{antenna_reference_point}[$i]) . ' by ' . $ARP_found . ".\n");
         }
        else
         {
           print('Section 4.' . $i . ' - Antenna Reference Point : cannot be checked. Not defined in antenna.gra for ' . trim(substr($antenna{type}[$i],0,16)) . '.' . "\n");
         }
      }

    # ANTENNA SERIAL NUMBER
    if ( (length(trim($antenna{serial_number}[$i])) == 0) || ($antenna{serial_number}[$i] eq '(A*, but note the first A5 is used in SINEX)') )
     {
       print('Section 4.' . $i . ' - Serial Number : missing input' . "\n");
     }

    if ( (length(trim($antenna{serial_number}[$i])) > 20) && ($antenna{serial_number}[$i] ne '(A*, but note the first A5 is used in SINEX)') )
     {
       print('Section 4.' . $i . ' - Serial Number :  invalid format. Use A20.' . "\n");
     }

    #MARKER->ARP UP ECC.
    if (
       ($antenna{arp_up_ecc}[$i] !~ /^[-0-9]{0,1}[0-9]{0,2}\.[0-9]{1,4}$/ ) &&
       ($antenna{arp_up_ecc}[$i] ne '(F8.4)') &&
       ($antenna{arp_up_ecc}[$i] ne '')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP Up Ecc. :  invalid format. Use F8.4.' . "\n");
     } 

    if (
       (trim($antenna{arp_up_ecc}[$i]) eq '') ||
       ($antenna{arp_up_ecc}[$i] eq '(F8.4)')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP Up Ecc. :  missing input' . "\n");
     } 


    #MARKER->ARP NORTH ECC.
    if (
       ($antenna{arp_north_ecc}[$i] !~ /^[-0-9]{0,1}[0-9]{0,2}\.[0-9]{1,4}$/ ) &&
       ($antenna{arp_north_ecc}[$i] ne '(F8.4)') &&
       ($antenna{arp_north_ecc}[$i] ne '')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP North Ecc. :  invalid format. Use F8.4.' . "\n");
     } 

    if (
       (trim($antenna{arp_north_ecc}[$i]) eq '') ||
       ($antenna{arp_north_ecc}[$i] eq '(F8.4)')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP North Ecc. :  missing input' . "\n");
     } 



    #MARKER->ARP EAST ECC.
    if (
       ($antenna{arp_east_ecc}[$i] !~ /^[-0-9]{0,1}[0-9]{0,2}\.[0-9]{1,4}$/ ) &&
       ($antenna{arp_east_ecc}[$i] ne '(F8.4)') &&
       ($antenna{arp_east_ecc}[$i] ne '')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP East Ecc. :  invalid format. Use F8.4.' . "\n");
     } 

    if (
       (trim($antenna{arp_east_ecc}[$i]) eq '') ||
       ($antenna{arp_east_ecc}[$i] eq '(F8.4)')
       )
     {
       print('Section 4.' . $i . ' - Marker->ARP East Ecc. :  missing input' . "\n");
     } 

    # ALIGNMENT FROM THE TRUE NORTH 
    if (
       ($antenna{alignment_from_true_n}[$i] !~ /^[0-9]{1,3}$/ ) &&
       ($antenna{alignment_from_true_n}[$i] ne '(deg; + is clockwise/east)') &&
       ($antenna{alignment_from_true_n}[$i] ne '')
       )
     {
       print('Section 4.' . $i . ' - Alignment from True N :  invalid format. Use A3.' . "\n");
     } 

    if (
       (trim($antenna{alignment_from_true_n}[$i]) eq '') ||
       ($antenna{alignment_from_true_n}[$i] eq '(deg; + is clockwise/east)')
       )
     {
       print('Section 4.' . $i . ' - Alignment from True N :  missing input. Set up between 0 and 360 deg.' . "\n"); #If unknown, please comment.
     } 


    # CALIBRATION VALUES (ONLY FOR THE OPTION EPN-STRICT)
    if (
       ($epnstrict eq 'true') &&
       ($error_antennatype eq 'false') &&
       ($error_radometype eq 'false')
       )
     {


       $antfound = 'false';
       $atxfound = 'false';
       open (ATXFile, $atxfile) || die "Cannot open $_";

       while (!eof(ATXFile))
        {


        $line = <ATXFile>;
        if (substr($line,60,16) eq 'TYPE / SERIAL NO')
         {
           if (
              (substr($line,0,20) eq $antenna{type}[$i]) &&
              (
               (trim(substr($line,20,40)) eq '') ||
               (trim(substr($line,20,40)) eq $antenna{serial_number}[$i])
              )
              )
             {
               $antfound = 'true';
               while (substr($line,60,4) ne 'DAZI') { $line = <ATXFile>; }
               if (trim(substr($line,0,10)) ne '0.0') { $atxfound = 'true'; }
             }
        
         }

        }
       close(ATXFile);


       if ($antfound eq 'false')
        {
         print('Section 4.' . $i . ' - Antenna Type : ' . trim($antenna{type}[$i]) . ' not found in ' . $atxfile . "\n");
        }

       if ( ($antfound eq 'true') && ($atxfound eq 'false') )
        {
         print('Section 4.' . $i . ' - Antenna Type : no true (or individual) absolute calibrations available for ' . trim($antenna{type}[$i]) . ' in ' . $atxfile . "\n");
        }

       #print($antfound . " " . $atxfound . "\n");

     }

    # RADOME SERIAL NUMBER --> only warning
    if (length(trim($antenna{radome_serial_number}[$i])) == 0 )
     {
     }

    # ANTENNA CABLE TYPE --> only warning
    if ( (length(trim($antenna{antenna_cable_type}[$i])) == 0 ) || ($antenna{antenna_cable_type}[$i] eq '(vendor & type number)') )
     {
     }

    # ANTENNA CABLE LENGTH --> only warning (if missing)
    if (length(trim($antenna{antenna_cable_length}[$i])) == 0)
     {
     }

    if (
       ($antenna{antenna_cable_length}[$i] !~ /^[-0-9]{1,}\.[0-9]{1,}$/ ) &&
       ($antenna{antenna_cable_length}[$i] !~ /^[-0-9]{1,}$/ ) &&
       (length(trim($antenna{antenna_cable_length}[$i])) > 0)
       )
     {
         print('Section 4.' . $i . ' - Antenna Cable Length : invalid format. Use integer or float.' . "\n");
     }



    # DATE INSTALLED
    $error_date_installed = check_stationlogdate($antenna{date_installed}[$i]);
    if($error_date_installed ne '')
     {
       print('Section 4.' . $i . ' - Date Installed : ' . $error_date_installed . "\n");
     }

    # DATE REMOVED
    if($i < $number_antennae)
    {
    $error_date_removed = check_stationlogdate($antenna{date_removed}[$i]);
    if($error_date_removed ne '')
     {
       print('Section 4.' . $i . ' - Date Removed : ' . $error_date_removed . "\n");
     }
    }

    if(
      ($i == $number_antennae) &&
      ($antenna{date_removed}[$i] ne "CCYY-MM-DDThh:mmZ") &&
      ($antenna{date_removed}[$i] ne "CCYY-MM-DD") &&
      ($antenna{date_removed}[$i] ne "(CCYY-MM-DDThh:mmZ)") &&
      ($antenna{date_removed}[$i] ne "(CCYY-MM-DDThh:mm") &&
      ($antenna{date_removed}[$i] ne "")
      )
    {
    $error_date_removed = check_stationlogdate($antenna{date_removed}[$i]);
    if($error_date_removed ne '')
     {
       print('Section 4.' . $i . ' - Date Removed : ' . $error_date_removed . "\n");
     }
    }

=pod
# necessary reinitialization
if (
     ($dateremovedantenna[$counterAnt] == "(CCYY-MM-DDThh:mmZ)") or
     ($dateremovedantenna[$counterAnt] == "(CCYY-MM-DDThh:mm") or
     ($dateremovedantenna[$counterAnt] == "")
   )
     { $dateremovedantenna[$counterAnt] = 'CCYY-MM-DDThh:mmZ'; }
=cut


    # DATE INSTALLED and DATE REMOVED : chronology comparison
    if (
       ($error_date_installed eq "") &&
       ($error_date_removed eq "") &&
       ($antenna{date_installed}[$i] gt $antenna{date_removed}[$i] )
       )
     {
       if (!(
            (substr($antenna{date_installed}[$i],0,10) eq substr($antenna{date_removed}[$i],0,10) ) &&
            (length($antenna{date_removed}[$i]) == 10) &&
            (substr($antenna{date_installed}[$i],10,7) eq 'T00:00Z')
            )
          )
        {
          print('Section 4.' . $i . ' - Date Removed precedes Date Installed' . "\n");
        }
     }


    # DATE INSTALLED (current installation) and DATE REMOVED (previous installation) : chronology comparison
    if (
       ($error_date_installed eq "") &&
       ($previous_error_date_removed eq "") &&
       ($antenna{date_installed}[$i] lt $antenna{date_removed}[($i-1)] )
       )
      {
       if (!(
            (substr($antenna{date_installed}[$i],0,10) eq substr($antenna{date_removed}[($i-1)],0,10) ) &&
            (length($antenna{date_installed}[$i]) == 10) &&
            (substr($antenna{date_removed}[($i-1)],10,7) eq 'T00:00Z')
            )
          )
        {
          print('Sections 4.' . ($i-1) . ' and 4.' . $i . ' - Date Installed (subsection 4.' . $i . ') precedes Date Removed (subsection 4.' . ($i-1) . ')' . "\n");
        }
      }


    $previous_error_date_removed = $error_date_removed;



   }   

  if ($number_antennae == 0)
   {
      print('Section 4 - GNSS Antenna Information : missing section' . "\n");
   }



  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 5 - title of that section not found.'; }


  #######################################################################
  # READ SECTION 5.
  #######################################################################
#  print (" read 5\n");
  $number_localties = 0;
  
  while ( ( $line !~ /^6.\s*Frequency\s*Standard\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Tied\s*Marker\s*Name\s*/i ) && ($line !~ /\s*5.x\s*/i ) )
          {
            $number_localties++;   
            $localties{tied_marker_name}[$number_localties] = trim(substr($line,32,length($line)-33));
            #$localties{tied_marker_name}[$number_localties] =~s/\'/&#39;/g;
            #$localties{tied_marker_name}[$number_localties] =~s/"/&#39;/g;
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Tied\s*Marker\s*Usage\s*/i )          { $localties{tied_marker_usage}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Tied\s*Marker\s*CDP\s*Number\s*/i )   { $localties{tied_marker_cdp_number}[$number_localties] = trim(substr($line,32,4)); } 
                 if (substr($line,0,32) =~ /\s*Tied\s*Marker\s*DOMES\s*Number\s*/i ) { $localties{tied_marker_domes_number}[$number_localties] = trim(substr($line,32,9)); } 
                 if (substr($line,0,32) =~ /\s*dx\s*\(m\)\s*/i )                     { $localties{dx}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*dy\s*\(m\)\s*/i )                     { $localties{dy}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*dz\s*\(m\)\s*/i )                     { $localties{dz}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Accuracy\s*\(mm\)\s*/i )              { $localties{accuracy}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Survey\s*method\s*/i )                { $localties{survey_method}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Date\s*Measured\s*/i )                { $localties{date_measured}[$number_localties] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $localties{additional_information}[$number_localties] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $localties{additional_information}[$number_localties] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 5.' . $number_localties . ' - no empty line after that subsection'; }
                 }
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 5.' . $number_localties . ' - no empty line after that subsection'; }
          }
     }
      
  for($i=1;$i<=$number_localties;$i++)
   {
#      print("$localties{tied_marker_name}[$i]\n");
#      print("$localties{tied_marker_usage}[$i] $localties{tied_marker_cdp_number}[$i] $localties{tied_marker_domes_number}[$i]\n");
#      print("$localties{dx}[$i] $localties{dy}[$i] $localties{dz}[$i]\n");
#      print("$localties{accuracy}[$i] $localties{survey_method}[$i] $localties{date_measured}[$i]\n");
#      print("$localties{additional_information}[$i]\n");

      $localties{tied_marker_name}[$i] =~ s/\'/&#39;/g;
      $localties{tied_marker_name}[$i] =~ s/"/&#39;/g;
      $localties{dx}[$i] =~ s/^\+//;
      $localties{dy}[$i] =~ s/^\+//;
      $localties{dz}[$i] =~ s/^\+//;
      $localties{dx}[$i] =~ s/m$//;
      $localties{dy}[$i] =~ s/m$//;
      $localties{dz}[$i] =~ s/m$//;
      $localties{dx}[$i] =~ s/,/\./;
      $localties{dy}[$i] =~ s/,/\./;
      $localties{dz}[$i] =~ s/,/\./;
      $localties{accuracy}[$i] =~ s/^\+\/\-//;
      $localties{accuracy}[$i] =~ s/mm$//;
      $localties{accuracy}[$i] =~ s/\(mm\)$//;
      $localties{additional_information}[$i] =~ s/\'/&#39;/g;
      $localties{additional_information}[$i] =~ s/"/&#39;/g;


      # TIED MARKER NAME
      if (length(trim($localties{tied_marker_name}[$i])) == 0)
       {
         print('Section 5.' . $i . ' - Tied Marker Name : missing input' . "\n");
       }

      # TIED MARKER USAGE --> only warning
      if ( (length(trim($localties{tied_marker_usage}[$i])) == 0) || (trim($localties{tied_marker_usage}[$i]) eq '(SLR/VLBI/LOCAL CONTROL/FOOTPRINT/etc)') )
       {
         # print('Section 5.' . $i . ' - Tied Marker Usage : missing input' . "\n");
       }

      # TIED MARKER CDP NUMBER
      if (
          (length(trim($localties{tied_marker_cdp_number}[$i])) > 0) &&
          (length(trim($localties{tied_marker_cdp_number}[$i])) != 4) &&
          (trim($localties{tied_marker_cdp_number}[$i]) ne '(A4)')
         )
       {
         print('Section 5.' . $i . ' - Tied Marker CDP Number : invalid format. Use A4 (or blank).' . "\n");
       }

      # TIED MARKER DOMES NUMBER
      if (
          (length(trim($localties{tied_marker_domes_number}[$i])) > 0) &&
          (length(trim($localties{tied_marker_domes_number}[$i])) != 9) &&
          (trim($localties{tied_marker_domes_number}[$i]) ne '(A9)')
         )
       {
         print('Section 5.' . $i . ' - Tied Marker DOMES Number : invalid format. Use A9 (or blank).' . "\n");
       }


      # Differential Components from GNSS Marker to the tied monument (ITRS) - dx (m)
      if (
          (trim($localties{dx}[$i]) ne '') &&
          (trim($localties{dx}[$i]) ne '(m)') &&
          (trim($localties{dx}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
          (trim($localties{dx}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}$/ )
         )
       {
         print('Section 5.' . $i . ' - Differential Components from GNSS Marker to the tied monument (ITRS) - dx (m) : invalid format. Use integer or float (or blank).' . "\n");
       }


      # Differential Components from GNSS Marker to the tied monument (ITRS) - dy (m)
      if (
          (trim($localties{dy}[$i]) ne '') &&
          (trim($localties{dy}[$i]) ne '(m)') &&
          (trim($localties{dy}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
          (trim($localties{dy}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}$/ )
         )
       {
         print('Section 5.' . $i . ' - Differential Components from GNSS Marker to the tied monument (ITRS) - dy (m) : invalid format. Use integer or float (or blank).' . "\n");
       }

      # Differential Components from GNSS Marker to the tied monument (ITRS) - dz (m)
      if (
          (trim($localties{dz}[$i]) ne '') &&
          (trim($localties{dz}[$i]) ne '(m)') &&
          (trim($localties{dz}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
          (trim($localties{dz}[$i]) !~ /^[-0-9]{0,1}[0-9]{1,}$/ )
         )
       {
         print('Section 5.' . $i . ' - Differential Components from GNSS Marker to the tied monument (ITRS) - dz (m) : invalid format. Use integer or float (or blank).' . "\n");
       }

      # ACCURACY
      if (
          (trim($localties{accuracy}[$i]) !~ /^[0-9]{1,}\.[0-9]{1,}$/ ) &&
          (trim($localties{accuracy}[$i]) !~ /^[0-9]{1,}$/ ) &&
          (trim($localties{accuracy}[$i]) !~ /^<\s{0,}[0-9]{1,}\.[0-9]{1,}$/ ) &&
          (trim($localties{accuracy}[$i]) !~ /^<\s{0,}[0-9]{1,}$/ ) &&
          (length(trim($localties{accuracy}[$i])) > 0) &&
          (trim($localties{accuracy}[$i]) ne '(mm)')
         )
       {
         print('Section 5.' . $i . ' - Accuracy (mm) : invalid format. Use integer or float (may be preceded by "<" ) ... or blank.' . "\n");
       }

      # SURVEY METHOD
      if ( (length(trim($localties{survey_method}[$i])) == 0) || (trim($localties{survey_method}[$i]) eq '(GPS CAMPAIGN/TRILATERATION/TRIANGULATION/etc)') )
       {
         print('Section 5.' . $i . ' - Survey method : missing input' . "\n");
       }

      # DATE MEASURED
      $error_date_measured = check_stationlogdate($localties{date_measured}[$i]);
      if ( ($error_date_measured ne '') && (trim($localties{date_measured}[$i]) ne '(CCYY-MM-DDThh:mmZ)') )
       {
         print('Section 5.' . $i . ' - Date Measured : ' . $error_date_measured . "\n");
       }


   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 6 - title of that section not found.'; }



  #######################################################################
  # READ SECTION 6.
  #######################################################################
#  print (" read 6\n");
  $number_frequencies = 0;
  
  while ( ( $line !~ /^7.\s*Collocation\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Standard\s*Type\s*/i ) && ($line !~ /\s*6.x\s*/i ) )
          {
            $number_frequencies++;   
            $frequencies{standard_type}[$number_frequencies] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Input\s*Frequency\s*/i )   { $frequencies{input_frequency}[$number_frequencies] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )   { $frequencies{effective_dates}[$number_frequencies] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $frequencies{notes}[$number_frequencies] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $frequencies{notes}[$number_frequencies] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 6.' . $number_frequencies . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 6.' . $number_frequencies . '.'; }
          }  
     }
      
  for($i=1;$i<=$number_frequencies;$i++)
   {
#      print("$frequencies{standard_type}[$i] $frequencies{input_frequency}[$i] $frequencies{effective_dates}[$i]\n");
#      print("$frequencies{notes}[$i]\n");

       
       $frequencies{input_frequency}[$i] =~s/MHz$//;
       $frequencies{input_frequency}[$i] = trim($frequencies{input_frequency}[$i]);
       $frequencies{notes}[$i] =~s/\'/&#39;/g;
       $frequencies{notes}[$i] =~s/"/&#39;/g;


       # STANDARD TYPE
       if (
          (trim($frequencies{standard_type}[$i]) eq '' ) ||
          (trim($frequencies{standard_type}[$i]) eq '(INTERNAL or EXTERNAL H-MASER/CESIUM/etc)' )
          )
        {
         print('Section 6.' . $i . ' - Standard Type : missing input' . "\n");
        }


       if (trim($frequencies{standard_type}[$i]) eq 'INTERNAL') { $internal_frequency = 'true'; }
       else  { $internal_frequency = 'false'; }

       if (
          (length(trim($frequencies{standard_type}[$i])) <= 9 ) &&
          (length(trim($frequencies{standard_type}[$i])) > 0 ) &&
          (trim($frequencies{standard_type}[$i]) ne 'INTERNAL')
          )
         {
         print('Section 6.' . $i . ' - Standard Type : invalid format. Use INTERNAL or EXTERNAL H-MASER/CESIUM/etc.' . "\n");
         }

       $external_frequency = 'false';
       if (length(trim($frequencies{standard_type}[$i])) > 9 )
         {
          if (substr(trim($frequencies{standard_type}[$i]),0,9) ne 'EXTERNAL ')
           {
             print('Section 6.' . $i . ' - Standard Type : invalid format. Use INTERNAL or EXTERNAL H-MASER/CESIUM/etc.' . "\n");
           }
          else
           {
             $external_frequency = 'true';
           }
         }


       # INPUT FREQUENCY
       if (
           ( $external_frequency eq 'true') &&
           ( ( length($frequencies{input_frequency}[$i]) == 0) or ($frequencies{input_frequency}[$i] eq '(if external)') )
          )
        {
         print('Section 6.' . $i . ' - Input Frequency : missing input' . "\n");
        }

       if (
           ($internal_frequency eq 'true') &&
           (length($frequencies{input_frequency}[$i]) > 0) &&
           ($frequencies{input_frequency}[$i] ne '(if external)')
          )
        {
         print('Section 6.' . $i . ' - Input Frequency : not allowed for INTERNAL frequency' . "\n");
        }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES (not for the LAST subsection)
       if (
          (trim($frequencies{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_frequencies)
          )
        {
         print('Section 6.' . $i . ' - Effective Dates : complete the start and end dates' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($frequencies{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_frequencies)
          )
        {
         if (
            (substr($frequencies{effective_dates}[$i],0,4) < 1980 ) ||
            (substr($frequencies{effective_dates}[$i],0,4) > $year)
            )
           {
            print('Section 6.' . $i . ' - Effective Dates (begin) : ' . substr($frequencies{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         if (
            (substr($frequencies{effective_dates}[$i],11,4) < 1980 ) ||
            (substr($frequencies{effective_dates}[$i],11,4) > $year)
            )
           {
            print('Section 6.' . $i . ' - Effective Dates (end) : ' . substr($frequencies{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         $error_effective_dates[$i] = check_stationlogdate(substr($frequencies{effective_dates}[$i],0,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 6.' . $i . ' - Effective Dates (begin) : ' . substr($frequencies{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

         $error_effective_dates[$i] = check_stationlogdate(substr($frequencies{effective_dates}[$i],11,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 6.' . $i . ' - Effective Dates (end) : ' . substr($frequencies{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

       }			 	

       # EFFECTIVE DATES (ONLY for the LAST subsection)
       if (
          (trim($frequencies{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_frequencies)
          )
        {
         print('Section 6.' . $i . ' - Effective Dates : complete only the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($frequencies{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_frequencies)
          )
        {
          if (
             (substr($frequencies{effective_dates}[$i],0,4) < 1980 ) ||
             (substr($frequencies{effective_dates}[$i],0,4) > $year)
             )
            {
             print('Section 6.' . $i . ' - Effective Dates (begin) : ' . substr($frequencies{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($frequencies{effective_dates}[$i],0,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 6.' . $i . ' - Effective Dates (begin) : ' . substr($frequencies{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }
	
       # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
       if (
          ($error_effective_dates[$i] eq '') &&
          ( substr($frequencies{effective_dates}[$i],0,10) gt substr($frequencies{effective_dates}[$i],11,11) )
          )
         {
           print('Section 6.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
         }

       # EFFECTIVE DATES (chronology comparison between Date Installed and ... Date Removed of the previous installation)
       if (
          ($error_effective_dates[$i] eq '') &&
          ($error_effective_dates[($i-1)] eq '') &&
          ( substr($frequencies{effective_dates}[$i],0,10) lt substr($frequencies{effective_dates}[($i-1)],11,11) )
          )
       {
         print('Section 6.' . $i . ' - Effective Dates : the date of installation precede the date of removing of the previous installation (6.' . ($i-1) . ')' . "\n");
       }

   }   

  if ($number_frequencies == 0)
   {
      print('Section 6 - Frequency Standard : missing section' . "\n");
   }



  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 7 not found.'; }



  #######################################################################
  # READ SECTION 7.
  #######################################################################
#  print (" read 7\n");
  $number_instrumentation = 0;
  
  while ( ( $line !~ /^8.\s*Meteorological\s*Instrumentation\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Instrumentation\s*Type\s*/i ) && ($line !~ /\s*7.x\s*/i ) )
          {
            $number_instrumentation++;   
            $instrumentation{instrumentation_type}[$number_instrumentation] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Status\s*/i )            { $instrumentation{status}[$number_instrumentation] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i ) { $instrumentation{effective_dates}[$number_instrumentation] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $instrumentation{notes}[$number_instrumentation] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $instrumentation{notes}[$number_instrumentation] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 7.' . $number_instrumentation . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 7.' . $number_instrumentation . '.'; }
          }  
     }

  for($i=1;$i<=$number_instrumentation;$i++)
   {
#      print("$instrumentation{instrumentation_type}[$i] $instrumentation{status}[$i] $instrumentation{effective_dates}[$i]\n");
#      print("$instrumentation{notes}[$i]\n");

      $instrumentation{notes}[$i]=~s/\'/&#39;/g;
      $instrumentation{notes}[$i]=~s/"/&#39;/g;
      $instrumentation{status}[$i] = uc($instrumentation{status}[$i]);

=pod
      if (
          ($instrumentation{instrumentation_type}[$i] ne '(GPS/GLONASS/DORIS/PRARE/SLR/VLBI/TIME/etc)') or
          ($instrumentation{status}[$i] ne '(PERMANENT/MOBILE)') or
          ($instrumentation{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
          ($instrumentation{notes}[$i] ne '(multiple lines)')
         )
      {         
      }
=cut


      # INSTRUMENTATION TYPE
       if (
          (trim($instrumentation{instrumentation_type}[$i]) eq '' ) ||
          (trim($instrumentation{instrumentation_type}[$i]) eq '(GPS/GLONASS/DORIS/PRARE/SLR/VLBI/TIME/etc)' )
          )
        {
         print('Section 7.' . $i . ' - Instrumentation Type : missing input' . "\n");
        }

      # STATUS
       if (
          (trim($instrumentation{status}[$i]) eq '' ) ||
          (trim($instrumentation{status}[$i]) eq '(PERMANENT/MOBILE)' )
          )
        {
         print('Section 7.' . $i . ' - Status : missing input' . "\n");
        }

       if (
          (trim($instrumentation{status}[$i]) ne '' ) &&
          (trim($instrumentation{status}[$i]) ne '(PERMANENT/MOBILE)' ) &&
          (trim($instrumentation{status}[$i]) ne 'PERMANENT' ) &&
          (trim($instrumentation{status}[$i]) ne 'MOBILE' )
          )
        {
         print('Section 7.' . $i . ' - Status : invalid input. Please fill PERMANENT or MOBILE.' . "\n");
        }







       $error_effective_dates[$i] = '';


       # EFFECTIVE DATES
       if (
          (trim($instrumentation{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($instrumentation{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          )
        {
         print('Section 7.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }
       else
        {

          if (trim($instrumentation{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
           {
            if (
               #(substr($instrumentation{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($instrumentation{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 7.' . $i . ' - Effective Dates (begin) : ' . substr($instrumentation{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

           if (
              #(substr($instrumentation{effective_dates}[$i],11,4) < 1980 ) ||
              (substr($instrumentation{effective_dates}[$i],11,4) > $year)
              )
             {
              print('Section 7.' . $i . ' - Effective Dates (end) : ' . substr($instrumentation{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
              $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($instrumentation{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 7.' . $i . ' - Effective Dates (begin) : ' . substr($instrumentation{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($instrumentation{effective_dates}[$i],11,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 7.' . $i . ' - Effective Dates (end) : ' . substr($instrumentation{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }


            # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
            if (
               ($error_effective_dates[$i] eq '') &&
               ( substr($instrumentation{effective_dates}[$i],0,10) gt substr($instrumentation{effective_dates}[$i],11,11) )
               )
             {
              print('Section 7.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
             }



           }


         if (trim($instrumentation{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          {
            if (
               #(substr($instrumentation{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($instrumentation{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 7.' . $i . ' - Effective Dates (begin) : ' . substr($instrumentation{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($instrumentation{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 7.' . $i . ' - Effective Dates (begin) : ' . substr($instrumentation{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

          }


      }




   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 8 not found.'; }



  #######################################################################
  # READ SECTION 8.1
  #######################################################################
#  print (" read 8.1\n");
  $number_humiditysensor = 0;
  
  while ( ( $line !~ /^8.1.x\s*Humidity\s*Sensor\s*Model\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Humidity\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.1.x\s*/i ) )
          {
            $number_humiditysensor++;   
            $humiditysensor{model}[$number_humiditysensor] = trim(substr($line,32,length($line)-33));
             while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Manufacturer\s*/i )               { $humiditysensor{manufacturer}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Serial\s*Number\s*/i )            { $humiditysensor{serial_number}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $humiditysensor{data_sampling_interval}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Accuracy\s*\(\% rel h\)\s*/i )    { $humiditysensor{accuracy}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Aspiration\s*/i )                 { $humiditysensor{aspiration}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $humiditysensor{height_diff_to_ant}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Calibration\s*date\s*/i )         { $humiditysensor{calibration_date}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )          { $humiditysensor{effective_dates}[$number_humiditysensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $humiditysensor{notes}[$number_humiditysensor] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $humiditysensor{notes}[$number_humiditysensor] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.1.' . $number_humiditysensor . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.1.' . $number_humiditysensor . '.'; }
          }  
     }
      
  for($i=1;$i<=$number_humiditysensor;$i++)
   {
#      print("$humiditysensor{model}[$i] $humiditysensor{manufacturer}[$i] $humiditysensor{serial_number}[$i] $humiditysensor{data_sampling_interval}[$i] $humiditysensor{accuracy}[$i] $humiditysensor{aspiration}[$i] $humiditysensor{height_diff_to_ant}[$i] $humiditysensor{calibration_date}[$i] $humiditysensor{effective_dates}[$i]\n");
#      print("$humiditysensor{notes}[$i]\n");

       $humiditysensor{model}[$i]=~s/\'/&#39;/g;
       $humiditysensor{model}[$i]=~s/"/&#39;/g;
       $humiditysensor{manufacturer}[$i]=~s/\'/&#39;/g;
       $humiditysensor{manufacturer}[$i]=~s/"/&#39;/g;
       $humiditysensor{data_sampling_interval}[$i] =~s/s$//;
       $humiditysensor{data_sampling_interval}[$i] =~s/sec$//;
       $humiditysensor{data_sampling_interval}[$i] =~s/SEC$//;
       $humiditysensor{data_sampling_interval}[$i] = trim($humiditysensor{data_sampling_interval}[$i]);
       $humiditysensor{accuracy}[$i] =~s/\(% rel h\)$//;
       $humiditysensor{accuracy}[$i] =~s/%rel h$//;
       $humiditysensor{accuracy}[$i] =~s/% rel h$//;
       $humiditysensor{accuracy}[$i] =~s/%$//;
       $humiditysensor{accuracy}[$i] =~s/\.$//;
       $humiditysensor{accuracy}[$i] =~s/^\./0./;
       $humiditysensor{accuracy}[$i] =~s/\+\/\-//;
       $humiditysensor{accuracy}[$i] = trim($humiditysensor{accuracy}[$i]);
       $humiditysensor{height_diff_to_ant}[$i] =~s/,/./g;
       $humiditysensor{height_diff_to_ant}[$i] =~s/M$//;
       $humiditysensor{height_diff_to_ant}[$i] =~s/m$//;
       $humiditysensor{height_diff_to_ant}[$i] =~ s/^\+//;
       $humiditysensor{height_diff_to_ant}[$i] = trim($humiditysensor{height_diff_to_ant}[$i]);
       $humiditysensor{notes}[$i] =~s/\'/&#39;/g;
       $humiditysensor{notes}[$i] =~s/"/&#39;/g;

#print("$quoted_humiditysensor{manufacturer}[$i]\n");

       if (
          ($humiditysensor{model}[$i] ne '') or          
          ($humiditysensor{manufacturer}[$i] ne '') or
          ($humiditysensor{serial_number}[$i] ne '') or
          ($humiditysensor{data_sampling_interval}[$i] ne '(sec)') or
          ($humiditysensor{accuracy}[$i] ne '') or                       #   (% rel h)
          ($humiditysensor{aspiration}[$i] ne '(UNASPIRATED/NATURAL/FAN/etc)') or
          ($humiditysensor{height_diff_to_ant}[$i] ne '(m)') or
          ($humiditysensor{calibration_date}[$i] ne '(CCYY-MM-DD)') or
          ($humiditysensor{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
          ($humiditysensor{notes}[$i] ne '(multiple lines)')
          )
      {
      }


     # MODEL
     if ( length(trim($humiditysensor{model}[$i])) == 0 )
      {
         print('Section 8.1.' . $i . ' - Humidity Sensor Model : missing input' . "\n");
      }

     # MANUFACTURER
     if ( length(trim($humiditysensor{manufacturer}[$i])) == 0 )
      {
         #print('Section 8.1.' . $i . ' - Manufacturer : missing input' . "\n");
      }

     # SERIAL NUMBER
     if ( length(trim($humiditysensor{serial_number}[$i])) == 0 )
      {
         #print('Section 8.1.' . $i . ' - Serial Number : missing input' . "\n");
      }

     # DATA SAMPLING INTERVAL
     if ( length(trim($humiditysensor{data_sampling_interval}[$i])) == 0 )
      {
         #print('Section 8.1.' . $i . ' - Data Sampling Interval : missing input' . "\n");
      }

     if (
        ( length(trim($humiditysensor{data_sampling_interval}[$i])) > 0 ) &&
        ($humiditysensor{data_sampling_interval}[$i] !~ /^[0-9]{1,}$/ )
        )
      {
         print('Section 8.1.' . $i . ' - Data Sampling Interval : invalid format. Use integer.' . "\n");
      }

     # ACCURACY
     if ( length(trim($humiditysensor{accuracy}[$i])) == 0 )
      {
         #print('Section 8.1.' . $i . ' - Accuracy : missing input' . "\n");
      }

     if (
        ( length(trim($humiditysensor{accuracy}[$i])) > 0 ) &&
        ($humiditysensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($humiditysensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.1.' . $i . ' - Accuracy : invalid format. Use integer or float (may be preceded by "<").' . "\n");
      }

     # ASPIRATION
     if (
        (length(trim($humiditysensor{aspiration}[$i])) == 0 ) ||
        (trim($humiditysensor{aspiration}[$i]) eq '(UNASPIRATED/NATURAL/FAN/etc)')
        )
      {
         #print('Section 8.1.' . $i . ' - Aspiration : missing input' . "\n");
      }

     # HEIGHT DIFF TO ANT
     if ( length(trim($humiditysensor{height_diff_to_ant}[$i])) == 0 )
      {
         print('Section 8.1.' . $i . ' - Height Diff to Ant : missing input' . "\n");
      }

     if (
        ( length(trim($humiditysensor{height_diff_to_ant}[$i])) > 0 ) and
        ($humiditysensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($humiditysensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.1.' . $i . ' - Height Diff to Ant : invalid format. Use integer or float.' . "\n");
      }

     # CALIBRATION DATE
     if ($humiditysensor{calibration_date}[$i] !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
      {
         #print('Section 8.1.' . $i . ' - Calibration date : missing or invalid input' . "\n");
      }
     else
      {

        if (
           (substr($humiditysensor{calibration_date}[$i],0,4) < 1800 ) ||
           (substr($humiditysensor{calibration_date}[$i],0,4) > $year) ||
           !(check_date(substr($humiditysensor{calibration_date}[$i],0,4), substr($humiditysensor{calibration_date}[$i],5,2), substr($humiditysensor{calibration_date}[$i],8,2)))
           )				 
            {
             print('Section 8.1.' . $i . ' - Calibration date : senseless date' . "\n");
            }

      }



       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES (not for the LAST subsection)
       if (
          (trim($humiditysensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_humiditysensor)
          )
        {
         print('Section 8.1.' . $i . ' - Effective Dates : complete the start and end dates' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($humiditysensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_humiditysensor)
          )
        {
         if (
            (substr($humiditysensor{effective_dates}[$i],0,4) < 1980 ) ||
            (substr($humiditysensor{effective_dates}[$i],0,4) > $year)
            )
           {
            print('Section 8.1.' . $i . ' - Effective Dates (begin) : ' . substr($humiditysensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         if (
            (substr($humiditysensor{effective_dates}[$i],11,4) < 1980 ) ||
            (substr($humiditysensor{effective_dates}[$i],11,4) > $year)
            )
           {
            print('Section 8.1.' . $i . ' - Effective Dates (end) : ' . substr($humiditysensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         $error_effective_dates[$i] = check_stationlogdate(substr($humiditysensor{effective_dates}[$i],0,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.1.' . $i . ' - Effective Dates (begin) : ' . substr($humiditysensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

         $error_effective_dates[$i] = check_stationlogdate(substr($humiditysensor{effective_dates}[$i],11,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.1.' . $i . ' - Effective Dates (end) : ' . substr($humiditysensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

       }			 	

       # EFFECTIVE DATES (ONLY for the LAST subsection)

       if (
          (trim($humiditysensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          (trim($humiditysensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i == $number_humiditysensor)
          )
        {
         print('Section 8.1.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }


       if (
          (trim($humiditysensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_humiditysensor)
          )
        {
          if (
             (substr($humiditysensor{effective_dates}[$i],0,4) < 1980 ) ||
             (substr($humiditysensor{effective_dates}[$i],0,4) > $year)
             )
            {
             print('Section 8.1.' . $i . ' - Effective Dates (begin) : ' . substr($humiditysensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($humiditysensor{effective_dates}[$i],0,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.1.' . $i . ' - Effective Dates (begin) : ' . substr($humiditysensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }



       if (
          (trim($humiditysensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i == $number_humiditysensor)
          )
        {
          if (
             (substr($humiditysensor{effective_dates}[$i],11,4) < 1980 ) ||
             (substr($humiditysensor{effective_dates}[$i],11,4) > $year)
             )
            {
             print('Section 8.1.' . $i . ' - Effective Dates (end) : ' . substr($humiditysensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($humiditysensor{effective_dates}[$i],11,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.1.' . $i . ' - Effective Dates (end) : ' . substr($humiditysensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }
	
       # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
       if (
          ($error_effective_dates[$i] eq '') &&
          ( substr($humiditysensor{effective_dates}[$i],0,10) gt substr($humiditysensor{effective_dates}[$i],11,11) )
          )
         {
           print('Section 8.1.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
         }

       # EFFECTIVE DATES (chronology comparison between Date Installed and ... Date Removed of the previous installation)
       if (
          ($error_effective_dates[$i] eq '') &&
          ($error_effective_dates[($i-1)] eq '') &&
          ( substr($humiditysensor{effective_dates}[$i],0,10) lt substr($humiditysensor{effective_dates}[($i-1)],11,11) )
          )
       {
         print('Section 8.1.' . $i . ' - Effective Dates : the date of installation precede the date of removing of the previous installation (8.1.' . ($i-1) . ')' . "\n");
       }



   }

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 8.1.x not found.'; }


  #######################################################################
  # READ SECTION 8.2
  #######################################################################
#  print (" read 8.2\n");
  $number_pressuresensor = 0;
  
  while ( ( $line !~ /^8.2.x\s*Pressure\s*Sensor\s*Model\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Pressure\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.2.x\s*/i ) )
          {
            $number_pressuresensor++;   
            $pressuresensor{model}[$number_pressuresensor] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Manufacturer\s*/i )               { $pressuresensor{manufacturer}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Serial\s*Number\s*/i )            { $pressuresensor{serial_number}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $pressuresensor{data_sampling_interval}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Accuracy\s*/i )                   { $pressuresensor{accuracy}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $pressuresensor{height_diff_to_ant}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Calibration\s*date\s*/i )         { $pressuresensor{calibration_date}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )          { $pressuresensor{effective_dates}[$number_pressuresensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $pressuresensor{notes}[$number_pressuresensor] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $pressuresensor{notes}[$number_pressuresensor] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.2.' . $number_pressuresensor . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.2.' . $number_pressuresensor . '.'; }
          }  
     }
      
  for($i=1;$i<=$number_pressuresensor;$i++)
   {
#      print("press $pressuresensor{model}[$i] $pressuresensor{manufacturer}[$i] $pressuresensor{serial_number}[$i] $pressuresensor{data_sampling_interval}[$i] $pressuresensor{accuracy}[$i] $pressuresensor{height_diff_to_ant}[$i] $pressuresensor{calibration_date}[$i] $pressuresensor{effective_dates}[$i]\n");
#      print("$pressuresensor{notes}[$i]\n");

      $pressuresensor{model}[$i] =~s/\'/&#39;/g;
      $pressuresensor{model}[$i] =~s/"/&#39;/g;
      $pressuresensor{manufacturer}[$i] =~s/\'/&#39;/g;
      $pressuresensor{manufacturer}[$i] =~s/"/&#39;/g;
      $pressuresensor{data_sampling_interval}[$i] =~s/s$//;      
      $pressuresensor{data_sampling_interval}[$i] =~s/sec$//;
      $pressuresensor{data_sampling_interval}[$i] =~s/SEC$//;
      $pressuresensor{data_sampling_interval}[$i] = trim($pressuresensor{data_sampling_interval}[$i]);
      $pressuresensor{accuracy}[$i] =~s/^\./0./;
      $pressuresensor{accuracy}[$i] =~s/\.$//;
      $pressuresensor{accuracy}[$i] =~s/hPa sigma$//;
      $pressuresensor{accuracy}[$i] =~s/hPa$//;
      $pressuresensor{accuracy}[$i] =~s/hpa$//;
      $pressuresensor{accuracy}[$i] =~s/hp$//;
      $pressuresensor{accuracy}[$i] =~s/\(mbar\)$//;
      $pressuresensor{accuracy}[$i] =~s/mbar$//;
      $pressuresensor{accuracy}[$i] =~s/mb$//;
      $pressuresensor{accuracy}[$i] =~s/\+\/\-//;
      $pressuresensor{accuracy}[$i] = trim($pressuresensor{accuracy}[$i]);
      $pressuresensor{height_diff_to_ant}[$i] =~s/\(m\)$//;
      $pressuresensor{height_diff_to_ant}[$i] =~s/m$//;
      $pressuresensor{height_diff_to_ant}[$i] =~ s/^\+//;
      $pressuresensor{height_diff_to_ant}[$i] =~s/,/./g;
      $pressuresensor{height_diff_to_ant}[$i] = trim($pressuresensor{height_diff_to_ant}[$i]);
      $pressuresensor{notes}[$i]=~s/\'/&#39;/g;
      $pressuresensor{notes}[$i]=~s/"/&#39;/g;
      
      if(
         ($pressuresensor{model}[$i] ne '') or
         ($pressuresensor{manufacturer}[$i] ne '') or
         ($pressuresensor{serial_number}[$i] ne '') or
         ($pressuresensor{data_sampling_interval}[$i] ne '(sec)') or
         ($pressuresensor{accuracy}[$i] ne '(hPa)') or
         ($pressuresensor{height_diff_to_ant}[$i] ne '') or    # (m)
         ($pressuresensor{calibration_date}[$i] ne '(CCYY-MM-DD)') or
         ($pressuresensor{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
         ($pressuresensor{notes}[$i] ne '(multiple lines)')
        )
      {                
      }

     # MODEL
     if ( length(trim($pressuresensor{model}[$i])) == 0 )
      {
         print('Section 8.2.' . $i . ' - Pressure Sensor Model : missing input' . "\n");
      }

     # MANUFACTURER
     if ( length(trim($pressuresensor{manufacturer}[$i])) == 0 )
      {
         #print('Section 8.2.' . $i . ' - Manufacturer : missing input' . "\n");
      }

     # SERIAL NUMBER
     if ( length(trim($pressuresensor{serial_number}[$i])) == 0 )
      {
         #print('Section 8.2.' . $i . ' - Serial Number : missing input' . "\n");
      }

     # DATA SAMPLING INTERVAL
     if ( length(trim($pressuresensor{data_sampling_interval}[$i])) == 0 )
      {
         #print('Section 8.2.' . $i . ' - Data Sampling Interval : missing input' . "\n");
      }

     if (
        ( length(trim($pressuresensor{data_sampling_interval}[$i])) > 0 ) &&
        ($pressuresensor{data_sampling_interval}[$i] !~ /^[0-9]{1,}$/ )
        )
      {
         print('Section 8.2.' . $i . ' - Data Sampling Interval : invalid format. Use integer.' . "\n");
      }

     # ACCURACY
     if ( length(trim($pressuresensor{accuracy}[$i])) == 0 )
      {
         #print('Section 8.2.' . $i . ' - Accuracy : missing input' . "\n");
      }

     if (
        ( length(trim($pressuresensor{accuracy}[$i])) > 0 ) &&
        ($pressuresensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($pressuresensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.2.' . $i . ' - Accuracy : invalid format. Use integer or float (may be preceded by "<").' . "\n");
      }

     # HEIGHT DIFF TO ANT
     if ( length(trim($pressuresensor{height_diff_to_ant}[$i])) == 0 )
      {
         print('Section 8.2.' . $i . ' - Height Diff to Ant : missing input' . "\n");
      }

     if (
        ( length(trim($pressuresensor{height_diff_to_ant}[$i])) > 0 ) and
        ($pressuresensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($pressuresensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.2.' . $i . ' - Height Diff to Ant : invalid format. Use integer or float.' . "\n");
      }

     # CALIBRATION DATE
     if ($pressuresensor{calibration_date}[$i] !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
      {
         #print('Section 8.2.' . $i . ' - Calibration date : missing or invalid input' . "\n");
      }
     else
      {

        if (
           (substr($pressuresensor{calibration_date}[$i],0,4) < 1800 ) ||
           (substr($pressuresensor{calibration_date}[$i],0,4) > $year) ||
           !(check_date(substr($pressuresensor{calibration_date}[$i],0,4), substr($pressuresensor{calibration_date}[$i],5,2), substr($pressuresensor{calibration_date}[$i],8,2)))
           )				 
            {
             print('Section 8.2.' . $i . ' - Calibration date : senseless date' . "\n");
            }

      }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES (not for the LAST subsection)
       if (
          (trim($pressuresensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_pressuresensor)
          )
        {
         print('Section 8.2.' . $i . ' - Effective Dates : complete the start and end dates' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($pressuresensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_pressuresensor)
          )
        {
         if (
            (substr($pressuresensor{effective_dates}[$i],0,4) < 1980 ) ||
            (substr($pressuresensor{effective_dates}[$i],0,4) > $year)
            )
           {
            print('Section 8.2.' . $i . ' - Effective Dates (begin) : ' . substr($pressuresensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         if (
            (substr($pressuresensor{effective_dates}[$i],11,4) < 1980 ) ||
            (substr($pressuresensor{effective_dates}[$i],11,4) > $year)
            )
           {
            print('Section 8.2.' . $i . ' - Effective Dates (end) : ' . substr($pressuresensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         $error_effective_dates[$i] = check_stationlogdate(substr($pressuresensor{effective_dates}[$i],0,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.2.' . $i . ' - Effective Dates (begin) : ' . substr($pressuresensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

         $error_effective_dates[$i] = check_stationlogdate(substr($pressuresensor{effective_dates}[$i],11,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.2.' . $i . ' - Effective Dates (end) : ' . substr($pressuresensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

       }

       # EFFECTIVE DATES (ONLY for the LAST subsection)
       if (
          (trim($pressuresensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          (trim($pressuresensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i == $number_pressuresensor)
          )
        {
         print('Section 8.2.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($pressuresensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_pressuresensor)
          )
        {
          if (
             (substr($pressuresensor{effective_dates}[$i],0,4) < 1980 ) ||
             (substr($pressuresensor{effective_dates}[$i],0,4) > $year)
             )
            {
             print('Section 8.2.' . $i . ' - Effective Dates (begin) : ' . substr($pressuresensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($pressuresensor{effective_dates}[$i],0,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.2.' . $i . ' - Effective Dates (begin) : ' . substr($pressuresensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }



       if (
          (trim($pressuresensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i == $number_pressuresensor)
          )
        {
          if (
             (substr($pressuresensor{effective_dates}[$i],11,4) < 1980 ) ||
             (substr($pressuresensor{effective_dates}[$i],11,4) > $year)
             )
            {
             print('Section 8.2.' . $i . ' - Effective Dates (end) : ' . substr($pressuresensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($pressuresensor{effective_dates}[$i],11,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.2.' . $i . ' - Effective Dates (end) : ' . substr($pressuresensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }








       # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
       if (
          ($error_effective_dates[$i] eq '') &&
          ( substr($pressuresensor{effective_dates}[$i],0,10) gt substr($pressuresensor{effective_dates}[$i],11,11) )
          )
         {
           print('Section 8.2.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
         }

       # EFFECTIVE DATES (chronology comparison between Date Installed and ... Date Removed of the previous installation)
       if (
          ($error_effective_dates[$i] eq '') &&
          ($error_effective_dates[($i-1)] eq '') &&
          ( substr($pressuresensor{effective_dates}[$i],0,10) lt substr($pressuresensor{effective_dates}[($i-1)],11,11) )
          )
       {
         print('Section 8.2.' . $i . ' - Effective Dates : the date of installation precede the date of removing of the previous installation (8.2.' . ($i-1) . ')' . "\n");
       }





   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 8.2.x not found.'; }
  

  #######################################################################
  # READ SECTION 8.3
  #######################################################################
  #print (" read 8.3\n");
  $number_temperaturesensor = 0;
  
  while ( ( $line !~ /^8.3.x\s*Temp.\s*Sensor\s*Model\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Temp.\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.3.x\s*/i ) )
          {
            $number_temperaturesensor++;   
            $temperaturesensor{model}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33));

            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Manufacturer\s*/i )               { $temperaturesensor{manufacturer}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Serial\s*Number\s*/i )            { $temperaturesensor{serial_number}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $temperaturesensor{data_sampling_interval}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Accuracy\s*/i )                   { $temperaturesensor{accuracy}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Aspiration\s*/i )                 { $temperaturesensor{aspiration}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $temperaturesensor{height_diff_to_ant}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Calibration\s*date\s*/i )         { $temperaturesensor{calibration_date}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )          { $temperaturesensor{effective_dates}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $temperaturesensor{notes}[$number_temperaturesensor] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $temperaturesensor{notes}[$number_temperaturesensor] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.3.' . $number_temperaturesensor . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.3.' . $number_temperaturesensor . '.'; }
          }  
     }

  for($i=1;$i<=$number_temperaturesensor;$i++)
   {
#      print(" temp $temperaturesensor{model}[$i] $temperaturesensor{manufacturer}[$i] $temperaturesensor{serial_number}[$i] $temperaturesensor{data_sampling_interval}[$i] $temperaturesensor{accuracy}[$i] $temperaturesensor{aspiration}[$i] $temperaturesensor{height_diff_to_ant}[$i] $temperaturesensor{calibration_date}[$i] $temperaturesensor{effective_dates}[$i]\n");
#      print("$temperaturesensor{notes}[$i]\n");

      $temperaturesensor{model}[$i]=~s/\'/&#39;/g;
      $temperaturesensor{model}[$i]=~s/"/&#39;/g;
      $temperaturesensor{manufacturer}[$i] =~s/\'/&#39;/g;
      $temperaturesensor{manufacturer}[$i] =~s/"/&#39;/g;
      $temperaturesensor{data_sampling_interval}[$i] =~s/s$//;
      $temperaturesensor{data_sampling_interval}[$i] =~s/sec$//;
      $temperaturesensor{data_sampling_interval}[$i] =~s/SEC$//;
      $temperaturesensor{data_sampling_interval}[$i] = trim($temperaturesensor{data_sampling_interval}[$i]);
      $temperaturesensor{accuracy}[$i] =~s/^\./0./;
      $temperaturesensor{accuracy}[$i] =~s/\.$//;
      $temperaturesensor{accuracy}[$i] =~s/\(deg C\)$//;
      $temperaturesensor{accuracy}[$i] =~s/deg C$//;
      $temperaturesensor{accuracy}[$i] =~s/deg.C$//;
      $temperaturesensor{accuracy}[$i] =~s/\°C$//;
      $temperaturesensor{accuracy}[$i] =~s/C$//;
      $temperaturesensor{accuracy}[$i] =~s/\+\/\-//;
      $temperaturesensor{accuracy}[$i] = trim($temperaturesensor{accuracy}[$i]);
      $temperaturesensor{height_diff_to_ant}[$i] =~s/m$//;
      $temperaturesensor{height_diff_to_ant}[$i] =~ s/^\+//;
      $temperaturesensor{height_diff_to_ant}[$i] =~s/,/./g;
      $temperaturesensor{height_diff_to_ant}[$i] = trim($temperaturesensor{height_diff_to_ant}[$i]);
      $temperaturesensor{notes}[$i]=~s/\'/&#39;/g;
      $temperaturesensor{notes}[$i]=~s/"/&#39;/g;
      
      if (
         ($temperaturesensor{model}[$i] ne '') or
         ($temperaturesensor{manufacturer}[$i] ne '') or
         ($temperaturesensor{serial_number}[$i] ne '') or
         ($temperaturesensor{data_sampling_interval}[$i] ne '(sec)') or
         ($temperaturesensor{accuracy}[$i] ne '') or        # (deg C)
         ($temperaturesensor{aspiration}[$i] ne '(UNASPIRATED/NATURAL/FAN/etc)') or
         ($temperaturesensor{height_diff_to_ant}[$i] ne '(m)') or
         ($temperaturesensor{calibration_date}[$i] ne '(CCYY-MM-DD)') or
         ($temperaturesensor{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
         ($temperaturesensor{notes}[$i] ne '(multiple lines)')
        )
      {        
      }

     # MODEL
     if ( length(trim($temperaturesensor{model}[$i])) == 0 )
      {
         print('Section 8.3.' . $i . ' - Temperature Sensor Model : missing input' . "\n");
      }

     # MANUFACTURER
     if ( length(trim($temperaturesensor{manufacturer}[$i])) == 0 )
      {
         #print('Section 8.3.' . $i . ' - Manufacturer : missing input' . "\n");
      }

     # SERIAL NUMBER
     if ( length(trim($temperaturesensor{serial_number}[$i])) == 0 )
      {
         #print('Section 8.3.' . $i . ' - Serial Number : missing input' . "\n");
      }

     # DATA SAMPLING INTERVAL
     if ( length(trim($temperaturesensor{data_sampling_interval}[$i])) == 0 )
      {
         #print('Section 8.3.' . $i . ' - Data Sampling Interval : missing input' . "\n");
      }

     if (
        ( length(trim($temperaturesensor{data_sampling_interval}[$i])) > 0 ) &&
        ($temperaturesensor{data_sampling_interval}[$i] !~ /^[0-9]{1,}$/ )
        )
      {
         print('Section 8.3.' . $i . ' - Data Sampling Interval : invalid format. Use integer.' . "\n");
      }

     # ACCURACY
     if ( length(trim($temperaturesensor{accuracy}[$i])) == 0 )
      {
         #print('Section 8.3.' . $i . ' - Accuracy : missing input' . "\n");
      }

     if (
        ( length(trim($temperaturesensor{accuracy}[$i])) > 0 ) &&
        ($temperaturesensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($temperaturesensor{accuracy}[$i] !~ /^<{0,1}\s{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.3.' . $i . ' - Accuracy : invalid format. Use integer or float (may be preceded by "<").' . "\n");
      }

     # ASPIRATION
     if (
        (length(trim($temperaturesensor{aspiration}[$i])) == 0 ) ||
        (trim($temperaturesensor{aspiration}[$i]) eq '(UNASPIRATED/NATURAL/FAN/etc)')
        )
      {
         #print('Section 8.3.' . $i . ' - Aspiration : missing input' . "\n");
      }

     # HEIGHT DIFF TO ANT
     if ( length(trim($temperaturesensor{height_diff_to_ant}[$i])) == 0 )
      {
         print('Section 8.3.' . $i . ' - Height Diff to Ant : missing input' . "\n");
      }

     if (
        ( length(trim($temperaturesensor{height_diff_to_ant}[$i])) > 0 ) and
        ($temperaturesensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($temperaturesensor{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.3.' . $i . ' - Height Diff to Ant : invalid format. Use integer or float.' . "\n");
      }

     # CALIBRATION DATE
     if ($temperaturesensor{calibration_date}[$i] !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
      {
         #print('Section 8.3.' . $i . ' - Calibration date : missing or invalid input' . "\n");
      }
     else
      {

        if (
           (substr($temperaturesensor{calibration_date}[$i],0,4) < 1800 ) ||
           (substr($temperaturesensor{calibration_date}[$i],0,4) > $year) ||
           !(check_date(substr($temperaturesensor{calibration_date}[$i],0,4), substr($temperaturesensor{calibration_date}[$i],5,2), substr($temperaturesensor{calibration_date}[$i],8,2)))
           )				 
            {
             print('Section 8.3.' . $i . ' - Calibration date : senseless date' . "\n");
            }

      }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES (not for the LAST subsection)
       if (
          (trim($temperaturesensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_temperaturesensor)
          )
        {
         print('Section 8.3.' . $i . ' - Effective Dates : complete the start and end dates' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($temperaturesensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_temperaturesensor)
          )
        {
         if (
            (substr($temperaturesensor{effective_dates}[$i],0,4) < 1980 ) ||
            (substr($temperaturesensor{effective_dates}[$i],0,4) > $year)
            )
           {
            print('Section 8.3.' . $i . ' - Effective Dates (begin) : ' . substr($temperaturesensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         if (
            (substr($temperaturesensor{effective_dates}[$i],11,4) < 1980 ) ||
            (substr($temperaturesensor{effective_dates}[$i],11,4) > $year)
            )
           {
            print('Section 8.3.' . $i . ' - Effective Dates (end) : ' . substr($temperaturesensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         $error_effective_dates[$i] = check_stationlogdate(substr($temperaturesensor{effective_dates}[$i],0,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.3.' . $i . ' - Effective Dates (begin) : ' . substr($temperaturesensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

         $error_effective_dates[$i] = check_stationlogdate(substr($temperaturesensor{effective_dates}[$i],11,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.3.' . $i . ' - Effective Dates (end) : ' . substr($temperaturesensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

       }

       # EFFECTIVE DATES (ONLY for the LAST subsection)
       if (
          (trim($temperaturesensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($temperaturesensor{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_temperaturesensor)
          )
        {
         print('Section 8.3.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($temperaturesensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_temperaturesensor)
          )
        {
          if (
             (substr($temperaturesensor{effective_dates}[$i],0,4) < 1980 ) ||
             (substr($temperaturesensor{effective_dates}[$i],0,4) > $year)
             )
            {
             print('Section 8.3.' . $i . ' - Effective Dates (begin) : ' . substr($temperaturesensor{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($temperaturesensor{effective_dates}[$i],0,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.3.' . $i . ' - Effective Dates (begin) : ' . substr($temperaturesensor{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }


       if (
          (trim($temperaturesensor{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i == $number_temperaturesensor)
          )
        {
          if (
             (substr($temperaturesensor{effective_dates}[$i],11,4) < 1980 ) ||
             (substr($temperaturesensor{effective_dates}[$i],11,4) > $year)
             )
            {
             print('Section 8.3.' . $i . ' - Effective Dates (end) : ' . substr($temperaturesensor{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($temperaturesensor{effective_dates}[$i],11,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.3.' . $i . ' - Effective Dates (end) : ' . substr($temperaturesensor{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }





       # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
       if (
          ($error_effective_dates[$i] eq '') &&
          ( substr($temperaturesensor{effective_dates}[$i],0,10) gt substr($temperaturesensor{effective_dates}[$i],11,11) )
          )
         {
           print('Section 8.3.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
         }

       # EFFECTIVE DATES (chronology comparison between Date Installed and ... Date Removed of the previous installation)
       if (
          ($error_effective_dates[$i] eq '') &&
          ($error_effective_dates[($i-1)] eq '') &&
          ( substr($temperaturesensor{effective_dates}[$i],0,10) lt substr($temperaturesensor{effective_dates}[($i-1)],11,11) )
          )
       {
         print('Section 8.3.' . $i . ' - Effective Dates : the date of installation precede the date of removing of the previous installation (8.3.' . ($i-1) . ')' . "\n");
       }


   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 8.3.x not found.'; }





  #######################################################################
  # READ SECTION 8.4
  #######################################################################
  #print (" read 8.4\n");
  $number_watervaporradiometer = 0;
  
  while ( ( $line !~ /^8.4.x\s*Water\s*Vapor\s*Radiometer\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Water\s*Vapor\s*Radiometer\s*/i ) && ($line !~ /\s*8.4.x\s*/i ) )
          {
            $number_watervaporradiometer++;
            $watervaporradiometer{model}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Manufacturer\s*/i )               { $watervaporradiometer{manufacturer}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Serial\s*Number\s*/i )            { $watervaporradiometer{serial_number}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Distance\s*to\s*Antenna\s*/i )    { $watervaporradiometer{distance_to_antenna}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $watervaporradiometer{height_diff_to_ant}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Calibration\s*date\s*/i )         { $watervaporradiometer{calibration_date}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )          { $watervaporradiometer{effective_dates}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33)); } 
                 if (substr($line,0,32) =~ /\s*Notes\s*/i )
                 {
                  $watervaporradiometer{notes}[$number_watervaporradiometer] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $watervaporradiometer{notes}[$number_watervaporradiometer] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.4.' . $number_watervaporradiometer . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.4.' . $number_watervaporradiometer . '.'; }
          }  
     }

  for($i=1;$i<=$number_watervaporradiometer;$i++)
   {
#      print("$watervaporradiometer{model}[$i] $watervaporradiometer{manufacturer}[$i] $watervaporradiometer{serial_number}[$i] $watervaporradiometer{distance_to_antenna}[$i] $watervaporradiometer{height_diff_to_ant}[$i] $watervaporradiometer{calibration_date}[$i] $watervaporradiometer{effective_dates}[$i]\n");
#      print("$watervaporradiometer{notes}[$i]\n");

      $watervaporradiometer{model}[$i] =~s/\'/&#39;/g;
      $watervaporradiometer{model}[$i] =~s/"/&#39;/g;
      $watervaporradiometer{manufacturer}[$i] =~s/\'/&#39;/g;
      $watervaporradiometer{manufacturer}[$i] =~s/"/&#39;/g;
      $watervaporradiometer{height_diff_to_ant}[$i] =~s/m$//;
      $watervaporradiometer{height_diff_to_ant}[$i] =~s/,/./g;
      $watervaporradiometer{height_diff_to_ant}[$i] =~s/^\+//;
      $watervaporradiometer{height_diff_to_ant}[$i] = trim($watervaporradiometer{height_diff_to_ant}[$i]);
      $watervaporradiometer{distance_to_antenna}[$i] =~s/m$//;
      $watervaporradiometer{distance_to_antenna}[$i] =~s/,/./g;
      $watervaporradiometer{distance_to_antenna}[$i] =~s/^\+//;
      $watervaporradiometer{distance_to_antenna}[$i] = trim($watervaporradiometer{distance_to_antenna}[$i]);
      $watervaporradiometer{notes}[$i] =~s/\'/&#39;/g;
      $watervaporradiometer{notes}[$i] =~s/"/&#39;/g;

      if(
        ($watervaporradiometer{model}[$i] ne '') or
        ($watervaporradiometer{manufacturer}[$i] ne '') or
        ($watervaporradiometer{serial_number}[$i] ne '') or
        ($watervaporradiometer{distance_to_antenna}[$i] ne '(m)') or
        ($watervaporradiometer{height_diff_to_ant}[$i] ne '(m)') or
        ($watervaporradiometer{calibration_date}[$i] ne '(CCYY-MM-DD)') or
        ($watervaporradiometer{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
        ($watervaporradiometer{notes}[$i] ne '(multiple lines)')
        )
      {        
      }      






     # WATER VAPOR RADIOMETER - MODEL
     if ( length(trim($watervaporradiometer{model}[$i])) == 0 )
      {
         print('Section 8.4.' . $i . ' - Water Vapor Radiometer : missing input' . "\n");
      }

     # MANUFACTURER
     if ( length(trim($watervaporradiometer{manufacturer}[$i])) == 0 )
      {
         #print('Section 8.4.' . $i . ' - Manufacturer : missing input' . "\n");
      }

     # SERIAL NUMBER
     if ( length(trim($watervaporradiometer{serial_number}[$i])) == 0 )
      {
         #print('Section 8.4.' . $i . ' - Serial Number : missing input' . "\n");
      }

     # DISTANCE TO ANTENNA
     if ( length(trim($watervaporradiometer{distance_to_antenna}[$i])) == 0 )
      {
         print('Section 8.4.' . $i . ' - Distance to Antenna : missing input' . "\n");
      }

     if (
        ( length(trim($watervaporradiometer{distance_to_antenna}[$i])) > 0 ) and
        ($watervaporradiometer{distance_to_antenna}[$i] !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($watervaporradiometer{distance_to_antenna}[$i] !~ /^[-]{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.4.' . $i . ' - Distance to Antenna : invalid format. Use integer or float.' . "\n");
      }

     # HEIGHT DIFF TO ANT
     if ( length(trim($watervaporradiometer{height_diff_to_ant}[$i])) == 0 )
      {
         print('Section 8.4.' . $i . ' - Height Diff to Ant : missing input' . "\n");
      }

     if (
        ( length(trim($watervaporradiometer{height_diff_to_ant}[$i])) > 0 ) and
        ($watervaporradiometer{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}\.[0-9]{1,}$/ ) &&
        ($watervaporradiometer{height_diff_to_ant}[$i] !~ /^[-]{0,1}[0-9]{1,}$/ )
        )
      {
         print('Section 8.4.' . $i . ' - Height Diff to Ant : invalid format. Use integer or float.' . "\n");
      }

     # CALIBRATION DATE
     if ($watervaporradiometer{calibration_date}[$i] !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
      {
         #print('Section 8.4.' . $i . ' - Calibration date : missing or invalid input' . "\n");
      }
     else
      {

        if (
           (substr($watervaporradiometer{calibration_date}[$i],0,4) < 1800 ) ||
           (substr($watervaporradiometer{calibration_date}[$i],0,4) > $year) ||
           !(check_date(substr($watervaporradiometer{calibration_date}[$i],0,4), substr($watervaporradiometer{calibration_date}[$i],5,2), substr($watervaporradiometer{calibration_date}[$i],8,2)))
           )				 
            {
             print('Section 8.4.' . $i . ' - Calibration date : senseless date' . "\n");
            }

      }

       $error_effective_dates[$i] = '';


       # EFFECTIVE DATES (not for the LAST subsection)
       if (
          (trim($watervaporradiometer{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_watervaporradiometer)
          )
        {
         print('Section 8.4.' . $i . ' - Effective Dates : complete the start and end dates' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($watervaporradiometer{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          ($i < $number_watervaporradiometer)
          )
        {
         if (
            (substr($watervaporradiometer{effective_dates}[$i],0,4) < 1980 ) ||
            (substr($watervaporradiometer{effective_dates}[$i],0,4) > $year)
            )
           {
            print('Section 8.4.' . $i . ' - Effective Dates (begin) : ' . substr($watervaporradiometer{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         if (
            (substr($watervaporradiometer{effective_dates}[$i],11,4) < 1980 ) ||
            (substr($watervaporradiometer{effective_dates}[$i],11,4) > $year)
            )
           {
            print('Section 8.4.' . $i . ' - Effective Dates (end) : ' . substr($watervaporradiometer{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
            $error_effective_dates[$i] = 'true';
           }

         $error_effective_dates[$i] = check_stationlogdate(substr($watervaporradiometer{effective_dates}[$i],0,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.4.' . $i . ' - Effective Dates (begin) : ' . substr($watervaporradiometer{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

         $error_effective_dates[$i] = check_stationlogdate(substr($watervaporradiometer{effective_dates}[$i],11,10));
         if($error_effective_dates[$i] ne '')
          {
            print('Section 8.4.' . $i . ' - Effective Dates (end) : ' . substr($watervaporradiometer{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
          }

       }

       # EFFECTIVE DATES (ONLY for the LAST subsection)
       if (
          (trim($watervaporradiometer{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_watervaporradiometer)
          )
        {
         print('Section 8.4.' . $i . ' - Effective Dates : complete only the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }

       if (
          (trim($watervaporradiometer{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ ) &&
          ($i == $number_watervaporradiometer)
          )
        {
          if (
             (substr($watervaporradiometer{effective_dates}[$i],0,4) < 1980 ) ||
             (substr($watervaporradiometer{effective_dates}[$i],0,4) > $year)
             )
            {
             print('Section 8.4.' . $i . ' - Effective Dates (begin) : ' . substr($watervaporradiometer{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
             $error_effective_dates[$i] = 'true';
            }


          $error_effective_dates[$i] = check_stationlogdate(substr($watervaporradiometer{effective_dates}[$i],0,10));
          if($error_effective_dates[$i] ne '')
           {
             print('Section 8.4.' . $i . ' - Effective Dates (begin) : ' . substr($watervaporradiometer{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
           }
       }
	
       # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
       if (
          ($error_effective_dates[$i] eq '') &&
          ( substr($watervaporradiometer{effective_dates}[$i],0,10) gt substr($watervaporradiometer{effective_dates}[$i],11,11) )
          )
         {
           print('Section 8.4.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
         }

       # EFFECTIVE DATES (chronology comparison between Date Installed and ... Date Removed of the previous installation)
       if (
          ($error_effective_dates[$i] eq '') &&
          ($error_effective_dates[($i-1)] eq '') &&
          ( substr($watervaporradiometer{effective_dates}[$i],0,10) lt substr($watervaporradiometer{effective_dates}[($i-1)],11,11) )
          )
       {
         print('Section 8.4.' . $i . ' - Effective Dates : the date of installation precede the date of removing of the previous installation (8.4.' . ($i-1) . ')' . "\n");
       }



   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 8.4.x not found.'; }



  #######################################################################
  # READ SECTION 8.5
  #######################################################################
  #print (" read 8.5\n");
  $number_otherinstrumentation = 0;
  
  while ( ( $line !~ /^9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Other\s*Instrumentation\s*/i ) && ($line !~ /\s*8.5.x\s*/i ) )
          {
            $number_otherinstrumentation++;   
            $otherinstrumentation[$number_otherinstrumentation] = trim(substr($line,32,length($line)-33));
            $line = <LogFile>;
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $otherinstrumentation[$number_otherinstrumentation] .= "\n" . trim(substr($line,32,length($line)-33));
                 $line = <LogFile>;
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 8.5.' . $number_otherinstrumentation . '.'; }
          } 
     }
      
  for($i=1;$i<=$number_otherinstrumentation;$i++)
   {
#      print("$otherinstrumentation[$i]\n");

     $otherinstrumentation[$i] =~s/\'/&#39;/g;
     $otherinstrumentation[$i] =~s/"/&#39;/g;

     if ($otherinstrumentation[$i] ne '(multiple lines)')
     {               
     }

     # OTHER INSTRUMENTATION
     if ( length(trim($otherinstrumentation[$i])) == 0 )
      {
         print('Section 8.5.' . $i . ' - Other Instrumentation : missing input' . "\n");
      }


   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 9 not found.'; }



  #######################################################################
  # READ SECTION 9.1
  #######################################################################
  #print (" read 9.1\n");
  $number_radiointerferences = 0;
  
  while ( ( $line !~ /^9.1.x\s*Radio\s*Interferences\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Radio\s*Interferences\s*/i ) && ($line !~ /\s*9.1.x\s*/i ) )
          {
            $number_radiointerferences++;
            $radiointerferences{radiointerferences}[$number_radiointerferences] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;
                 if ( (substr($line,0,32) =~ /\s*Observed\s*Degradations\s*/i ) || (substr($line,0,32) =~ /\s*Observed\s*Degredations\s*/i ) ) { $radiointerferences{observed_degradations}[$number_radiointerferences] = trim(substr($line,32,length($line)-33)); }
                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )       { $radiointerferences{effective_dates}[$number_radiointerferences] = trim(substr($line,32,length($line)-33)); }
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $radiointerferences{additional_information}[$number_radiointerferences] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $radiointerferences{additional_information}[$number_radiointerferences] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.1.' . $number_radiointerferences . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.1.' . $number_radiointerferences . '.'; }
          }  
     }
      
  for($i=1;$i<=$number_radiointerferences;$i++)
   {
#      print("$radiointerferences{radiointerferences}[$i] $radiointerferences{observed_degradations}[$i] $radiointerferences{effective_dates}[$i]\n");
#      print("$radiointerferences{additional_information}[$i]\n");

     $radiointerferences{additional_information}[$i] =~s/\'/&#39;/g;
     $radiointerferences{additional_information}[$i] =~s/"/&#39;/g;

     if (
         ($radiointerferences{radiointerferences}[$i] ne '(TV/CELL PHONE ANTENNA/RADAR/etc)') or
         ($radiointerferences{observed_degradations}[$i] ne '(SN RATIO/DATA GAPS/etc)') or
         ($radiointerferences{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
         ($radiointerferences{additional_information}[$i] ne '(multiple lines)')
        )
     {             
     }

     # RADIO INTERFERENCES - ORIGIN
     if ( ( length(trim($radiointerferences{radiointerferences}[$i])) == 0 ) || (trim($radiointerferences{radiointerferences}[$i]) eq '(TV/CELL PHONE ANTENNA/RADAR/etc)' ) )
      {
         print('Section 9.1.' . $i . ' - Radio Interferences : missing input' . "\n");
      }

     # OBSERVED DEGRADATIONS
     if ( ( length(trim($radiointerferences{observed_degradations}[$i])) == 0 ) || (trim($radiointerferences{observed_degradations}[$i]) eq '(TV/CELL PHONE ANTENNA/RADAR/etc)' ) )
      {
         print('Section 9.1.' . $i . ' - Observed Degradations : missing input' . "\n");
      }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES
       if (
          (trim($radiointerferences{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($radiointerferences{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          )
        {
         print('Section 9.1.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }
       else
        {

          if (trim($radiointerferences{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
           {
            if (
               (substr($radiointerferences{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($radiointerferences{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.1.' . $i . ' - Effective Dates (begin) : ' . substr($radiointerferences{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

           if (
              (substr($radiointerferences{effective_dates}[$i],11,4) < 1980 ) ||
              (substr($radiointerferences{effective_dates}[$i],11,4) > $year)
              )
             {
              print('Section 9.1.' . $i . ' - Effective Dates (end) : ' . substr($radiointerferences{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
              $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($radiointerferences{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.1.' . $i . ' - Effective Dates (begin) : ' . substr($radiointerferences{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($radiointerferences{effective_dates}[$i],11,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.1.' . $i . ' - Effective Dates (end) : ' . substr($radiointerferences{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }


            # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
            if (
               ($error_effective_dates[$i] eq '') &&
               ( substr($radiointerferences{effective_dates}[$i],0,10) gt substr($radiointerferences{effective_dates}[$i],11,11) )
               )
             {
              print('Section 9.1.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
             }



           }


         if (trim($radiointerferences{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          {
            if (
               (substr($radiointerferences{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($radiointerferences{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.1.' . $i . ' - Effective Dates (begin) : ' . substr($radiointerferences{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($radiointerferences{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.1.' . $i . ' - Effective Dates (begin) : ' . substr($radiointerferences{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

          }


      }



   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 9.1.x not found.'; }


  #######################################################################
  # READ SECTION 9.2
  #######################################################################
  #print (" read 9.2\n");
  $number_multipathsources = 0;
  
  while ( ( $line !~ /^9.2.x\s*Multipath\s*Sources\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Multipath\s*Sources\s*/i ) && ($line !~ /\s*9.2.x\s*/i ) )
          {
            $number_multipathsources++;
            $multipathsources{multipathsources}[$number_multipathsources] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )        { $multipathsources{effective_dates}[$number_multipathsources] = trim(substr($line,32,length($line)-33)); }
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $multipathsources{additional_information}[$number_multipathsources] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $multipathsources{additional_information}[$number_multipathsources] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.2.' . $number_multipathsources . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.2.' . $number_multipathsources . '.'; }
          }  
     }

  for($i=1;$i<=$number_multipathsources;$i++)
   {
#      print("$multipathsources{multipathsources}[$i] $multipathsources{effective_dates}[$i]\n");
#      print("$multipathsources{additional_information}[$i]\n");

     $multipathsources{additional_information}[$i] =~s/\'/&#39;/g;
     $multipathsources{additional_information}[$i] =~s/"/&#39;/g;

     if (
         ($multipathsources{multipathsources}[$i] ne '(METAL ROOF/DOME/VLBI ANTENNA/etc)') or
         ($multipathsources{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
         ($multipathsources{additional_information}[$i] ne '(multiple lines)')
         )
      {              
      }


     # MULTIPATH SOURCES - ORIGIN
     if ( ( length(trim($multipathsources{multipathsources}[$i])) == 0 ) || (trim($multipathsources{multipathsources}[$i]) eq '(METAL ROOF/DOME/VLBI ANTENNA/etc)' ) )
      {
         print('Section 9.2.' . $i . ' - Multipath Sources : missing input' . "\n");
      }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES
       if (
          (trim($multipathsources{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($multipathsources{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          )
        {
         print('Section 9.2.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }
       else
        {

          if (trim($multipathsources{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
           {
            if (
               (substr($multipathsources{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($multipathsources{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.2.' . $i . ' - Effective Dates (begin) : ' . substr($multipathsources{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

           if (
              (substr($multipathsources{effective_dates}[$i],11,4) < 1980 ) ||
              (substr($multipathsources{effective_dates}[$i],11,4) > $year)
              )
             {
              print('Section 9.2.' . $i . ' - Effective Dates (end) : ' . substr($multipathsources{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
              $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($multipathsources{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.2.' . $i . ' - Effective Dates (begin) : ' . substr($multipathsources{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($multipathsources{effective_dates}[$i],11,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.2.' . $i . ' - Effective Dates (end) : ' . substr($multipathsources{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }


            # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
            if (
               ($error_effective_dates[$i] eq '') &&
               ( substr($multipathsources{effective_dates}[$i],0,10) gt substr($multipathsources{effective_dates}[$i],11,11) )
               )
             {
              print('Section 9.2.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
             }



           }


         if (trim($multipathsources{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          {
            if (
               (substr($multipathsources{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($multipathsources{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.2.' . $i . ' - Effective Dates (begin) : ' . substr($multipathsources{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($multipathsources{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.2.' . $i . ' - Effective Dates (begin) : ' . substr($multipathsources{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

          }


      }









   }

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 9.2.x not found.'; }


  #######################################################################
  # READ SECTION 9.3
  #######################################################################
  #print (" read 9.3\n");
  $number_signalobstructions = 0;
  #while ( ( $line !~ /^9.3.x\s*Signal\s*Obstructions\s*/i ) && (!eof(LogFile)) )
  while ( ( $line !~ /^10.\s*Local\s*Episodic\s*Effects\s*Possibly\s*Affecting\s*Data\s*Quality\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Signal\s*Obstructions\s*/i ) && ($line !~ /\s*9.3.x\s*/i ) )
          {
            $number_signalobstructions++;
            $signalobstructions{signalobstructions}[$number_signalobstructions] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 if (substr($line,0,32) =~ /\s*Effective\s*Dates\s*/i )        { $signalobstructions{effective_dates}[$number_signalobstructions] = trim(substr($line,32,length($line)-33)); }
                 if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
                 {
                  $signalobstructions{additional_information}[$number_signalobstructions] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $signalobstructions{additional_information}[$number_signalobstructions] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.3.' . $number_signalobstructions . '.'; }
                 } 
              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 9.3.' . $number_signalobstructions . '.'; }
          }  
     }
      
  for($i=1;$i<=$number_signalobstructions;$i++)
   {
  #    print("$signalobstructions{signalobstructions}[$i] $signalobstructions{effective_dates}[$i]\n");
  #    print("$signalobstructions{additional_information}[$i]\n");

      $signalobstructions{additional_information}[$i] =~s/\'/&#39;/g;
      $signalobstructions{additional_information}[$i] =~s/"/&#39;/g;

      if (
         ($signalobstructions{signalobstructions}[$i] ne '(TREES/BUILDLINGS/etc)') or
         ($signalobstructions{effective_dates}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
         ($signalobstructions{additional_information}[$i] ne '(multiple lines)')
         )
      {               
      }

     # SIGNAL OBSTRUCTIONS - ORIGIN
     if ( ( length(trim($signalobstructions{signalobstructions}[$i])) == 0 ) || (trim($signalobstructions{signalobstructions}[$i]) eq '(TREES/BUILDLINGS/etc)' ) )
      {
         print('Section 9.3.' . $i . ' - Signal Obstructions : missing input' . "\n");
      }


       $error_effective_dates[$i] = '';

       # EFFECTIVE DATES
       if (
          (trim($signalobstructions{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($signalobstructions{effective_dates}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          )
        {
         print('Section 9.3.' . $i . ' - Effective Dates : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }
       else
        {

          if (trim($signalobstructions{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
           {
            if (
               (substr($signalobstructions{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($signalobstructions{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.3.' . $i . ' - Effective Dates (begin) : ' . substr($signalobstructions{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

           if (
              (substr($signalobstructions{effective_dates}[$i],11,4) < 1980 ) ||
              (substr($signalobstructions{effective_dates}[$i],11,4) > $year)
              )
             {
              print('Section 9.3.' . $i . ' - Effective Dates (end) : ' . substr($signalobstructions{effective_dates}[$i],11,4) . ' is a senseless year' . "\n");
              $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($signalobstructions{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.3.' . $i . ' - Effective Dates (begin) : ' . substr($signalobstructions{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($signalobstructions{effective_dates}[$i],11,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.3.' . $i . ' - Effective Dates (end) : ' . substr($signalobstructions{effective_dates}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }


            # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
            if (
               ($error_effective_dates[$i] eq '') &&
               ( substr($signalobstructions{effective_dates}[$i],0,10) gt substr($signalobstructions{effective_dates}[$i],11,11) )
               )
             {
              print('Section 9.3.' . $i . ' - Effective Dates : the date of removing precede the date of installation' . "\n");
             }



           }


         if (trim($signalobstructions{effective_dates}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          {
            if (
               (substr($signalobstructions{effective_dates}[$i],0,4) < 1980 ) ||
               (substr($signalobstructions{effective_dates}[$i],0,4) > $year)
               )
             {
               print('Section 9.3.' . $i . ' - Effective Dates (begin) : ' . substr($signalobstructions{effective_dates}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($signalobstructions{effective_dates}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 9.3.' . $i . ' - Effective Dates (begin) : ' . substr($signalobstructions{effective_dates}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

          }


      }




   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 10 not found.'; }



  #######################################################################
  # READ SECTION 10.
  #######################################################################
#  print (" read 10\n");
  $number_localepisodiceffects = 0;
  
  while ( ( $line !~ /^11.\s*On-Site,\s*Point\s*of\s*Contact\s*Agency\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if ( (substr($line,0,32) =~ /\s*Date\s*/i ) && ($line !~ /\s*10.x\s*/i ) )
          {
            $number_localepisodiceffects++;
            $localepisodiceffects{date}[$number_localepisodiceffects] = trim(substr($line,32,length($line)-33));
            while ( (trim($line) ne "") && (!eof(LogFile)) )
              {
                 $line = <LogFile>;

                 #if (substr($line,0,32) =~ /\s*Event\s*/i )            { $localepisodiceffects{event}[$number_localepisodiceffects] = trim(substr($line,32,length($line)-33)); } 

                 if (substr($line,0,32) =~ /\s*Event\s*/i )
                 {
                  $localepisodiceffects{event}[$number_localepisodiceffects] = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $localepisodiceffects{event}[$number_localepisodiceffects] .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 10.' . $number_localepisodiceffects . '.'; }
                 } 

              }
            if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line after subsection No 10.' . $number_localepisodiceffects . '.'; }
          }  
     }

      
  for($i=1;$i<=$number_localepisodiceffects;$i++)
   {
#      print("$localepisodiceffects{date}[$i] $localepisodiceffects{event}[$i]\n");

      $localepisodiceffects{event}[$i] =~s/\'/&#39;/g;
      $localepisodiceffects{event}[$i] =~s/"/&#39;/g;

      if (
          ($localepisodiceffects{date}[$i] ne '(CCYY-MM-DD/CCYY-MM-DD)') or
          ($localepisodiceffects{event}[$i] ne '(TREE CLEARING/CONSTRUCTION/etc)')
         )
      {
      }


       $error_effective_dates[$i] = '';

       # DATE
       if (
          (trim($localepisodiceffects{date}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ ) &&
          (trim($localepisodiceffects{date}[$i]) !~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          )
        {
         print('Section 10.' . $i . ' - Date : complete at least the start date' . "\n");
         $error_effective_dates[$i] = 'true';
        }
       else
        {

          if (trim($localepisodiceffects{date}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}$/ )
           {
            if (
               (substr($localepisodiceffects{date}[$i],0,4) < 1980 ) ||
               (substr($localepisodiceffects{date}[$i],0,4) > $year)
               )
             {
               print('Section 10.' . $i . ' - Date (begin) : ' . substr($localepisodiceffects{date}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

           if (
              (substr($localepisodiceffects{date}[$i],11,4) < 1980 ) ||
              (substr($localepisodiceffects{date}[$i],11,4) > $year)
              )
             {
              print('Section 10.' . $i . ' - Date (end) : ' . substr($localepisodiceffects{date}[$i],11,4) . ' is a senseless year' . "\n");
              $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($localepisodiceffects{date}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 10.' . $i . ' - Date (begin) : ' . substr($localepisodiceffects{date}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($localepisodiceffects{date}[$i],11,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 10.' . $i . ' - Date (end) : ' . substr($localepisodiceffects{date}[$i],11,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }


            # EFFECTIVE DATES (chronology comparison between Date Installed and Date Removed)
            if (
               ($error_effective_dates[$i] eq '') &&
               ( substr($localepisodiceffects{date}[$i],0,10) gt substr($localepisodiceffects{date}[$i],11,11) )
               )
             {
              print('Section 10.' . $i . ' - Date : the date of removing precede the date of installation' . "\n");
             }



           }


         if (trim($localepisodiceffects{date}[$i]) =~ /^[0-9]{4}[-]{1}[0-9]{2}[-]{1}[0-9]{2}[\/]{1}CCYY-MM-DD$/ )
          {
            if (
               (substr($localepisodiceffects{date}[$i],0,4) < 1980 ) ||
               (substr($localepisodiceffects{date}[$i],0,4) > $year)
               )
             {
               print('Section 10.' . $i . ' - Date (begin) : ' . substr($localepisodiceffects{date}[$i],0,4) . ' is a senseless year' . "\n");
               $error_effective_dates[$i] = 'true';
             }

            $error_effective_dates[$i] = check_stationlogdate(substr($localepisodiceffects{date}[$i],0,10));
            if($error_effective_dates[$i] ne '')
             {
               print('Section 10.' . $i . ' - Date (begin) : ' . substr($localepisodiceffects{date}[$i],0,10) . ' -> ' . $error_effective_dates[$i] . "\n");
             }

          }


      }




     # EVENT
     if ( ( length(trim($localepisodiceffects{event}[$i])) == 0 ) || (trim($localepisodiceffects{event}[$i]) eq '(TREE CLEARING/CONSTRUCTION/etc)' ) )
      {
         print('Section 10.' . $i . ' - Event : missing input' . "\n");
      }


   }   

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 11 not found.'; }



  #######################################################################
  # READ SECTION 11.
  #######################################################################
  #print (" read 11\n");
  $line = <LogFile>;
  while ( ( $line !~ /^12.\s*Responsible\s*Agency\s*/i ) && (!eof(LogFile)) )
     {
       $tmp = substr($line,30,length($line)-31);
       if (substr($line,0,32) =~ /\s*Agency\s*/i )
              {
                  $agency_section11 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Preferred\s*Abbreviation\s*/i ) && (!eof(LogFile)) && (trim($line) ne "") )
                    {
                      if (length($line) >  32) { $agency_section11 .= "\n" . trim(substr($line,32,length($line)-33)); }
                      $line = <LogFile>;
                    }
                  if ( ( (eof(LogFile)) || (trim($line) eq "") ) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Preferred Abbreviation" not found in section No 11.'; }
              } 
       if (substr($line,0,32) =~ /\s*Preferred\s*Abbreviation\s*/i )    { $preferredabbreviation_section11 = trim(substr($line,32,length($line)-33));  }
       if ((substr($line,0,32) =~ /\s*Mailing\s*Address\s*/i ) && ($tmp !~ /\s*Mailing\s*Address\s*/i ) )
              {
                  $mailing_address_section11 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Primary\s*Contact\s*/i ) && (!eof(LogFile)) && (trim($line) ne "") )
                    {
                      if (length($line) >  32) { $mailing_address_section11 .= "\n" . trim(substr($line,32,length($line)-33)); }
                      $line = <LogFile>;
                    }
                  if ( ( (eof(LogFile)) || (trim($line) eq "") ) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Primary Contact" not found in section No 11.'; }
              } 
              
       if ((substr($line,0,32) =~ /\s*Primary\s*Contact\s*/i ) && ($tmp !~ /\s*Primary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Secondary\s*Contact\s*/i ) && (!eof(LogFile)) )
                    {

                      if (substr($line,0,32) =~ /\s*Contact\s*Name\s*/i )
                        {
                           $primarycontact_contactname_section11 = trim(substr($line,32,length($line)-33));
                        }   
                           
                      if (substr($line,0,32) =~ /\s*Telephone\s*\(primary\)\s*/i )
                        {
                           $primarycontact_primarytelephone_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        {
                           $primarycontact_secondarytelephone_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Fax\s*/i )
                        {
                           $primarycontact_fax_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*E-mail\s*/i )
                        {
                           $primarycontact_email_section11 = trim(substr($line,32,length($line)-33));
                        }   
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Secondary Contact" not found in section No 11.'; }

              } 
       if ((substr($line,0,32) =~ /\s*Secondary\s*Contact\s*/i ) && ($tmp !~ /\s*Secondary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Additional\s*Information\s*/i ) && (!eof(LogFile)) )
                    {

                      if (substr($line,0,32) =~ /\s*Contact\s*Name\s*/i )
                        {
                           $secondarycontact_contactname_section11 = trim(substr($line,32,length($line)-33));
                        }   
                           
                      if (substr($line,0,32) =~ /\s*Telephone\s*\(primary\)\s*/i )
                        {
                           $secondarycontact_primarytelephone_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        {
                           $secondarycontact_secondarytelephone_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Fax\s*/i )
                        {
                           $secondarycontact_fax_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*E-mail\s*/i )
                        {
                           $secondarycontact_email_section11 = trim(substr($line,32,length($line)-33));
                        }   

                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Additional Information" not found in section No 11.'; }

              } 

       if (substr($line,0,32) =~ /\s*Additional\s*Information\s*/i )
         {
                  $additional_information_section11 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $additional_information_section11 .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line between sections No 11 and No 12.'; }
         } 
       $line = <LogFile>;
       #if (trim($line) ne '') { print "$line\n"; }
     }
   $agency_section11 =~s/\'/&#39;/g;
   $agency_section11 =~s/"/&#39;/g;
   $mailing_address_section11 =~s/\'/&#39;/g;
   $mailing_address_section11 =~s/"/&#39;/g;
   $additional_information_section11 =~s/\'/&#39;/g;
   $additional_information_section11 =~s/"/&#39;/g;

#  print "$agency_section11\n";
#  print "$preferredabbreviation_section11\n";
#  print "$mailing_address_section11\n";

#  print "primarycontact_contactname        : $primarycontact_contactname_section11\n";
#  print "primarycontact_primarytelephone   : $primarycontact_primarytelephone_section11\n";
#  print "primarycontact_secondarytelephone : $primarycontact_secondarytelephone_section11\n";
#  print "primarycontact_fax                : $primarycontact_fax_section11\n";
#  print "primarycontact_email              : $primarycontact_email_section11\n";

#  print "secondarycontact_contactname        : $secondarycontact_contactname_section11\n";
#  print "secondarycontact_primarytelephone   : $secondarycontact_primarytelephone_section11\n";
#  print "secondarycontact_secondarytelephone : $secondarycontact_secondarytelephone_section11\n";
#  print "secondarycontact_fax                : $secondarycontact_fax_section11\n";
#  print "secondarycontact_email              : $secondarycontact_email_section11\n";

#  print "additional_information : $additional_information_section11\n";


   # AGENCY
   if ( ( length(trim($agency_section11)) == 0 ) || (trim($agency_section11) eq '(multiple lines)' ) )
    {
       print('Section 11 - Agency : missing input' . "\n");
    }

   # PREFERRED ABBREVIATION
   if ( ( length(trim($preferredabbreviation_section11)) == 0 ) || (trim($preferredabbreviation_section11) eq '(A10)' ) )
    {
       print('Section 11 - Preferred Abbreviation : missing input' . "\n");
    }

   # MAILING ADDRESS
   if ( ( length(trim($mailing_address_section11)) == 0 ) || (trim($mailing_address_section11) eq '(multiple lines)' ) )
    {
       print('Section 11 - Mailing Address : missing input' . "\n");
    }

   # PRIMARY CONTACT - CONTACT NAME
   if ( length(trim($primarycontact_contactname_section11)) == 0 )
    {
       print('Section 11 - Primary Contact - Contact Name : missing input' . "\n");
    }

   # PRIMARY CONTACT - E-MAIL
   if ( length(trim($primarycontact_email_section11)) == 0 )
    {
       print('Section 11 - Primary Contact - E-mail : missing input' . "\n");
    }
   else
    {
      if ($primarycontact_email_section11 !~ /^([\w\-]+(\.[\w\-]+)*)@([\w\-]+(\.[\w\-]+)*)\.(\w+)$/)  # [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}
       {
        print('Section 11 - Primary Contact - E-mail : invalid address' . "\n");
       }
    }

   # SECONDARY CONTACT - E-MAIL
   if ( ( length(trim($secondarycontact_email_section11)) == 0 ) && (length(trim($secondarycontact_contactname_section11)) > 0) )
    {
       print('Section 11 - Secondary Contact - E-mail : missing input' . "\n");
    }

   if ( ( length(trim($secondarycontact_email_section11)) > 0 ) && (length(trim($secondarycontact_contactname_section11)) > 0) )
    {
      if ($secondarycontact_email_section11 !~ /^([\w\-]+(\.[\w\-]+)*)@([\w\-]+(\.[\w\-]+)*)\.(\w+)$/)  # [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}
       {
         print('Section 11 - Secondary Contact - E-mail : invalid address' . "\n");
       }
    }


  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 12 not found.'; }



  #######################################################################
  # READ SECTION 12.
  #######################################################################
  #print (" read 12\n");
  $line = <LogFile>;
  while ( ( $line !~ /^13.\s*More\s*Information\s*/i ) && (!eof(LogFile)) )
     {
       $tmp = substr($line,30,length($line)-31);
       if (substr($line,0,32) =~ /\s*Agency\s*/i )
              {
                  $agency_section12 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Preferred\s*Abbreviation\s*/i ) && (!eof(LogFile)) && (trim($line) ne "") )
                    {
                      if (length($line) >  32) { $agency_section12 .= "\n" . trim(substr($line,32,length($line)-33)); }
                      $line = <LogFile>;
                    }
                  if ( ( (eof(LogFile)) || (trim($line) eq "") ) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Preferred Abbreviation" not found in section No 12.'; }
              } 
       if (substr($line,0,32) =~ /\s*Preferred\s*Abbreviation\s*/i )    { $preferredabbreviation_section12 = trim(substr($line,32,length($line)-33));  }

       if ((substr($line,0,32) =~ /\s*Mailing\s*Address\s*/i ) && ($tmp !~ /\s*Mailing\s*Address\s*/i ) )
              {
                  $mailing_address_section12 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Primary\s*Contact\s*/i ) && (!eof(LogFile)) && (trim($line) ne "") )
                    {
                      if (length($line) >  32) { $mailing_address_section12 .= "\n" . trim(substr($line,32,length($line)-33)); }
                      $line = <LogFile>;
                    }
                  if ( ( (eof(LogFile)) || (trim($line) eq "") ) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Primary Contact" not found in section No 12.'; }
              } 

       if ((substr($line,0,32) =~ /\s*Primary\s*Contact\s*/i ) && ($tmp !~ /\s*Primary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Secondary\s*Contact\s*/i ) && (!eof(LogFile)) )
                    {

                      if (substr($line,0,32) =~ /\s*Contact\s*Name\s*/i )
                        {
                           $primarycontact_contactname_section12 = trim(substr($line,32,length($line)-33));
                        }   
                       
                      if (substr($line,0,32) =~ /\s*Telephone\s*\(primary\)\s*/i )
                        {
                           $primarycontact_primarytelephone_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        {
                           $primarycontact_secondarytelephone_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Fax\s*/i )
                        {
                           $primarycontact_fax_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*E-mail\s*/i )
                        {
                           $primarycontact_email_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      $line = <LogFile>;
       
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Secondary Contact" not found in section No 12.'; }
              } 

       if ((substr($line,0,32) =~ /\s*Secondary\s*Contact\s*/i ) && ($tmp !~ /\s*Secondary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( ( $line !~ /\s*Additional\s*Information\s*/i ) && (!eof(LogFile)) )
                    {

                      if (substr($line,0,32) =~ /\s*Contact\s*Name\s*/i )
                        {
                           $secondarycontact_contactname_section12 = trim(substr($line,32,length($line)-33));
                        }   
                           
                      if (substr($line,0,32) =~ /\s*Telephone\s*\(primary\)\s*/i )
                        {
                           $secondarycontact_primarytelephone_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        {
                           $secondarycontact_secondarytelephone_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*Fax\s*/i )
                        {
                           $secondarycontact_fax_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      if (substr($line,0,32) =~ /\s*E-mail\s*/i )
                        {
                           $secondarycontact_email_section12 = trim(substr($line,32,length($line)-33));
                        }   

                      $line = <LogFile>;
                   
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Field "Additional Information" not found in section No 12.'; }
              } 

       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section12 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (trim($line) ne "") && (!eof(LogFile)) )
                    {
                      $additional_information_section12 .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                    }
                  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'No empty line between sections No 12 and No 13.'; }
              } 
       $line = <LogFile>;

     }
   $agency_section12 =~s/\'/&#39;/g;
   $agency_section12 =~s/"/&#39;/g;
   $mailing_address_section12 =~s/\'/&#39;/g;
   $mailing_address_section12 =~s/"/&#39;/g;
   $additional_information_section12 =~s/\'/&#39;/g;
   $additional_information_section12 =~s/"/&#39;/g;
      
#  print "$agency_section12\n";
#  print "$preferredabbreviation_section12\n";
#  print "$mailing_address_section12\n";
  
#  print "primarycontact_contactname        : $primarycontact_contactname_section12\n";
#  print "primarycontact_primarytelephone   : $primarycontact_primarytelephone_section12\n";
#  print "primarycontact_secondarytelephone : $primarycontact_secondarytelephone_section12\n";
#  print "primarycontact_fax                : $primarycontact_fax_section12\n";
#  print "primarycontact_email              : $primarycontact_email_section12\n";

#  print "secondarycontact_contactname        : $secondarycontact_contactname_section12\n";
#  print "secondarycontact_primarytelephone   : $secondarycontact_primarytelephone_section12\n";
#  print "secondarycontact_secondarytelephone : $secondarycontact_secondarytelephone_section12\n";
#  print "secondarycontact_fax                : $secondarycontact_fax_section12\n";
#  print "secondarycontact_email              : $secondarycontact_email_section12\n";

#  print "additional_information : $additional_information_section12\n";





if ( (length(trim($agency_section12)) > 0) && (trim($agency_section12) ne '(multiple lines)') )
{

   # PREFERRED ABBREVIATION
   if ( ( length(trim($preferredabbreviation_section12)) == 0 ) || (trim($preferredabbreviation_section12) eq '(A10)' ) )
    {
       print('Section 12 - Preferred Abbreviation : missing input' . "\n");
    }

   # MAILING ADDRESS
   if ( ( length(trim($mailing_address_section12)) == 0 ) || (trim($mailing_address_section12) eq '(multiple lines)' ) )
    {
       print('Section 12 - Mailing Address : missing input' . "\n");
    }

   # PRIMARY CONTACT - CONTACT NAME
   if ( length(trim($primarycontact_contactname_section12)) == 0 )
    {
       print('Section 12 - Primary Contact - Contact Name : missing input' . "\n");
    }

   # PRIMARY CONTACT - E-MAIL
   if ( length(trim($primarycontact_email_section12)) == 0 )
    {
       print('Section 12 - Primary Contact - E-mail : missing input' . "\n");
    }
   else
    {
      if ($primarycontact_email_section12 !~ /^([\w\-]+(\.[\w\-]+)*)@([\w\-]+(\.[\w\-]+)*)\.(\w+)$/)  # [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}
       {
        print('Section 12 - Primary Contact - E-mail : invalid address' . "\n");
       }
    }

   # SECONDARY CONTACT - E-MAIL
   if ( ( length(trim($secondarycontact_email_section12)) == 0 ) && (length(trim($secondarycontact_contactname_section12)) > 0) )
    {
       print('Section 12 - Secondary Contact - E-mail : missing input' . "\n");
    }

   if ( ( length(trim($secondarycontact_email_section12)) > 0 ) && (length(trim($secondarycontact_contactname_section12)) > 0) )
    {
      if ($secondarycontact_email_section12 !~ /^([\w\-]+(\.[\w\-]+)*)@([\w\-]+(\.[\w\-]+)*)\.(\w+)$/)  # [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}
       {
         print('Section 12 - Secondary Contact - E-mail : invalid address' . "\n");
       }
    }

 }



  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Title of section No 13 not found.'; }


  #######################################################################
  # READ SECTION 13.(until Antenna Graphics with Dimensions)
  #######################################################################
  #print (" read 13\n");
  while ( ( $line !~ /\s*Antenna\s*Graphics\s*with\s*Dimensions\s*/i ) && (!eof(LogFile)) )
     {
       $line = <LogFile>;
       if (substr($line,0,32) =~ /\s*Primary\s*Data\s*Center\s*/i )        { $primary_data_center = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Secondary\s*Data\s*Center\s*/i )      { $secondary_data_center = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*URL\s*for\s*More\s*Information\s*/i ) { $url_for_more_information = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Site\s*Map\s*/i )                     { $site_map = trim(substr($line,32,length($line)-33)); }
       if (substr($line,0,32) =~ /\s*Site\s*Diagram\s*/i )                 { $site_diagram = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Horizon\s*Mask\s*/i )                 { $horizon_mask = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Monument\s*Description\s*/i )         { $monument_description_MI = trim(substr($line,32,length($line)-33)); } 
       if (substr($line,0,32) =~ /\s*Site\s*Pictures\s*/i )                { $site_pictures = trim(substr($line,32,length($line)-33)); }        


       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section13 = trim(substr($line,32,length($line)-33));
                  $line = <LogFile>;
                  while ( (( $line !~ /\s*Antenna\s*Graphics\s*with\s*Dimensions\s*/i ) && (trim($line) ne "")) && (!eof(LogFile)) )
                    {
                      $additional_information_section13 .= "\n" . trim(substr($line,32,length($line)-33));
                      $line = <LogFile>;
                   }
                 if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 13 - line "Antenna Graphics with Dimensions" not found'; }

              } 
     }


   $additional_information_section13 =~s/\'/&#39;/g;
   $additional_information_section13 =~s/"/&#39;/g;
      
#  print "$primary_data_center\n";
#  print "$secondary_data_center\n";
#  print "$url_for_more_information\n";
#  print "$site_map\n";
#  print "$site_diagram\n";
#  print "$horizon_mask\n";
#  print "$monument_description_MI\n";
#  print "$site_pictures\n";
#  print "$additional_information_section13\n";

   # PRIMARY DATA CENTRE
   if ( length(trim($primary_data_center)) == 0 )
    {
       print('Section 13 - Primary Data Center : missing input' . "\n");
    }

  if ( (eof(LogFile)) && ($encounteredproblem eq '') ) { $encounteredproblem = 'Section 13 - line "Antenna Graphics with Dimensions" not found'; }
 

  #######################################################################
  # READ "Antenna Graphics with Dimensions" (in the section 13.)
  #######################################################################
#  print(" read antenna graphics\n");
  $antenna_graphics_with_dimensions = "";
  while (!eof(LogFile) )
     {
       $line = <LogFile>;
       $antenna_graphics_with_dimensions .= $line;
     }

  $antenna_graphics_with_dimensions =~s/\'/&#39;/g;
  $antenna_graphics_with_dimensions =~s/"/&#39;/g;

#  print("$antenna_graphics_with_dimensions\n");

  

# FourID, PreparedBy, DatePrepared, ReportType, CurrentLogFileName, PreviousLog, ModifiedSection,
# SiteName, Four_character_id, MonumentInscri, IERDOMES, CDPNum, MonumentDescript, HeightMonu, MonuFound, FoundDepth, MarkerDescript, DateInstalled, GeologicChar, BedrockType, BedrockCond, FractureSpacing, FaultZones, Distance, AddInfo1,
# City, State, Country, Tectonic, XCoor, YCoor, ZCoor, LatitudeNorth, LongitudeEast, Elevation, AddInfo2,
# NameAgency, PreAbbr, MailingAdd
# Name1, Tel1, Sectel1, Fax1, Email1,
# Name2, Tel2, Sectel2, Fax2, Email2,
# AddInfo11,
# AgencyResponsible, PreAbbResponsible, MailinAddResponsible,
# ContactNameResponsible, Tel1responsible, Tel2Responsible, FaxResponsible, EmailResponsible,
# Contact2Responsible, 	TelContact1Responsible, TelContact2Responsible, Fax2Responsible, Email2Responsible
# AddInfo12
# PrimaryDataCenter, SecondaryDataCenter, URLMoreInfo, SiteMap, SiteDiagram, horizonMask, MonumentDescription_MI, SitePicture, AddInfo13,
# AntennaGraph



  close(LogFile);

  if ($encounteredproblem ne "") { print("$encounteredproblem\n"); }
 }

print("\n" . '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' . "\n");


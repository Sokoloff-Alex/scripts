sub sitelogfilereading{	

#-------------------------------------------------------------------
# Author : Royal Observatory of Belgium
#
# Disclaimer : No responsibility is accepted by or on behalf of the ROB for any script errors.
#              The ROB will under no circumstances be held liable for any direct or indirect consequences,
#              nor for any damages that may occur from the use of this script (or any required other script).
#-------------------------------------------------------------------

open (LogFile, "$sitelogfilename");

$display_warning = "no";
$debug_mode = "no";

if ($debug_mode eq "yes")
 {
   print("\n============================= READ " . $sitelogfilename . " ==================================================\n");
 }
 
#######################################################################
# READ SECTION 0.
#######################################################################
undef($prepared_by);
undef($date_prepared);
undef($report_type);
undef($previous_site_log);
undef($modified_added_sections);

while ( $line !~ /^1.\s*Site\s*Identification\s*of\s*the\s*GNSS\s*Monument\s*/i )
  {
    if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 0.)"); return 1; }
    $line = <LogFile>;
    if (substr($line,0,32) =~ /\s*Prepared\s*by\s*\(full name\)\s*/i ) { $prepared_by = trim(substr($line,32,length($line)-33)); } 
    if ($line =~ /\s*Date\s*Prepared\s*/i )
     {
       if(length($line) > index($line,":")+1) { $date_prepared = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
       else  { $date_prepared = ""; }
     } 
    if ($line =~ /\s*Report\s*Type\s*/i )
     {
       if(length($line) > index($line,":")+1) { $report_type = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
       else  { $report_type = ""; }
     } 
    if (substr($line,0,32) =~ /\s*Previous\s*Site\s*Log\s*/i )         { $previous_site_log = trim(substr($line,32,length($line)-33)); } 
    if (substr($line,0,32) =~ /\s*Modified\/Added\s*Sections\s*/i )
       {
         $modified_added_sections = trim(substr($line,32,length($line)-33));
         $line = <LogFile>;
         while (trim($line) ne "")
           {
             $modified_added_sections .= "\n" . trim(substr($line,32,length($line)-33));
             $line = <LogFile>;
           }
       } 
  }


if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 0. +++++++++++++++++++++++++++++++++ \n");
  print "$prepared_by\n";
  print "$date_prepared\n";
  print "$report_type\n";
  print "$previous_site_log\n";
  print "$modified_added_sections\n";
 }  

if ($display_warning eq "yes")
 {
   if ( $line =~ /1.\s*Site\s*Identification\s*of\s*the\s*GPS\s*Monument\s*/i )
     {
      print($sitelogfilename . " --> WARNING : line \"1.   Site Identification of the GNSS Monument\" missing but \"Site Identification of the GPS Monument\" found\n");
     }

   if ( $line !~ /^1.\s*Site\s*Identification\s*of\s*the\s*/i )
     {
      print($sitelogfilename . " --> WARNING : line \"1.   Site Identification of the GNSS Monument\" one space right shifted\n");
     }
 }


#######################################################################
# READ SECTION 1.
#######################################################################
undef($site_name);
undef($four_character_id);
undef($monument_inscription);
undef($iers_domes_number);
undef($cdp_number);
undef($monument_description);
undef($height_of_the_monument);
undef($monument_foundation);
undef($foundation_depth);
undef($marker_description);
undef($date_installed);
undef($geologic_characteristic);
undef($bedrock_type);
undef($bedrock_condition);
undef($fracture_spacing);
undef($fault_zones_nearby);
undef($distance_activity);
undef($additional_information_section1);

while ($line !~ /2.\s*Site\s*Location\s*Information\s*/i )
       {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 1.)"); return 1; }
       $line = <LogFile>;
       if ($line =~ /\s*Site\s*Name\s*/i )                  { $site_name = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Four\s*Character\s*ID\s*/i )        { $four_character_id = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Monument\s*Inscription\s*/i )
         {
	   if(length($line) > index($line,":")+1) { $monument_inscription = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
           else { $monument_inscription = ""; }
         }	   
       if ($line =~ /\s*IERS\s*DOMES\s*Number\s*/i )        { $iers_domes_number = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*CDP\s*Number\s*/i )
         {
	   if(length($line) > index($line,":")+1) { $cdp_number = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
	   else  { $cdp_number = ""; }
         } 
       if ($line =~ /\s*Monument\s*Description\s*/i )       { $monument_description = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Height\s*of\s*the\s*Monument\s*/i )
         {
	   if(length($line) > index($line,":")+1) { $height_of_the_monument = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
	   else  { $height_of_the_monument = ""; }
         } 
       if ($line =~ /\s*Monument\s*Foundation\s*/i )        { $monument_foundation = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Foundation\s*Depth\s*/i )           { $foundation_depth = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Marker\s*Description\s*/i )         { $marker_description = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Date\s*Installed\s*/i )             { $date_installed = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Geologic\s*Characteristic\s*/i )    { $geologic_characteristic = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Bedrock\s*Type\s*/i )               { $bedrock_type = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Bedrock\s*Condition\s*/i )          { $bedrock_condition = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Fracture\s*Spacing\s*/i )           { $fracture_spacing = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Fault\s*zones\s*nearby\s*/i )       { $fault_zones_nearby = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

       if ($line =~ /\s*Distance\/activity\s*/i ) 
              {
                  $distance_activity = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while ( ($line !~ /\s*Additional\s*Information\s*/i ) && (trim($line) ne "") )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 1. - Distance activity)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $distance_activity .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
              }    

       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section1 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 1. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $additional_information_section1 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
              } 



     }

if ($display_warning eq "yes")
 {
   if ( $line !~ /^2.\s*Site\s*Location\s*Information\s*/i )
     {
      print($sitelogfilename . " --> WARNING : line \"2.   Site Location Information\" one space right shifted\n");
     }
 }



if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 1. +++++++++++++++++++++++++++++++++ \n");
  print "$site_name\n";
  print "$four_character_id\n";
  print "$monument_inscription\n";
  print "$iers_domes_number\n";
  print "$cdp_number\n";
  print "$monument_description\n";
  print "$height_of_the_monument\n";
  print "$monument_foundation\n";
  print "$foundation_depth\n";
  print "$marker_description\n";
  print "$date_installed\n";
  print "$geologic_characteristic\n";
  print "$bedrock_type\n";
  print "$bedrock_condition\n";
  print "$fracture_spacing\n";
  print "$fault_zones_nearby\n";
  print "$distance_activity\n";
  print "$additional_information_section1\n";
 }





#######################################################################
# READ SECTION 2.
#######################################################################
undef($city_or_town);
undef($state_or_province);
undef($country);
undef($tectonic_plate);
undef($x_coordinate);
undef($y_coordinate);
undef($z_coordinate);
undef($latitude);
undef($longitude);
undef($elevation);
undef($additional_information_section2);

while ( ( $line !~ /3.\s*GNSS\s*Receiver\s*Information\s*/i ) and ( $line !~ /3.\s*GPS\s*Receiver\s*Information\s*/i ) and ( $line !~ /\s*Receiver\s*Type\s*/i ) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 2.)"); return 1; }
       $line = <LogFile>;
       if ($line =~ /\s*City\s*or\s*Town\s*/i )            { $city_or_town = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*State\s*or\s*Province\s*/i )       { $state_or_province = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Country\s*/i )                     { $country = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Tectonic\s*Plate\s*/i )            { $tectonic_plate = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*X\s*coordinate\s*/i )              { $x_coordinate = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Y\s*coordinate\s*/i )              { $y_coordinate = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Z\s*coordinate\s*/i )              { $z_coordinate = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Latitude\s*\(N is \+\)\s*/i )       { $latitude = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Longitude\s*\(E is \+\)\s*/i )      { $longitude = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Elevation\s*\(m,ellips.\)\s*/i )   { $elevation = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  if (length($line) > index($line,":")+1 ) { $additional_information_section2 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
		  else  { $additional_information_section2 = ""; }
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 2. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $additional_information_section2 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
              } 

     }

      
if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 2. +++++++++++++++++++++++++++++++++ \n");
  print "$city_or_town\n";
  print "$state_or_province\n";
  print "$country\n";
  print "$tectonic_plate\n";
  print "$x_coordinate\n";
  print "$y_coordinate\n";
  print "$z_coordinate\n";
  print "$latitude\n";
  print "$longitude\n";
  print "$elevation\n";
  print "$additional_information_section2\n";
 }

if ($display_warning eq "yes")
 {
if ( $line =~ /3.\s*GPS\s*Receiver\s*Information\s*/i )
     {
      print("$sitelogfilename --> WARNING : line \"3.   GNSS Receiver Information\" missing but \"3.   GPS Receiver Information\" found\n");
     }

if (( $line !~ /^3.\s*/i ) && ( $line !~ /\s*Receiver\s*Type\s*/i ))
     {
      print($sitelogfilename . " --> WARNING : line \"3.   GNSS Receiver Information\" one space right shifted\n");
     }

if ( $line =~ /\s*Receiver\s*Type\s*/i )
     {
      print("$sitelogfilename --> WARNING : line \"3.   GNSS Receiver Information\" missing\n");
     }
 }







#######################################################################
# READ SECTION 3.
#######################################################################
$number_receivers = 0;
undef(*receiver);

while ( ( $line !~ /4.\s*GNSS\s*Antenna\s*Information\s*/i ) and ( $line !~ /4.\s*GPS\s*Antenna\s*Information\s*/i ) )
     {
       
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 3.)"); return 1; }
       if ( ($line =~ /\s*Receiver\s*Type\s*/i ) && ($line !~ /\s*3.x\s*/i ) )
          {
            $number_receivers++;   
            $receiver{type}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {

                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 3. - Receiver Type)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Satellite\s*System\s*/i )           { $receiver{satellite_system}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if (substr($line,0,index($line,":")+1) =~ /\s*Serial\s*Number\s*:\s*/i )              { $receiver{serial_number}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if (substr($line,0,index($line,":")+1) =~ /\s*Firmware\s*Version\s*/i )           { $receiver{firmware_version}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Elevation\s*Cutoff\s*Setting\s*/i ) { $receiver{elevation_cutoff_setting}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Date\s*Installed\s*:\s*/i ) 
                   {
                      $receiver{date_installed}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));

		      if ($receiver{date_installed}[$number_receivers] =~ /\d{4}-\d{2}-\d{2}/)
		        {
		          $receiver{year_installed}[$number_receivers] = substr($receiver{date_installed}[$number_receivers],0,4); 
		          $monthnumber = substr($receiver{date_installed}[$number_receivers],5,2); 
		          $receiver{doy_installed}[$number_receivers] = substr($receiver{date_installed}[$number_receivers],8,2); 

                          if($receiver{year_installed}[$number_receivers] % 4 == 0)
		            { $february = 29; }
		          else	
		            { $february = 28; }
                          my @doy_onfirstofmonths = (0,31, (31+$february), (62+$february),(92+$february),(123+$february),(153+$february),(184+$february),(215+$february),(245+$february),(276+$february),(306+$february));
                          $receiver{doy_installed}[$number_receivers]  += @doy_onfirstofmonths[($monthnumber-1)];

                          if ($receiver{date_installed}[$number_receivers] =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z/)
                            {
                              $receiver{hour_installed}[$number_receivers] = substr($receiver{date_installed}[$number_receivers],11,2);
                              $receiver{minute_installed}[$number_receivers] = substr($receiver{date_installed}[$number_receivers],14,2); 
                            }

                        }
		      else
                        {
                         $receiver{year_installed}[$number_receivers] = "0000";
                         $receiver{doy_installed}[$number_receivers] = '000';
                         $receiver{hour_installed}[$number_receivers] = '00';
                         $receiver{minute_installed}[$number_receivers] = '00';
			 if ($display_warning eq "yes")
			  {
                           print("Warning : Receiver Date Installed (section 3." . $number_receivers . ") not correctly formatted : $receiver{date_installed}[$number_receivers]\n");
		          } 
	                }  
                   } 
		 
		 
	 
                 if ($line =~ /\s*Date\s*Removed\s*:\s*/i )
                   {
                     $receiver{date_removed}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));

		      if ($receiver{date_removed}[$number_receivers] =~ /\d{4}-\d{2}-\d{2}/)
		        {
		          $receiver{year_removed}[$number_receivers] = substr($receiver{date_removed}[$number_receivers],0,4); 
		          $monthnumber = substr($receiver{date_removed}[$number_receivers],5,2); 
		          $receiver{doy_removed}[$number_receivers] = substr($receiver{date_removed}[$number_receivers],8,2); 

                          if($receiver{year_removed}[$number_receivers] % 4 == 0)
		            { $february = 29; }
		          else	
		            { $february = 28; }
                          my @doy_onfirstofmonths = (0,31, (31+$february), (62+$february),(92+$february),(123+$february),(153+$february),(184+$february),(215+$february),(245+$february),(276+$february),(306+$february));
                          $receiver{doy_removed}[$number_receivers]  += @doy_onfirstofmonths[($monthnumber-1)];

                          if ($receiver{date_removed}[$number_receivers] =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z/)
                            {
                              $receiver{hour_removed}[$number_receivers] = substr($receiver{date_removed}[$number_receivers],11,2);
                              $receiver{minute_removed}[$number_receivers] = substr($receiver{date_removed}[$number_receivers],14,2); 
                            }
                        }
		      else
                        {
                         $receiver{year_removed}[$number_receivers] = "0000";
                         $receiver{doy_removed}[$number_receivers] = '000';
                         $receiver{hour_removed}[$number_receivers] = '00';
                         $receiver{minute_removed}[$number_receivers] = '00';
			 if ($display_warning eq "yes")
			  {
                           print("Warning : Receiver Date Removed (section 3." . $number_receivers . ") not correctly formatted : $receiver{date_removed}[$number_receivers]\n");
		          } 
	                }  

                   } 


                 if ($line =~ /\s*Temperature\s*Stabiliz\.\s*/i )     { $receiver{temperature_stabilization}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $receiver{additional_information}[$number_receivers] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 3. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) 
                        {
                          $receiver{additional_information}[$number_receivers] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                        }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

       $line = <LogFile>;
     }

if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_receivers;$i++)
   {
      print("+++++++++++++ SECTION 3." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$receiver{type}[$i] $receiver{serial_number}[$i] $receiver{date_installed}[$i] $receiver{date_removed}[$i]\n");
      print("$receiver{firmware_version}[$i] $receiver{elevation_cutoff_setting}[$i] $receiver{temperature_stabilization}[$i]\n");
      print("$receiver{additional_information}[$i]\n");
   }   
 }


if ($display_warning eq "yes")
 {
   if ( $line =~ /4.\s*GPS\s*Antenna\s*Information\s*/i )
     {
      print("$sitelogfilename --> WARNING : line \"4.   GNSS Antenna Information\" missing but \"4.   GPS Antenna Information\" found\n");
     }

   if ( $line !~ /^4.\s*/i )
     {
      print($sitelogfilename . " --> WARNING : line \"4.   GNSS Antenna Information\" one space right shifted\n");
     }
 }





















  #######################################################################
  # READ SECTION 4.
  #######################################################################
  $number_antennae = 0;
  undef(*antenna);
  $wrongformat_4_arp_up_ecc = "false";
  $wrongformat_4_arp_north_ecc = "false";
  $wrongformat_4_arp_east_ecc = "false";
  
  while ( ( $line !~ /5.\s*Surveyed\s*Local\s*Ties\s*/i ) and ( $line !~ /5.\s*Local\s*Site\s*Ties\s*/i ) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 4.)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Antenna\s*Type\s*/i ) && ($line !~ /\s*4.x\s*/i ) )
          {
            $number_antennae++;   
            $antenna{type}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 4. - Antenna Type)"); return 1; }
                 $line = <LogFile>;

                 if ( (substr($line,0,index($line,":")+1) =~ /\s*Serial\s*Number\s*:\s*/i ) && ($line !~ /\s*Radome\s*/i ) )              { $antenna{serial_number}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Antenna\s*Reference\s*Point\s*/i )      { $antenna{antenna_reference_point}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

                 if ($line =~ /\s*Marker->ARP\s*Up\s*/i )
                   {
                     $antenna{arp_up_ecc}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
		     if (substr($antenna{arp_up_ecc}[$number_antennae],length($antenna{arp_up_ecc}[$number_antennae])-1,1) eq "m")
		       {
			       $antenna{arp_up_ecc}[$number_antennae] = trim(substr($antenna{arp_up_ecc}[$number_antennae],0,length($antenna{arp_up_ecc}[$number_antennae])-1));
			       $wrongformat_4_arp_up_ecc = "true";
		       }
		      if ($antenna{arp_up_ecc}[$number_antennae] =~ /(F8.4)/) { $antenna{arp_up_ecc}[$number_antennae] = "000.0000"; $wrongformat_4_arp_up_ecc = "true"; }
	           }

                 if ($line =~ /\s*Marker->ARP\s*North\s*Ecc\(m\)\s*/i )
                   {
                     $antenna{arp_north_ecc}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
		     if (substr($antenna{arp_north_ecc}[$number_antennae],length($antenna{arp_north_ecc}[$number_antennae])-1,1) eq "m")
		       {
			       $antenna{arp_north_ecc}[$number_antennae] = trim(substr($antenna{arp_north_ecc}[$number_antennae],0,length($antenna{arp_north_ecc}[$number_antennae])-1));
			       $wrongformat_4_arp_north_ecc = "true";
		       }
		      if ($antenna{arp_north_ecc}[$number_antennae] =~ /(F8.4)/) { $antenna{arp_north_ecc}[$number_antennae] = "000.0000"; $wrongformat_4_arp_north_ecc = "true"; }
	           }  

                 if ($line =~ /\s*Marker->ARP\s*East\s*Ecc\(m\)\s*/i )
                   {
                     $antenna{arp_east_ecc}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
		     if (substr($antenna{arp_east_ecc}[$number_antennae],length($antenna{arp_east_ecc}[$number_antennae])-1,1) eq "m")
		       {
			       $antenna{arp_east_ecc}[$number_antennae] = trim(substr($antenna{arp_east_ecc}[$number_antennae],0,length($antenna{arp_east_ecc}[$number_antennae])-1));
			       $wrongformat_4_arp_east_ecc = "true";
		       }
		      if ($antenna{arp_east_ecc}[$number_antennae] =~ /(F8.4)/) { $antenna{arp_east_ecc}[$number_antennae] = "000.0000"; $wrongformat_4_arp_east_ecc = "true"; }
                   }
		   
                 if ($line =~ /\s*Alignment\s*from\s*True\s*N\s*/i )      { $antenna{alignment_from_true_n}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ( ($line =~ /\s*Antenna\s*Radome\s*Type\s*/i ) && ( $line !~ /\s*Additional Information\s*/i ) && (substr($line,0,20) ne "                    ") )    { $antenna{antenna_radome_type}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Radome\s*Serial\s*Number\s*/i )      { $antenna{radome_serial_number}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Antenna\s*Cable\s*Type\s*/i )      { $antenna{antenna_cable_type}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Antenna\s*Cable\s*Length\s*/i )      { $antenna{antenna_cable_length}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Date\s*Installed\s*:\s*/i )
                   {
                      $antenna{date_installed}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
		     
		      if ($antenna{date_installed}[$number_antennae] =~ /\d{4}-\d{2}-\d{2}/)
		        {
		          $antenna{year_installed}[$number_antennae] = substr($antenna{date_installed}[$number_antennae],0,4); 
		          $monthnumber = substr($antenna{date_installed}[$number_antennae],5,2); 
		          $antenna{doy_installed}[$number_antennae] = substr($antenna{date_installed}[$number_antennae],8,2); 

                          if($antenna{year_installed}[$number_antennae] % 4 == 0)
		            { $february = 29; }
		          else	
		            { $february = 28; }
                          my @doy_beforefirstofmonths = (0,31, (31+$february), (62+$february),(92+$february),(123+$february),(153+$february),(184+$february),(215+$february),(245+$february),(276+$february),(306+$february));
                          $antenna{doy_installed}[$number_antennae]  += @doy_beforefirstofmonths[($monthnumber-1)];

                          if ($antenna{date_installed}[$number_antennae] =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z/)
                            {
                              $antenna{hour_installed}[$number_antennae] = substr($antenna{date_installed}[$number_antennae],11,2);
                              $antenna{minute_installed}[$number_antennae] = substr($antenna{date_installed}[$number_antennae],14,2); 
                            }
                        }
		      else
                        {
                         $antenna{year_installed}[$number_antennae] = "0000";
                         $antenna{doy_installed}[$number_antennae] = '000';
                         $antenna{hour_installed}[$number_antennae] = '00';
                         $antenna{minute_installed}[$number_antennae] = '00';
			  if ($display_warning eq "yes")
                           {
                            print("Warning : Antenna Date Installed (section 4." . $number_antennae . ") not correctly formatted : $antenna{date_installed}[$number_antennae]\n");
		           } 
	                }  
		     
                   }
		   
		   
                 if ($line =~ /\s*Date\s*Removed\s*:\s*/i )
                   {
                     $antenna{date_removed}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));

		      if ($antenna{date_removed}[$number_antennae] =~ /\d{4}-\d{2}-\d{2}/)
		        {
		          $antenna{year_removed}[$number_antennae] = substr($antenna{date_removed}[$number_antennae],0,4); 
		          $monthnumber = substr($antenna{date_removed}[$number_antennae],5,2); 
		          $antenna{doy_removed}[$number_antennae] = substr($antenna{date_removed}[$number_antennae],8,2); 

                          if($antenna{year_removed}[$number_antennae] % 4 == 0)
		            { $february = 29; }
		          else	
		            { $february = 28; }
                          my @doy_beforefirstofmonths = (0,31, (31+$february), (62+$february),(92+$february),(123+$february),(153+$february),(184+$february),(215+$february),(245+$february),(276+$february),(306+$february));
                          $antenna{doy_removed}[$number_antennae]  += @doy_beforefirstofmonths[($monthnumber-1)];

                          if ($antenna{date_removed}[$number_antennae] =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}Z/)
                            {
                              $antenna{hour_removed}[$number_antennae] = substr($antenna{date_removed}[$number_antennae],11,2);
                              $antenna{minute_removed}[$number_antennae] = substr($antenna{date_removed}[$number_antennae],14,2); 
                            }
                        }
		      else
                        {
                         $antenna{year_removed}[$number_antennae] = "0000";
                         $antenna{doy_removed}[$number_antennae] = '000';
                         $antenna{hour_removed}[$number_antennae] = '00';
                         $antenna{minute_removed}[$number_antennae] = '00';
			  if ($display_warning eq "yes")
                           {
                            print("Warning : Antenna Date Removed (section 4." . $number_antennae . ") not correctly formatted : $antenna{date_removed}[$number_antennae]\n");
		           } 
	                }  
                   }






                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $antenna{additional_information}[$number_antennae] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 4. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) 
                        {
                           $antenna{additional_information}[$number_antennae] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                        } 
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }


if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_antennae;$i++)
   {
      print("+++++++++++++ SECTION 4." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$antenna{type}[$i] $antenna{serial_number}[$i] $antenna{date_installed}[$i] $antenna{date_removed}[$i]\n");
      print("$antenna{antenna_reference_point}[$i] $antenna{alignment_from_true_n}[$i]\n");
      print("$antenna{arp_up_ecc}[$i] $antenna{arp_north_ecc}[$i] $antenna{arp_east_ecc}[$i]\n");
      print("$antenna{antenna_radome_type}[$i] $antenna{radome_serial_number}[$i] $antenna{antenna_cable_type}[$i] $antenna{antenna_cable_length}[$i]\n");
      print("$antenna{additional_information}[$i]\n");
   }
 }

if ($display_warning eq "yes")
{
   if ( $line =~ /5.\s*Local\s*Site\s*Ties\s*/i )
     {
      print("$sitelogfilename --> WARNING : line \"5.   Surveyed Local Ties\" missing but \"5.   Local Site Ties\" found\n");
     }

   if ( $wrongformat_4_arp_up_ecc eq "true")
     {
      print("$sitelogfilename --> WARNING in section 4 : -> wrong format for Marker->ARP Up Ecc\n");
     }

   if ( $wrongformat_4_arp_north_ecc eq "true")
     {
      print("$sitelogfilename --> WARNING in section 4 : -> wrong format for Marker->ARP North Ecc\n");
     }

   if ( $wrongformat_4_arp_east_ecc eq "true")
     {
      print("$sitelogfilename --> WARNING in section 4 : -> wrong format for Marker->ARP East Ecc\n");
     }
}











#######################################################################
# READ SECTION 5.
#######################################################################
$number_localties = 0;
undef(*localties);
while ( $line !~ /6.\s*Frequency\s*Standard\s*/i )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 5.)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Tied\s*Marker\s*Name\s*/i ) && ($line !~ /\s*5.x\s*/i ) )
          {
            $number_localties++;   
            $localties{tied_marker_name}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 5. - Tied Marker Name)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Tied\s*Marker\s*Usage\s*/i )          { $localties{tied_marker_usage}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Tied\s*Marker\s*CDP\s*Number\s*/i )   { $localties{tied_marker_cdp_number}[$number_localties] = trim(substr($line,index($line,":")+1,4)); } 
                 if ($line =~ /\s*Tied\s*Marker\s*DOMES\s*Number\s*/i ) { $localties{tied_marker_domes_number}[$number_localties] = trim(substr($line,index($line,":")+1,9)); } 
                 if ($line =~ /\s*dx\s*\(m\)\s*/i )                     { $localties{dx}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*dy\s*\(m\)\s*/i )                     { $localties{dy}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*dz\s*\(m\)\s*/i )                     { $localties{dz}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Accuracy\s*\(mm\)\s*/i )              { $localties{accuracy}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Survey\s*method\s*/i )                { $localties{survey_method}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Date\s*Measured\s*/i )                { $localties{date_measured}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $localties{additional_information}[$number_localties] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 5. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) { $localties{additional_information}[$number_localties] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_localties;$i++)
   {
      print("+++++++++++++ SECTION 5." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$localties{tied_marker_name}[$i]\n");
      print("$localties{tied_marker_usage}[$i] $localties{tied_marker_cdp_number}[$i] $localties{tied_marker_domes_number}[$i]\n");
      print("$localties{dx}[$i] $localties{dy}[$i] $localties{dz}[$i]\n");
      print("$localties{accuracy}[$i] $localties{survey_method}[$i] $localties{date_measured}[$i]\n");
      print("$localties{additional_information}[$i]\n");
   }   
 }




















#######################################################################
# READ SECTION 6.
#######################################################################
$number_frequencies = 0;
undef(*frequencies);
while ( ( $line !~ /7.\s*Collocation\s*Information\s*/i ) and ( $line !~ /\s*Instrumentation\s*Type\s*/i ) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 6.)"); return 1; }
       $line = <LogFile>;

       if ( ($line =~ /\s*Standard\s*Type\s*/i ) && ($line !~ /\s*6.x\s*/i ) )
          {
            $number_frequencies++;   
            $frequencies{standard_type}[$number_frequencies] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 6. - Standard Type)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Input\s*Frequency\s*/i )   { $frequencies{input_frequency}[$number_frequencies] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i )   { $frequencies{effective_dates}[$number_frequencies] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

                 if (($line =~ /\s*Notes\s*/i ) and (length($line) > index($line,":")+1) )
                 {
                  $frequencies{notes}[$number_frequencies] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 6. - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1) { $frequencies{notes}[$number_frequencies] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_frequencies;$i++)
   {
      print("+++++++++++++ SECTION 6." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$frequencies{standard_type}[$i] $frequencies{input_frequency}[$i] $frequencies{effective_dates}[$i]\n");
      print("$frequencies{notes}[$i]\n");
   }   
 }

if ($display_warning eq "yes")
{
if ( $line =~ /\s*Instrumentation\s*Type\s*/i )
  {
      print("$sitelogfilename --> WARNING : line \"7.   Collocation Information\" missing\n");
  }
}




















#######################################################################
# READ SECTION 7.
#######################################################################
$number_instrumentation = 0;
undef(*instrumentation);  
while ( $line !~ /8.\s*Meteorological\s*Instrumentation\s*/i )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 7.)"); return 1; }
       if ( ($line =~ /\s*Instrumentation\s*Type\s*/i ) && ($line !~ /\s*7.x\s*/i ) )
          {
            $number_instrumentation++;   
            $instrumentation{instrumentation_type}[$number_instrumentation] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 7. - Instrumentation Type)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Status\s*/i )            { $instrumentation{status}[$number_instrumentation] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i ) { $instrumentation{effective_dates}[$number_instrumentation] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if (($line =~ /\s*Notes\s*/i ) and (length($line) > index($line,":")+1) )
                 {
                  $instrumentation{notes}[$number_instrumentation] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 7. - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $instrumentation{notes}[$number_instrumentation] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 
                 if (($line =~ /\s*Notes\s*/i ) and (length($line) <= index($line,":")+1) )
                 {
		    $instrumentation{notes}[$number_instrumentation] = "";	 
		 }	 

              }
            
          }  

       $line = <LogFile>;
     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_instrumentation;$i++)
   {
      print("+++++++++++++ SECTION 7." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$instrumentation{instrumentation_type}[$i] $instrumentation{status}[$i] $instrumentation{effective_dates}[$i]\n");
      print("$instrumentation{notes}[$i]\n");
   }   
 }
















  #######################################################################
  # READ SECTION 8.1
  #######################################################################
  $number_humiditysensor = 0;
  undef(*humiditysensor);  
  while ( ( $line !~ /8.1.x\s*Humidity\s*Sensor\s*Model\s*/i ) and ($line !~ /\s*Pressure\s*Sensor\s*Model\s*/i ) and ($line !~ /9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.1)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Humidity\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.1.x\s*/i ) )
          {
            $number_humiditysensor++;   
            $humiditysensor{model}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.1 - Humidity Sensor Model)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Manufacturer\s*/i )               { $humiditysensor{manufacturer}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Serial\s*Number\s*/i )            { $humiditysensor{serial_number}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $humiditysensor{data_sampling_interval}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Accuracy\s*\(\% rel h\)\s*/i )    { $humiditysensor{accuracy}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Aspiration\s*/i )                 { $humiditysensor{aspiration}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $humiditysensor{height_diff_to_ant}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Calibration\s*date\s*/i )         { $humiditysensor{calibration_date}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i )          { $humiditysensor{effective_dates}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Notes\s*/i )
                 {
                  $humiditysensor{notes}[$number_humiditysensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.1 - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $humiditysensor{notes}[$number_humiditysensor] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_humiditysensor;$i++)
   {
      print("+++++++++++++ SECTION 8.1." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$humiditysensor{model}[$i] $humiditysensor{manufacturer}[$i] $humiditysensor{serial_number}[$i] $humiditysensor{data_sampling_interval}[$i] $humiditysensor{accuracy}[$i] $humiditysensor{aspiration}[$i] $humiditysensor{height_diff_to_ant}[$i] $humiditysensor{calibration_date}[$i] $humiditysensor{effective_dates}[$i]\n");
      print("$humiditysensor{notes}[$i]\n");
   }   
 }




















  #######################################################################
  # READ SECTION 8.2
  #######################################################################
  $number_pressuresensor = 0;
  undef(*pressuresensor);  
  while ( ( $line !~ /8.2.x\s*Pressure\s*Sensor\s*Model\s*/i ) and ($line !~ /\s*Temp.\s*Sensor\s*Model\s*/i ) and ($line !~ /9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.2)"); return 1; }
       if ( ($line =~ /\s*Pressure\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.2.x\s*/i ) )
          {
            $number_pressuresensor++;   
            $pressuresensor{model}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.2 - Pressure Sensor Model)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Manufacturer\s*/i )                { $pressuresensor{manufacturer}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Serial\s*Number\s*/i )
                   {
                      if (length($line) > index($line,":")+1) { $pressuresensor{serial_number}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
		      else  { $pressuresensor{serial_number}[$number_pressuresensor] = ""; }
	           } 
                 if ($line =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $pressuresensor{data_sampling_interval}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Accuracy\s*/i )                   { $pressuresensor{accuracy}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $pressuresensor{height_diff_to_ant}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Calibration\s*date\s*/i )         { $pressuresensor{calibration_date}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i )          { $pressuresensor{effective_dates}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Notes\s*/i )
                 {
                  $pressuresensor{notes}[$number_pressuresensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.2 - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $pressuresensor{notes}[$number_pressuresensor] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  
       $line = <LogFile>;

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_pressuresensor;$i++)
   {
      print("+++++++++++++ SECTION 8.2." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$pressuresensor{model}[$i] $pressuresensor{manufacturer}[$i] $pressuresensor{serial_number}[$i] $pressuresensor{data_sampling_interval}[$i] $pressuresensor{accuracy}[$i] $pressuresensor{height_diff_to_ant}[$i] $pressuresensor{calibration_date}[$i] $pressuresensor{effective_dates}[$i]\n");
      print("$pressuresensor{notes}[$i]\n");
   }   
 }



























  #######################################################################
  # READ SECTION 8.3
  #######################################################################
  $number_temperaturesensor = 0;
  undef(*temperaturesensor); 
  while ( ( $line !~ /8.3.x\s*Temp.\s*Sensor\s*Model\s*/i ) and ($line !~ /\s*Water\s*Vapor\s*Radiometer\s*/i ) and ($line !~ /9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.3)"); return 1; }
       if ( ($line =~ /\s*Temp.\s*Sensor\s*Model\s*/i ) && ($line !~ /\s*8.3.x\s*/i ) )
          {
            $number_temperaturesensor++;   
            $temperaturesensor{model}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.3 - Temp. Sensor Model)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Manufacturer\s*/i )               { $temperaturesensor{manufacturer}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Serial\s*Number\s*/i )
                   {
                      if (length($line) > index($line,":")+1) { $temperaturesensor{serial_number}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
		      else  { $temperaturesensor{serial_number}[$number_temperaturesensor] = ""; }
                   } 
                 if ($line =~ /\s*Data\s*Sampling\s*Interval\s*/i ) { $temperaturesensor{data_sampling_interval}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Accuracy\s*/i )                   { $temperaturesensor{accuracy}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Aspiration\s*/i )                 { $temperaturesensor{aspiration}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $temperaturesensor{height_diff_to_ant}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Calibration\s*date\s*/i )         { $temperaturesensor{calibration_date}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i )          { $temperaturesensor{effective_dates}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Notes\s*/i )
                 {
                  $temperaturesensor{notes}[$number_temperaturesensor] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.3 - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $temperaturesensor{notes}[$number_temperaturesensor] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  
       $line = <LogFile>;

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_temperaturesensor;$i++)
   {
      print("+++++++++++++ SECTION 8.3." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$temperaturesensor{model}[$i] $temperaturesensor{manufacturer}[$i] $temperaturesensor{serial_number}[$i] $temperaturesensor{data_sampling_interval}[$i] $temperaturesensor{accuracy}[$i] $temperaturesensor{aspiration}[$i] $temperaturesensor{height_diff_to_ant}[$i] $temperaturesensor{calibration_date}[$i] $temperaturesensor{effective_dates}[$i]\n");
      print("$temperaturesensor{notes}[$i]\n");
   }   
 }
       























  #######################################################################
  # READ SECTION 8.4
  #######################################################################
  $number_watervaporradiometer = 0;
  undef(*watervaporradiometer); 
  while ( ( $line !~ /8.4.x\s*Water\s*Vapor\s*Radiometer\s*/i ) and ($line !~ /\s*Other\s*Instrumentation\s*/i) and ($line !~ /9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.4)"); return 1; }
       if ( ($line =~ /\s*Water\s*Vapor\s*Radiometer\s*/i ) && ($line !~ /\s*8.4.x\s*/i ) )
          {
            $number_watervaporradiometer++;
            $watervaporradiometer{model}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.4 - Water Vapor Radiometer)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Manufacturer\s*/i )               { $watervaporradiometer{manufacturer}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Serial\s*Number\s*/i )            { $watervaporradiometer{serial_number}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Distance\s*to\s*Antenna\s*/i )    { $watervaporradiometer{distance_to_antenna}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Height\s*Diff\s*to\s*Ant\s*/i )   { $watervaporradiometer{height_diff_to_ant}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Calibration\s*date\s*/i )         { $watervaporradiometer{calibration_date}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Effective\s*Dates\s*/i )          { $watervaporradiometer{effective_dates}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
                 if ($line =~ /\s*Notes\s*/i )
                 {
                  $watervaporradiometer{notes}[$number_watervaporradiometer] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.4 - Notes)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $watervaporradiometer{notes}[$number_watervaporradiometer] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  
       $line = <LogFile>;

     }
      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_watervaporradiometer;$i++)
   {
      print("+++++++++++++ SECTION 8.4." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$watervaporradiometer{model}[$i] $watervaporradiometer{manufacturer}[$i] $watervaporradiometer{serial_number}[$i] $watervaporradiometer{distance_to_antenna}[$i] $watervaporradiometer{height_diff_to_ant}[$i] $watervaporradiometer{calibration_date}[$i] $watervaporradiometer{effective_dates}[$i]\n");
      print("$watervaporradiometer{notes}[$i]\n");
   }   
 }








  #######################################################################
  # READ SECTION 8.5
  #######################################################################
  $number_otherinstrumentation = 0;
  undef(*otherinstrumentation); 
  while ( $line !~ /9.\s*Local\s*Ongoing\s*Conditions\s*Possibly\s*Affecting\s*Computed\s*Position\s*/i )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.5)"); return 1; }
       if ( ($line =~ /\s*Other\s*Instrumentation\s*/i ) && ($line !~ /\s*8.5.x\s*/i ) )
          {
            $number_otherinstrumentation++;   
            if (length($line) > index($line,":")+1) { $otherinstrumentation[$number_otherinstrumentation] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
	    else { $otherinstrumentation[$number_otherinstrumentation] = ""; }
            $line = <LogFile>;
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 8.5 - Other Instrumentation)"); return 1; }
                 if (length($line) > index($line,":")+1) { $otherinstrumentation[$number_otherinstrumentation] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                 $line = <LogFile>;
              }
          } 
       $line = <LogFile>;
     }
            

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_otherinstrumentation;$i++)
   {
      print("+++++++++++++ SECTION 8.5." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$otherinstrumentation[$i]\n");
   }   
 }









  #######################################################################
  # READ SECTION 9.1
  #######################################################################
  $number_radiointerferences = 0;
  undef(*radiointerferences); 
  while ( ( $line !~ /9.1.x\s*Radio\s*Interferences\s*/i ) and ($line !~ /10.\s*Local\s*Episodic\s*Effects\s*Possibly\s*Affecting\s*Data\s*Quality\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.1)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Radio\s*Interferences\s*/i ) && ($line !~ /\s*9.1.x\s*/i ) )
          {
            $number_radiointerferences++;
            $radiointerferences{radiointerferences}[$number_radiointerferences] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.1 - Radio Interferences)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Observed\s*Degradations\s*/i ) { $radiointerferences{observed_degradations}[$number_radiointerferences] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                 if ($line =~ /\s*Effective\s*Dates\s*/i )       { $radiointerferences{effective_dates}[$number_radiointerferences] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $radiointerferences{additional_information}[$number_radiointerferences] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.1 - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) { $radiointerferences{additional_information}[$number_radiointerferences] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_radiointerferences;$i++)
   {
      print("+++++++++++++ SECTION 9.1." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$radiointerferences{radiointerferences}[$i] $radiointerferences{observed_degradations}[$i] $radiointerferences{effective_dates}[$i]\n");
      print("$radiointerferences{additional_information}[$i]\n");
   }   
 }






























  #######################################################################
  # READ SECTION 9.2
  #######################################################################
  $number_multipathsources = 0;
  undef(*multipathsources); 
  while ( ( $line !~ /9.2.x\s*Multipath\s*Sources\s*/i ) and ($line !~ /10.\s*Local\s*Episodic\s*Effects\s*Possibly\s*Affecting\s*Data\s*Quality\s*/i) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.2)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Multipath\s*Sources\s*/i ) && ($line !~ /\s*9.2.x\s*/i ) )
          {
            $number_multipathsources++;
            $multipathsources{multipathsources}[$number_multipathsources] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.2 - Multipath Sources)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Effective\s*Dates\s*/i )        { $multipathsources{effective_dates}[$number_multipathsources] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $multipathsources{additional_information}[$number_multipathsources] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.2 - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $multipathsources{additional_information}[$number_multipathsources] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_multipathsources;$i++)
   {
      print("+++++++++++++ SECTION 9.2." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$multipathsources{multipathsources}[$i] $multipathsources{effective_dates}[$i]\n");
      print("$multipathsources{additional_information}[$i]\n");
   }   
 }






















  #######################################################################
  # READ SECTION 9.3
  #######################################################################
  $number_signalobstructions = 0;
  undef(*signalobstructions); 
  while ( $line !~ /10.\s*Local\s*Episodic\s*Effects\s*Possibly\s*Affecting\s*Data\s*Quality\s*/i )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.3)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Signal\s*Obstructions\s*/i ) && ($line !~ /\s*9.3.x\s*/i ) )
          {
            $number_signalobstructions++;
            $signalobstructions{signalobstructions}[$number_signalobstructions] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.3 - Signal Obstructions)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Effective\s*Dates\s*/i )        { $signalobstructions{effective_dates}[$number_signalobstructions] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                 if ($line =~ /\s*Additional\s*Information\s*/i )
                 {
                  $signalobstructions{additional_information}[$number_signalobstructions] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 9.3 - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1 ) { $signalobstructions{additional_information}[$number_signalobstructions] .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
                 } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_signalobstructions;$i++)
   {
      print("+++++++++++++ SECTION 9.3." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$signalobstructions{signalobstructions}[$i] $signalobstructions{effective_dates}[$i]\n");
      print("$signalobstructions{additional_information}[$i]\n");
   }   
 }








  #######################################################################
  # READ SECTION 10.
  #######################################################################
  $number_localepisodiceffects = 0;
  undef(*localepisodiceffects); 
  while ( $line !~ /11.\s*On-Site,\s*Point\s*of\s*Contact\s*Agency\s*Information\s*/i )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 10.)"); return 1; }
       $line = <LogFile>;
       if ( ($line =~ /\s*Date\s*/i ) && ($line !~ /\s*10.x\s*/i ) )
          {
            $number_localepisodiceffects++;
            $localepisodiceffects{date}[$number_localepisodiceffects] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
            while (trim($line) ne "")
              {
                 if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 10. - Date)"); return 1; }
                 $line = <LogFile>;

                 if ($line =~ /\s*Event\s*/i )            { $localepisodiceffects{event}[$number_localepisodiceffects] = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 

              }
            
          }  

     }

      
if ($debug_mode eq "yes")
 {
  for($i=1;$i<=$number_localepisodiceffects;$i++)
   {
      print("+++++++++++++ SECTION 10." . $i . " +++++++++++++++++++++++++++++++++ \n");
      print("$localepisodiceffects{date}[$i] $localepisodiceffects{event}[$i]\n");
   }   
 }


























#######################################################################
# READ SECTION 11.
#######################################################################
undef($agency_section11);
undef($preferredabbreviation_section11);
undef($mailing_address_section11);
undef($primarycontact_contactname_section11);
undef($primarycontact_primarytelephone_section11);
undef($primarycontact_secondarytelephone_section11);
undef($primarycontact_fax_section11);
undef($primarycontact_email_section11);
undef($secondarycontact_contactname_section11);
undef($secondarycontact_primarytelephone_section11);
undef($secondarycontact_secondarytelephone_section11);
undef($secondarycontact_fax_section11);
undef($secondarycontact_email_section11);
undef($additional_information_section11);
  
  
  $line = <LogFile>;
  while ( ( $line !~ /12.\s*Responsible\s*Agency\s*/i ) and ( $line !~ /13.\s*More\s*Information\s*/i ) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11.)"); return 1; }
       if (length($line) > 30) { $tmp = substr($line,30,length($line)-31); } else { $tmp = ''; }
       if ( ($line =~ /\s*Agency\s*/i ) && ($tmp !~ /\s*Agency\s*/i ) )
              {
                  $agency_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));

                  $line = <LogFile>;

                  while ( $line !~ /\s*Preferred\s*Abbreviation\s*/i )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11. - Agency)"); return 1; }
                      if (length($line) > index($line,":")+1) { $agency_section11 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }  
                      $line = <LogFile>;
                    }
              } 

       if ($line =~ /\s*Preferred\s*Abbreviation\s*/i )    { $preferredabbreviation_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));  }


       if (($line =~ /\s*Mailing\s*Address\s*/i ) && ($tmp !~ /\s*Mailing\s*Address\s*/i ) )
              {
                  $mailing_address_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while ( $line !~ /\s*Primary\s*Contact\s*/i )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11. - Mailing Address)"); return 1; }
                      if (length($line) > index($line,":")+1) { $mailing_address_section11 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }  
                      $line = <LogFile>;
                    }
              } 



       if (($line =~ /\s*Primary\s*Contact\s*/i ) && ($tmp !~ /\s*Primary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( $line !~ /\s*Secondary\s*Contact\s*/i )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11. - Primary Contact)"); return 1; }

                      if ($line =~ /\s*Contact\s*Name\s*/i )
                        { $primarycontact_contactname_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   
                           
                      if ($line =~ /\s*Telephone\s*\(primary\)\s*/i )
                        { $primarycontact_primarytelephone_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        { $primarycontact_secondarytelephone_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Fax\s*/i )
                        { $primarycontact_fax_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*E-mail\s*/i )
                        { $primarycontact_email_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      $line = <LogFile>;
                       
                    }
              } 



       if (($line =~ /\s*Secondary\s*Contact\s*/i ) && ($tmp !~ /\s*Secondary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
                  while ( $line !~ /\s*Additional\s*Information\s*/i )
                    {

                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11. - Secondary Contact)"); return 1; }

                      if ($line =~ /\s*Contact\s*Name\s*/i )
                        { $secondarycontact_contactname_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   
                           
                      if ($line =~ /\s*Telephone\s*\(primary\)\s*/i )
                        { $secondarycontact_primarytelephone_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        { $secondarycontact_secondarytelephone_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Fax\s*/i )
                        { $secondarycontact_fax_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*E-mail\s*/i )
                        { $secondarycontact_email_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      $line = <LogFile>;
                       
                    }
              } 




       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section11 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (trim($line) ne "")
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 11. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1 ) {  $additional_information_section11 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
              } 
       $line = <LogFile>;

     }

if ($display_warning eq "yes")
{
   if ( $line =~ /13.\s*More\s*Information\s*/i )      
     {
      print("$sitelogfilename --> WARNING : section \"12.  Responsible Agency (if different from 11.)\" missing\n");
     }
}

      
if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 11. +++++++++++++++++++++++++++++++++ \n");
  print "$agency_section11\n";
  print "$preferredabbreviation_section11\n";
  print "$mailing_address_section11\n";

  print "primarycontact_contactname        : $primarycontact_contactname_section11\n";
  print "primarycontact_primarytelephone   : $primarycontact_primarytelephone_section11\n";
  print "primarycontact_secondarytelephone : $primarycontact_secondarytelephone_section11\n";
  print "primarycontact_fax                : $primarycontact_fax_section11\n";
  print "primarycontact_email              : $primarycontact_email_section11\n";

  print "secondarycontact_contactname        : $secondarycontact_contactname_section11\n";
  print "secondarycontact_primarytelephone   : $secondarycontact_primarytelephone_section11\n";
  print "secondarycontact_secondarytelephone : $secondarycontact_secondarytelephone_section11\n";
  print "secondarycontact_fax                : $secondarycontact_fax_section11\n";
  print "secondarycontact_email              : $secondarycontact_email_section11\n";

  print "additional_information : $additional_information_section11\n";
 }











#######################################################################
# READ SECTION 12.
#######################################################################
undef($agency_section12);
undef($preferredabbreviation_section12);
undef($mailing_address_section12);
undef($primarycontact_contactname_section12);
undef($primarycontact_primarytelephone_section12);
undef($primarycontact_secondarytelephone_section12);
undef($primarycontact_fax_section12);
undef($primarycontact_email_section12);
undef($secondarycontact_contactname_section12);
undef($secondarycontact_primarytelephone_section12);
undef($secondarycontact_secondarytelephone_section12);
undef($secondarycontact_fax_section12);
undef($secondarycontact_email_section12);
undef($additional_information_section12);

$line = <LogFile>;
while ( ( $line !~ /13.\s*More\s*Information\s*/i ) and ($line !~ /\s*Primary\s*Data\s*Center\s*/i ) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12.)"); return 1; }
       if (length($line) > 30) { $tmp = substr($line,30,length($line)-31); } else { $tmp = ''; }
       if ( ($line =~ /\s*Agency\s*/i ) && ($tmp !~ /\s*Agency\s*/i ) && (($line !~ /\s*Responsible\s*/i )) )
              {
                  $agency_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));

                  $line = <LogFile>;

                  while ( ( $line !~ /\s*Preferred\s*Abbreviation\s*/i ) && ( $line !~ /\s*Mailing\s*Address\s*/i ) )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12. - Agency)"); return 1; }
                      if (length($line)  > index($line,":")+1) { $agency_section12 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }  
                      $line = <LogFile>;
                    }
              } 

       if ($line =~ /\s*Preferred\s*Abbreviation\s*/i )    { $preferredabbreviation_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));  }


       if (($line =~ /\s*Mailing\s*Address\s*/i ) && ($tmp !~ /\s*Mailing\s*Address\s*/i ) )
              {
                  $mailing_address_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while ( $line !~ /\s*Primary\s*Contact\s*/i )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12. - Mailing Address)"); return 1; }
                      if (length($line) > index($line,":")+1) { $mailing_address_section12 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }	 
                      $line = <LogFile>;
                    }
               } 


       if (($line =~ /\s*Primary\s*Contact\s*/i ) && ($tmp !~ /\s*Primary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;
		  
                  while ( ( $line !~ /\s*Secondary\s*Contact\s*/i ) && (trim($line) ne "" ) )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12. - Primary Contact)"); return 1; }

                      if ($line =~ /\s*Contact\s*Name\s*/i )
                        { $primarycontact_contactname_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   
                           
                      if ($line =~ /\s*Telephone\s*\(primary\)\s*/i )
                        { $primarycontact_primarytelephone_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        { $primarycontact_secondarytelephone_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Fax\s*/i )
                        { $primarycontact_fax_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*E-mail\s*/i )
                        { $primarycontact_email_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      $line = <LogFile>;
                       
                    }
               } 


       if (($line =~ /\s*Secondary\s*Contact\s*/i ) && ($tmp !~ /\s*Secondary\s*Contact\s*/i ) )
              {
                  $line = <LogFile>;

                  while ( ( $line !~ /\s*Additional\s*Information\s*/i ) and ( $line !~ /13.\s*More\s*Information\s*/i ) and ($line !~ /\s*Primary\s*Data\s*Center\s*/i ) )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12. - Secondary Contact)"); return 1; }

                      if ($line =~ /\s*Contact\s*Name\s*/i )
                        { $secondarycontact_contactname_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   
                           
                      if ($line =~ /\s*Telephone\s*\(primary\)\s*/i )
                        { $secondarycontact_primarytelephone_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Telephone\s*\(secondary\)\s*/i )
                        { $secondarycontact_secondarytelephone_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*Fax\s*/i )
                        { $secondarycontact_fax_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      if ($line =~ /\s*E-mail\s*/i )
                        { $secondarycontact_email_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }   

                      $line = <LogFile>;
                       
                    }
               } 


       if ($line =~ /\s*Additional\s*Information\s*/i )
              {

                  $additional_information_section12 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;

                  while ( (trim($line) ne "") and ($line !~ /13.\s*More\s*Information\s*/i) )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 12. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) { $additional_information_section12 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }

               } 

       if ( ( $line !~ /13.\s*More\s*Information\s*/i ) and ($line !~ /\s*Primary\s*Data\s*Center\s*/i ) ) { $line = <LogFile>; }
       

     }

      
if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 12. +++++++++++++++++++++++++++++++++ \n");
  print "Agency section 12 : $agency_section12\n";
  print "$preferredabbreviation_section12\n";
  print "$mailing_address_section12\n";
  
  print "primarycontact_contactname        : $primarycontact_contactname_section12\n";
  print "primarycontact_primarytelephone   : $primarycontact_primarytelephone_section12\n";
  print "primarycontact_secondarytelephone : $primarycontact_secondarytelephone_section12\n";
  print "primarycontact_fax                : $primarycontact_fax_section12\n";
  print "primarycontact_email              : $primarycontact_email_section12\n";

  print "secondarycontact_contactname        : $secondarycontact_contactname_section12\n";
  print "secondarycontact_primarytelephone   : $secondarycontact_primarytelephone_section12\n";
  print "secondarycontact_secondarytelephone : $secondarycontact_secondarytelephone_section12\n";
  print "secondarycontact_fax                : $secondarycontact_fax_section12\n";
  print "secondarycontact_email              : $secondarycontact_email_section12\n";

  print "additional_information : $additional_information_section12\n";
 }
























#######################################################################
# READ SECTION 13.(until Antenna Graphics with Dimensions)
#######################################################################
undef($primary_data_center);
undef($secondary_data_center);
undef($url_for_more_information);
undef($site_map);
undef($site_diagram);
undef($horizon_mask);
undef($monument_description);
undef($site_pictures);
undef($additional_information_section13);

while (( $line !~ /\s*Antenna\s*Graphics\s*with\s*Dimensions\s*/i ) and (!eof(LogFile)) )
     {
       if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 13.)"); return 1; }
       if ($line =~ /\s*Primary\s*Data\s*Center\s*/i )        { $primary_data_center = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       $line = <LogFile>; #Must be writtent after Primary Data Centre, and before Additional Information
       if ($line =~ /\s*Secondary\s*Data\s*Center\s*/i )      { $secondary_data_center = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*URL\s*for\s*More\s*Information\s*/i ) { $url_for_more_information = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Site\s*Map\s*/i )                     { $site_map = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
       if ($line =~ /\s*Site\s*Diagram\s*/i )                 { $site_diagram = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Horizon\s*Mask\s*/i )                 { $horizon_mask = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Monument\s*Description\s*/i )         { $monument_description = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); } 
       if ($line =~ /\s*Site\s*Pictures\s*/i )                { $site_pictures = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }        


       if ($line =~ /\s*Additional\s*Information\s*/i )
              {
                  $additional_information_section13 = trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1));
                  $line = <LogFile>;
                  while (( $line !~ /\s*Antenna\s*Graphics\s*with\s*Dimensions\s*/i ) and (trim($line) ne "") and (!eof(LogFile)) )
                    {
                      if (eof(LogFile)) { &stop_and_send_mail($sitelogfilename . " (section 13. - Additional Information)"); return 1; }
                      if (length($line) > index($line,":")+1) { $additional_information_section13 .= "\n" . trim(substr($line,index($line,":")+1,length($line)-index($line,":")-1)); }
                      $line = <LogFile>;
                    }
              } 

     }

      
if ($debug_mode eq "yes")
 {
  print("+++++++++++++ SECTION 13. +++++++++++++++++++++++++++++++++ \n");
  print "$primary_data_center\n";
  print "$secondary_data_center\n";
  print "$url_for_more_information\n";
  print "$site_map\n";
  print "$site_diagram\n";
  print "$horizon_mask\n";
  print "$monument_description\n";
  print "$site_pictures\n";
  print "$additional_information_section13\n";
 }





if ($display_warning eq "yes")
{
  if (eof(LogFile))
    {
      print("$sitelogfilename --> WARNING : line \"Antenna Graphics with Dimensions\" missing\n");
    }
}




#######################################################################
# READ "Antenna Graphics with Dimensions" (in the section 13.)
#######################################################################
$antenna_graphics_with_dimensions = "";
while (!eof(LogFile) )
 {
   $line = <LogFile>;
   $antenna_graphics_with_dimensions .= $line;
 }

if ($debug_mode eq "yes")
 {
   print("+++++++++++++ SECTION Antenna Graphics with Dimensions +++++++++++++++++++++++++++++++++ \n");
   print("$antenna_graphics_with_dimensions\n");
 }




  close(LogFile);
}


sub stop_and_send_mail
 {
    print("\n" . $sitelogfilename . " --> ERROR : $_[0]\n\n");
    return 1;
 }


return 1;

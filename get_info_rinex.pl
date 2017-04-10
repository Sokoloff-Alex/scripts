#!/usr/bin/perl -w
#
#  Liest Informationen aus dem RINEX2 Header
#
##
use strict;
use warnings;

#
my @Zeilen;
my $mark_name;
my $mark_number;
my $h_exc;               
my $e_exc;               
my $n_exc;               
my $ant_numb;
my $ant_type;
my $ant_cone;
my $rec_numb;
my $rec_type; 
my $rec_vers;
my $X;
my $Y;
my $Z;

open (RINEX,"<$ARGV[0]" ) || die "RINEX Datei nicht gefunden\n";

while(<RINEX>)
 {
  push(@Zeilen,$_);
 }
close(RINEX);
for(@Zeilen)
 {
####################  Excentricities         
  if(/ANTENNA:/)
   { 
    ($h_exc, $e_exc, $n_exc) = GET_EXCENT ();
   }
####################  Antenna  Informationen
  elsif (/ANT # /)
   { 

    ($ant_numb, $ant_type, $ant_cone) = GET_ANT_TYP()
   }
####################  Receiver Informationen
  elsif (/REC/)
   { 
   ($rec_numb, $rec_type, $rec_vers) = GET_REC_TYP()
   }
####################  Coordinate Informationen
  elsif (/XYZ/)
   { 
    ($X, $Y, $Z) = GET_POS_XYZ()
   }
####################  MARKER Name             
  elsif (/MARKER\ NAME/)
   { 
    $mark_name = GET_MARK_NAME()
   }
####################  MARKER Number           
  elsif (/MARKER\ NUMB/)
   { 
    $mark_number = GET_MARK_NUMBER()
   }
  }

close(RINEX);                   

#
#  Output
#
#print "$mark_name\n";
#print "$mark_number\n";
#print "$h_exc, $e_exc, $n_exc\n";
#print "$ant_numb, $ant_type, $ant_cone\n";
#print "$rec_numb, $rec_type, $rec_vers\n";
#print "$X, $Y, $Z\n";                         
print "$mark_name $mark_number $X $Y $Z\n";


############################################
#
#   Subroutines 
#
###########################################

sub GET_EXCENT  {
# print "Unterprogramm GET_EXCENT\n";
# print $_;
 my $exc_h = substr $_,0,14;
 my $exc_e = substr $_,14,14;
 my $exc_n = substr $_,28,14;
#
## fuehrende Leerzeichen entfernen
#

 $exc_h =~ s/^\s+//;
 $exc_e =~ s/^\s+//;
 $exc_n =~ s/^\s+//;

#   print "$exc_h $exc_e $exc_n \n";

 return($exc_h, $exc_e, $exc_n);
}

sub GET_ANT_TYP {

#  print "Unterprogramm GET_ANT_TYP\n";

 my $ant_numb = substr $_,0,20;
 my $ant_type_cone = substr $_,20,20;
 my $ant_type = substr $ant_type_cone,0,16;
 my $ant_cone = substr $ant_type_cone,16,4;
#
### Leerzeichen entfernen
#
 $ant_numb =~ s/\s+$//;
 $ant_type =~ s/\s+$//;
 $ant_cone =~ s/\s+$//;
#
#
#
my $check_cone  = length($ant_cone);
#print " $check_cone      \n";
if ($check_cone == 0) {
#    print "No RAD-CODE given \n";
    $ant_cone = "UNKN"
}

#####
#  print $_;
#  print "$ant_numb $ant_type $ant_cone \n";
 return ($ant_numb, $ant_type, $ant_cone);
}

sub GET_REC_TYP {

#  print "Unterprogramm GET_REC_TYP\n";
#  print $_;

 my $rec_numb = substr $_,0, 20;
 my $rec_type = substr $_,20, 20;
 my $rec_vers = substr $_,40, 20;

### hintere Leerzeichen entfernen

# print "$rec_numb $rec_type $rec_vers\n";
 $rec_numb =~ s/\s+$//;
 $rec_type =~ s/\s+$//;
 $rec_vers =~ s/\s+$//;

#  print "$rec_numb $rec_type $rec_vers\n";

 return ($rec_numb, $rec_type, $rec_vers);
}

sub GET_POS_XYZ {

#  print "Unterprogramm GET_POS_XYZ\n";
#  print $_;

 my $X = substr $_, 0, 14;
 my $Y = substr $_, 14, 14;
 my $Z = substr $_, 28, 14;
 $X =~ s/^\s+//;
 $Y =~ s/^\s+//;
 $Z =~ s/^\s+//;

#  print "$X $Y $Z \n";

 return ($X,$Y,$Z)
}

sub GET_MARK_NAME {


#  print "Unterprogramm GET_MARK_NAME\n";
#  print $_;

 my $mark_name = substr $_, 0, 60;
 $mark_name =~ s/\s+$//;

#  print "$mark_name $mark_name\n";

 return($mark_name);
}

sub GET_MARK_NUMBER {

#  print "Unterprogramm GET_MARK_NUMBER\n";
#  print $_;

 my $mark_number = substr $_, 0, 60;
 $mark_number =~ s/\s+$//;

#  print "$mark_number $mark_number\n";

 return($mark_number);
}

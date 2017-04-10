#!/usr/bin/perl -w
#
# Script:  mean_amb.pl
#
# Purpose: Compute the session-mean percentage of resolved ambiguities for GPS,
#          GLONASS, and GPS+GLONASS, using BSW 5.2 BPE summary files (PRC-files)
#          created by RNX2SNX.PCF process.
#          The results are written to standard output.
#
# Usage:   mean_amb.pl sum_files.PRC
#          mean_amb.pl sum_files.PRC > outfile 2>errfile
#          mean_amb.pl [-h]
#
#          Wildcard characters are allowed. E.g., the following command:
#             mean_amb.pl */OUT/R2S*.PRC > mean_amb.out
#          may be executed in the directory where the campaign results
#          are stored (in SAVEDISK area ${S}/{V_RESULT}/).
#
# Created: 29.11.2015
# Author:  T. Liwosz
#
# Changes:
#
 use strict;

 if (@ARGV == 0 or $ARGV[0] eq '-h'){
    print "\n  Usage:\n\n",
          "    mean_amb.pl sum_files.PRC\n",
          "    mean_amb.pl sum_files.PRC > outfile 2>errfile\n",
          "    mean_amb.pl [-h]\n\n",
          "  Wildcard characters are allowed. E.g., the following command:\n\n",
          "    mean_amb.pl */OUT/R2S*.PRC > mean_amb.out\n\n",
          "  may be executed in the directory where the campaign results\n",
          "  are stored (in SAVEDISK area \${S}/{V_RESULT}/).\n\n";
    exit;
 }

 print "!Year/Sess   Res_GPS  Res_GLO  Res_GNSS\n",
       "!              (%)      (%)      (%)   \n",
       "!--------------------------------------\n";

 FILE: foreach my $prcFile (@ARGV){
     my %ambig;

     if (! -e $prcFile){
         print STDERR "$prcFile: PRC file not found.\n";
         next;
     }

     my $yy;
     my $sess;

     open(PRC, '<', $prcFile);

     my $head = 0;

     while (my $line = <PRC>){
        if ($line =~ /^RNX2SNX BPE PROCESSING SUMMARY FOR YEAR-SESSION (\d\d)-(\d{4})$/){
            $yy   = $1;
            $sess = $2;
            $head++;
        }
        if ($line =~ /^Ambiguity resolution options from PCF:$/){
            $head++;
            last;
        }
     }

     if ($head < 2){
         print STDERR "$prcFile: Not valid BSW 5.2 BPE summary file! File skipped.\n";
         next;
     }

     my $ar_nl = 0;
     my $ar_l3 = 0;

     while (my $line = <PRC>){

        if ($line =~ /^ Code-Based Narrowlane \(NL\) Ambiguity/){
            $ar_nl = 1;
        }
# Read code-based narrowlane results (scale no. of ambiguities to 2 frequencies)
        if ($line =~ /^ \w{4}${sess} / and $line =~ /#AR_NL/){
            my $baseline = substr($line, 10, 9);
            my $sys      = substr($line, 59, 2);
            if ($sys eq '  ' or $sys eq 'GR'){ next }
            $ambig{$baseline}{$sys}{'NUM'} = substr($line, 31, 5) * 2;
            $ambig{$baseline}{$sys}{'UNR'} = substr($line, 42, 5) * 2;
        }

        if ($line =~ /^ Phase-Based Narrowlane \(L3\) Ambiguity/){
            $ar_l3 = 1;
        }
# Read phase-based narrowlane results (scale no. of ambiguities to 2 frequencies)
        if ($line =~ /^ \w{4}${sess} / and $line =~ /#AR_L3/){
            my $baseline = substr($line, 10, 9);
            my $sys      = substr($line, 59, 2);
            if ($sys eq '  ' or $sys eq 'GR'){ next }
            $ambig{$baseline}{$sys}{'NUM'} = substr($line, 31, 5) * 2;
            $ambig{$baseline}{$sys}{'UNR'} = substr($line, 42, 5) * 2;
        }

        if ($line =~ /^ Quasi-Ionosphere-Free \(QIF\) Ambiguity/){
            if ($ar_nl == 0 or $ar_l3 == 0){
                print STDERR "$prcFile: code/phase based L5/L3 ambiguity results",
                             " not found before QIF. File skipped.\n";
                next FILE;
            }
        }

# Read QIF results, and update previous WL/NL and L5/L3 results (if present)
        if ($line =~ /^ \w{4}${sess} / and $line =~ /#AR_QIF/){
            my $baseline = substr($line, 10, 9);
            my $sys      = substr($line, 59, 2);
            if ($sys eq '  ' or $sys eq 'GR'){ next }
            if (defined $ambig{$baseline}{$sys}){
                $ambig{$baseline}{$sys}{'UNR'} = substr($line, 42, 5);
            }
            else{
                $ambig{$baseline}{$sys}{'NUM'} = substr($line, 31, 5);
                $ambig{$baseline}{$sys}{'UNR'} = substr($line, 42, 5);
            }
        }

# Read L12 results
        if ($line =~ /^ \w{4}${sess} / and $line =~ /#AR_L12/){
            my $baseline = substr($line, 10, 9);
            my $sys      = substr($line, 59, 2);
            if ($sys eq '  ' or $sys eq 'GR'){ next }
            $ambig{$baseline}{$sys}{'NUM'} = substr($line, 31, 5);
            $ambig{$baseline}{$sys}{'UNR'} = substr($line, 42, 5);
        }

        if ($line =~ /PART 7: GNSS COORDINATE/){
           last;
        }
     }
     close(PRC);

     my $numGps = 0;
     my $unrGps = 0;

     my $numGlo = 0;
     my $unrGlo = 0;

     my $numAll = 0;
     my $unrAll = 0;

     foreach my $key (keys %ambig){
         $numGps += $ambig{$key}{'G '}{'NUM'} if defined $ambig{$key}{'G '}{'NUM'};
         $numGlo += $ambig{$key}{' R'}{'NUM'} if defined $ambig{$key}{' R'}{'NUM'};
         $unrGps += $ambig{$key}{'G '}{'UNR'} if defined $ambig{$key}{'G '}{'UNR'};
         $unrGlo += $ambig{$key}{' R'}{'UNR'} if defined $ambig{$key}{' R'}{'UNR'};
     }

     $numAll = $numGps + $numGlo;
     $unrAll = $unrGps + $unrGlo;

     my $gpsAmb = '---';
     my $gloAmb = '---';
     my $allAmb = '---';

     if ($numGps > 0){ $gpsAmb = sprintf "%5.1f", (1-$unrGps/$numGps)*100 }
     if ($numGlo > 0){ $gloAmb = sprintf "%5.1f", (1-$unrGlo/$numGlo)*100 }
     if ($numAll > 0){ $allAmb = sprintf "%5.1f", (1-$unrAll/$numAll)*100 }

     my $yyyy = $yy + 2000;
     if ($yy > 80){ $yyyy = $yy + 1900 }

     printf " %4i/%04i   %5s    %5s    %5s\n", $yyyy, $sess, $gpsAmb, $gloAmb, $allAmb;
 }

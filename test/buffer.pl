#!/usr/bin/env perl

###############################################################################
#                                                                             #
#            Test case framework for validating input arguments               #
#                                                                             #
###############################################################################

use strict;
use warnings;

use File::Spec;

#
# specify the path to pccp.pl on command line.
#  ..or use the default ("../src/pccp.pl")
#
our $PCCP_PATH = (shift) || File::Spec->catfile(('..', 'src'), 'pccp.pl');

#
# redirect pccp.pl's writes from STDERR to STDOUT, which is only a 
#  convenience for paging output with e.g. `less' or `more'
#
our $REDIR_ERR = 1; 

my $BF = "fb";

sub dotest
{    
  my ($i, $n, $m) = @_;

  my $FS = File::Spec->catdir('.', $BF);
  my $FP = File::Spec->catfile(File::Spec->splitdir($FS), sprintf "source-%d-byte.file", $n);
  my $TP = File::Spec->catfile(File::Spec->splitdir($FS), sprintf "target-%d-byte.file", $n);

  printf "TEST %d (%d bytes, %d iterations):$/$/", $i, $n, $m;

  print `rm -rf \"$FS\"$/`;
  print `mkdir -p \"$FS\"$/`;

  my $tch = "dd if=\"/dev/urandom\" of=\"$FP\" count=$n bs=1";
  my $cmd = "perl \"$PCCP_PATH\" -f -t $m $FP $TP";

  $tch = "$tch 2>&1" if $REDIR_ERR;
  $cmd = "$cmd 2>&1" if $REDIR_ERR;

  print `$tch`;
  print `$cmd`;

  print $/, $/;

  print `rm -rf \"$FS\"$/`;
}    

print "#" x 100, $/, $/;

my $testcount = 0;

dotest(++$testcount,     1024 * 1024, 50);
dotest(++$testcount,   185363 * 1024, 40);
dotest(++$testcount,  5931641 * 1024, 30);
dotest(++$testcount, 33554432 * 1024, 20);

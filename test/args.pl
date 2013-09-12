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

my $SF_1  = "sf-1";
my $SF_2  = "sf-2";
my $SD_1  = "sd-1";
my $SD_2  = "sd-2";
my $TF    = "tf";
my $TD    = "td";
my $BF    = "fs";

my $FN    = 0;
my $FE    = 1;
my $DN    = 2;
my $DE    = 3;

my @FSTATSTR = qw| no-file file no-dir dir |;

sub dotest
{    
  my $n = shift @_;
  my @f = @_;    
  my @a = ();

  my $FS = File::Spec->catdir(('.', $BF), sprintf "%03d", $n);

  my $s = "TEST $n: ";
  for (0 .. (@f / 2) - 1)
  {
    $s .= sprintf "%s [%s] ", 
    $f[2*$_], $FSTATSTR[$f[2*$_+1]];
  }
  print $s, $/;

  print `rm -rf \"$FS\"$/`;
  print `mkdir -p \"$FS\"$/`;

  for (0 .. (@f / 2) - 1)
  {
    my $f = $FS . "/" . $f[2*$_];
    my $e = $f[2*$_+1];

    push @a, "\"$f\"";

    if ($e == 1)
    {
      print `touch \"$f\"$/`;
    }
    elsif ($e == 3)
    {
      print `mkdir \"$f\"$/`;
    }
  }

  my $cmd = "perl \"$PCCP_PATH\" -vvf @a";

  $cmd = "$cmd 2>&1" if $REDIR_ERR;

  print `$cmd`;

  print $/, $/;
}    


print `rm -rf \"$BF\"$/`;
print "#" x 100, $/, $/;

my $testcount = 0;

@_ = split /\s+/, "$SF_1    $FE    $TF      $FE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $TD      $DE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $TF      $FN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $TD      $DN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FN    $TF      $FE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FN    $TD      $DE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FN    $TF      $FN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FN    $TD      $DN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TF    $FE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TF    $FN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TD    $DN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TF    $FE"  ; dotest(++$testcount, @_); 
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TF    $FN"  ; dotest(++$testcount, @_); 
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TD    $DN"  ; dotest(++$testcount, @_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TF    $FE"  ; dotest(++$testcount, @_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TF    $FN"  ; dotest(++$testcount, @_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TD    $DN"  ; dotest(++$testcount, @_); 



@_ = split /\s+/, "$SD_1    $DE    $TF      $FE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $TD      $DE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $TF      $FN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $TD      $DN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $TF      $FE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $TD      $DE"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $TF      $FN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $TD      $DN"                ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TF    $FE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TF    $FN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TD    $DN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TF    $FE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TF    $FN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TD    $DN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TF    $FE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TD    $DE"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TF    $FN"  ; dotest(++$testcount, @_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TD    $DN"  ; dotest(++$testcount, @_);

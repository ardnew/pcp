#!/usr/bin/env perl

###############################################################################
#                                                                             #
#            Test case framework for validating input arguments               #
#                                                                             #
###############################################################################

use strict;
use warnings;

my $SF_1  = "sf-1";
my $SF_2  = "sf-2";
my $SD_1  = "sd-1";
my $SD_2  = "sd-2";
my $TF    = "tf";
my $TD    = "td";
my $FS    = "fs";

my $FN    = 0;
my $FE    = 1;
my $DN    = 2;
my $DE    = 3;

my @FSTATSTR = qw| no-file file no-dir dir |;

sub dotest
{    
	my @f = @_;    
	my @a = ();

	my $s = "TEST: ";
	for (0 .. (@f / 2) - 1)
	{
		$s .= sprintf "%s [%s] ", 
				$f[2*$_], $FSTATSTR[$f[2*$_+1]];
	}
	print $s, $/;

	print `rm -rf \"$FS\"$/`;
	print `mkdir \"$FS\"$/`;
	
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

	print `perl ../src/pccp.pl -vv @a$/`;

	print $/, $/;

	print `rm -rf \"$FS\"$/`;
}    


print "#" x 100, $/, $/;


@_ = split /\s+/, "$SF_1    $FE    $TF      $FE"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $TD      $DE"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $TF      $FN"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $TD      $DN"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FN    $TF      $FE"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FN    $TD      $DE"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FN    $TF      $FN"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FN    $TD      $DN"                ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TF    $FE"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TF    $FN"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FE    $TD    $DN"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TF    $FE"  ; dotest(@_); 
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TF    $FN"  ; dotest(@_); 
@_ = split /\s+/, "$SF_1    $FE    $SF_2    $FN    $TD    $DN"  ; dotest(@_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TF    $FE"  ; dotest(@_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TF    $FN"  ; dotest(@_); 
@_ = split /\s+/, "$SF_1    $FN    $SF_2    $FE    $TD    $DN"  ; dotest(@_); 



@_ = split /\s+/, "$SD_1    $DE    $TF      $FE"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $TD      $DE"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $TF      $FN"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $TD      $DN"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $TF      $FE"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $TD      $DE"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $TF      $FN"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $TD      $DN"                ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TF    $FE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TF    $FN"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FE    $TD    $DN"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TF    $FE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TF    $FN"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DE    $SD_2    $FN    $TD    $DN"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TF    $FE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TD    $DE"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TF    $FN"  ; dotest(@_);
@_ = split /\s+/, "$SD_1    $DN    $SD_2    $FE    $TD    $DN"  ; dotest(@_);
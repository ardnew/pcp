#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Path;
use File::Spec;

die sprintf "usage:$/    %s <%s>$/", $0, "version-id" unless @ARGV > 0;

my $scriptdir = 
  dirname(File::Spec->rel2abs(__FILE__));

my $resultdir = 
  File::Spec->catdir(dirname($scriptdir), "pcp-" . $ARGV[0]);

my $timestamp = `date "+%m/%d/%Y %R:%S %Z"`; chomp $timestamp;

#die "cannot create directory: $resultdir: file or directory already exists$/"
#  if -e $resultdir;

mkpath($resultdir);

my @distfiles = map { File::Spec->catfile($scriptdir, @$_) }
(
  [qw| LICENSE      |], # one array reference for each source file:
  [qw| README.md    |], #   the last element in the array reference is the file name,
  [qw| src pcp      |], #   and all preceding elements are directories to that file.
);

foreach my $fn (@distfiles)
{
  my $source = $fn;
  my $target = File::Spec->catfile($resultdir, basename($fn));

  #print "$source -> $target$/";

  my ($if, $of) = (undef, undef);

  open $if, '<', $source or die "open for read: $target: $!$/";
  open $of, '>', $target or die "open for write: $target: $!$/";
  
  while (<$if>)
  {
    s/__PCPVERS__/$ARGV[0]/g;
    s/__PCPDATE__/$timestamp/g;
    print $of $_;
  }

  close $of;
  close $if;
}

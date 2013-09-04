#!/usr/bin/env perl

###############################################################################
#                                                                             #
#            This is a general-usage demo of the File::Find module            #
#                                                                             #
###############################################################################

use strict;
use warnings;

use Cwd "realpath";
use File::Find;

our $PADWIDTH = 2;

my @statlist = 
(
  'dev', # device number of filesystem
  'ino', # inode number
  'mod', # file mode (type and permissions)
  'nhl', # number of (hard) links to the file
  'uid', # numeric user ID of file's owner
  'gid', # numeric group ID of file's owner
  'did', # device identifier (special files only)
  'siz', # total size of file in bytes
  'act', # last access time in seconds since epoch
  'mdt', # last modify time in seconds since epoch
  'cgt', # inode change time in seconds since epoch
  'bsz', # preferred I/O size in bytes
  'blk', # actual number of blocks allocated
);
my %statname = map { $_ => $.++ } @statlist;

sub printpair($$$) { printf "%*s => %s$/", $_[0] + $PADWIDTH, $_[1], $_[2] }
sub printhash($$)
{
  my (%hash, @sort, $long);

  %hash = %{(shift)}; $_ = shift; @sort = (ref) ? @{$_} : ();

  $long = 0; $long < length && ($long = length) for keys %hash;

  if (@sort == keys %hash) { printpair $long, $_, $hash{$_} foreach @sort; }
                      else { printpair $long, $_[0], $_[1] while @_ = each %hash; }
}

sub wantfile ($)
{
  my $filepath = shift;

  return 1;
}

sub proc
{
  my $filepath = $File::Find::name;
  my $dircpath = $File::Find::dir;

  my @stat = (stat _);

  my %filestat = map { $statlist[$_] => $stat[$_] } 0 .. $#stat;

  if (wantfile $filepath)
  {
    print "filepath = $filepath" . ($filepath eq $dircpath ? " (root)$/" : $/);
    print "dircpath = $dircpath$/";
    print $/;
  }
}

sub walk
{
  my %option = 
  (
    wanted       => \&proc,
    follow       => 0,
    follow_skip  => 0,
    no_chdir     => 1,
  ); 

  find(\%option, (shift));
}

walk(realpath(shift @ARGV || "."));

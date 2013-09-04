#!/usr/bin/env perl

use strict;
use warnings;


####[ globals ]###########################################################################


our $RETOK = 0; # return value: no errors
our $RETER = 1; # return value: error

our $FTYPE = 0;
our $DTYPE = 1;


####[ constants ]#########################################################################


my %required_module =
(
  'Pod::Usage'      => [ qw[] ],
  'Getopt::Long'    => [ qw[] ],
  'Cwd'             => [ qw[ realpath ] ],  
  'File::Find'      => [ qw[] ],
);

my %optional_module =
(
  'File::Spec'      => [ qw[] ],
  'Term::ReadKey'   => [ qw[] ],
);

my %option =
(
  c_cksum => [ qw[              checksum|c|s      0 ] ], # 0 is "default value"
  f_force => [ qw[                   force|f      0 ] ],
  h_usage => [ qw[ usage|help|what|wat|u|h|?      0 ] ],
  m_manpg => [ qw[             manpage|man|m      0 ] ],
  p_progr => [ qw[                progress|p      0 ] ],
  r_recur => [ qw[                 recurse|r=i   -1 ] ],
  v_debug => [ qw[         debug|verbose|d|v+     0 ] ],
);

my %pod =
(
  usage    => 1,
  manpage  => 2,
);


####[ forward declarations ]##############################################################


#
# arg1: error level for message to print (and program return code)
# arg2: message to print to STDOUT/STDERR
#
sub print_error ($$);

#
# arg1: modules in arg2 are required (no = 0, yes = 1)
# arg2: hash reference with structure { 'Module::Name' => [ "symbols", "to", "import" ] }
#
sub load_modules ($$);

#
# calls Getopt::Long::GetOptions with reference to above %option hash, and replaces the
# hash value (the array reference) with the result of GetOptions's parsing
#
# example:
#
#   after the call to parse_options, you can get the parsed debug option value:
#
#     $option{v_debug}
#
#   you will NOT have to (de-)reference the array:
#
#     ${$option{v_debug}}[1]
#
sub parse_options ($);

#
# runs pod2usage with the specified level of detail
#
# arg1: program return code
# arg2: POD detail level. see %pod hash above for options
#
sub pod ($$);

#
# accepts as input a list of length at least 2. the last element of the list is 
# interpreted as TARGET, and all preceding elements are SOURCE
#
# if more than 1 SOURCE exists, TARGET must be a directory. otherwise, both may be
# either a file or a directory
#
# on success, returns a list whose first element is TARGET, second element is the file 
# type of TARGET (FTYPE = file, DTYPE = directory), and each following element
# is the absolute path to a SOURCE. it is guaranteed that all SOURCE and TARGET elements 
# are accessible with all necessary permisions on the filesystem.
#
# on failure, prints an error message and stops program execution 
#
sub parse_filenames (@);


####[ main line ]#########################################################################


load_modules 1, \%required_module;
load_modules 0, \%optional_module;

parse_options \%option;

if ($option{v_debug} > 1)
{
  printf "command-line options:$/";
  while (my ($k, $v) = each %option) 
  { 
    printf "%9s = %-s$/", $k, $v; 
  }
  printf "%9s = (%-s)$/$/", 'args', join(', ', @ARGV);
}

pod $RETOK, "manpage" if $option{m_manpg};
pod $RETOK, "usage" if $option{h_usage} or @ARGV < 2;

my ($target, $fdtype, @source) = parse_filenames @ARGV;

if ($option{v_debug} > 1)
{
  printf "source files:$/  %s$/$/", join("$/  ", @source);
    
  printf "target %s:$/  %s%s$/$/", 
    $fdtype ? "directory" : "file", $target, -e $target ? "" : " (new)";
}

exit $RETOK;


####[ subroutines ]#######################################################################


sub print_error ($$)
{
  my ($ret, $msg) = @_;

  if ($ret == $RETOK)
  {
    printf STDOUT "%s %s$/", "[ warning ]", $msg;
  }
  elsif ($ret == $RETER)
  {
    printf STDOUT "%s %s$/", "[  error  ]", $msg;
    exit $ret;
  }
  else
  {
    printf STDOUT "[%s] %s$/", $0, $msg;
  }
}

sub load_modules ($$)
{
  my ($msg, $req, %mod) = (undef, shift, %{(shift)});

  while (my ($mod, @imp) = map { (ref) ? @{$_} : $_ } each %mod)
  {
    if (eval "require $mod; 1")
    {
      foreach (@imp)
      {
        $msg = "export not found: \"$mod\:\:$_\"" and last
          unless eval "$mod->import('$_'); 1";
      }
    }
    else
    {
      $msg = "module not found: \"$mod\"";
    }

    ( sub { print_error $RETOK, shift },
      sub { print_error $RETER, shift },)[$req]->($msg) if defined $msg;
  }
}

sub parse_options ($)
{
  my $opt = shift;

  Getopt::Long::Configure('bundling');

  # override SIGWARN to make Getopt shut up
  {
    local $SIG{__WARN__} = sub { };

    Getopt::Long::GetOptions
    (
      eval join ',',
        map 
        { 
          '${$$opt{'.$_.'}}[0] => \${$$opt{'.$_.'}}[1]' 
        } 
        keys %{$opt}
    )
    or print_error $RETER, 'wat? see --usage for more information';
  }

  $$opt{$_} = ${$$opt{$_}}[1] for keys %{$opt};
}

sub pod ($$)
{
  Pod::Usage::pod2usage
  ({ 
    -exitval => $_[0], 
    -verbose => $pod{$_[1]}, 
  }) 
  if defined $pod{$_[1]};
}

sub parse_filenames (@)
{
  print_error $RETER, "required source and target files not provided" 
    unless @_ > 1;

  my ($target, $fdtype, @source, %unique) = pop @_;

  foreach (@_)
  {
    print_error $RETOK, "no such file or directory: $_" and next 
      unless -e;

    if (-f) 
    {    
      if (-r) { $unique{$_} = undef }
         else { print_error $RETOK, "cannot read file: $_"; } 
    } 
    elsif (-d) 
    { 
      if (-r) { $unique{$_} = undef }
         else { print_error $RETOK, "cannot read directory: $_"; } 
    }       
    else 
    { 
      print_error $RETOK, "unknown file type: $_"; 
    }
  }

  @source = keys %unique;

  $fdtype = ($FTYPE, $DTYPE)[@_ > 1 || -d $target || (grep { -d } @source) > 0];

  print_error $RETER, "no valid source files provided" 
    unless @source;

  print_error $RETER, "target must be a directory when copying a directory or more than one file" 
    if $fdtype == $DTYPE and -f $target;

  return $target, $fdtype, @source;
}


__END__


####[ POD ]###############################################################################

=head1 NAME

=over 4

=item B<pccp> -- Copy files and directories with optional progress indicator

=back

=head1 SYNOPSIS

B<pccp> [ options ] [ B<-?cdfhmpsuv> ] F<source-file> F<target-file>

B<pccp> [ options ] [ B<-?cdfhmpsuv> ] F<source-file(s)> F<target-directory>

=head1 DESCRIPTION

B<pccp> will perform a block-level copy on a set of files or directories from one location to another, and it can display a real-time progress indicator with checksum details of the resulting copy operation.

The program does not currently support asynchronous I/O, so copy operations from one disk to another may be painfully slow.

=head1 OPTIONS

=over 8

=item B<--checksum>, B<-c>, B<-s>

Print checksum of source file and resulting copied file

=item B<--force>, B<-f>

Force copy even if destination file already exists

=item B<--help>, B<--usage>, B<--wat>, B<-h>, B<-u>, B<-w>, B<-?>

Print synopsis and options to STDOUT and exit

=item B<--manpage>, B<-m>

Display the manual page and exit

=item B<--progress>, B<-p>

Use visual indicator to show progress of copy operation

=item B<--recurse> F<depth>, B<-r> F<depth>

When copying a directory, do not copy files more than F<depth> levels deep

=item B<--debug>, B<--verbose>, B<-d>, B<-v>

Print verbose debug information (additional flags increases detail)

=back

=cut

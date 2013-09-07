#!/usr/bin/env perl

use strict;
use warnings;


####[ globals ]###########################################################################


our $NOTIC = 0; # "notice" message level
our $WARNG = 1; # "warning"
our $ERROR = 2; # "error"

our $FTYPE = 0; # "file"
our $DTYPE = 1; # "directory"

our $OPTMO = 0; # optional module
our $REQMO = 1; # required module

our $ALLOK = 0; # good
our $ONOES = 1; # bad


####[ constants ]#########################################################################


my %bootstrp_module = # these modules are needed for bootstrapping other features
(
  'Getopt::Long'    => [ qw[] ],
  'Pod::Usage'      => [ qw[] ],  
);

my %required_module =
(
  'File::Find'      => [ qw[] ],
  'File::Path'      => [ qw[] ],
  'File::Spec'      => [ qw[] ],
  'File::Copy'      => [ qw[] ],
);

my %optional_module =
(
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
# initializes the program by pre-loading some modules and parsing command line options
#
sub init;

#
# print a list of messages based on increasing numeric importance level:
#   
#   $NOTIC: print a notice to STDOUT (if -v set) and continue program execution
#   $WARNG: print a warning to STDERR and continue program execution
#   $ERROR: print an error to STDERR and exit program with error code $ONOES
#
# arg1: message importance level
# arg2: list of messages to print
#
sub print_message ($@);

#
# attempt to import external Perl modules
#
#   if the module is required and not found, exit program
#   if the module is optional and not found, continue program
#
# for optional modules not found, the corresponding key is deleted from the module hash
# to allow the program to check if it was successfully imported or not:
#
#   exists $module{'Module::Name'} == module loaded
#
# arg1: modules in arg2 are required (no = $OPTMO, yes = $REQMO)
# arg2: hash reference with structure { 'Module::Name' => [ "symbols", "to", "import" ] }
#
sub load_modules ($$);

#
# prints the contents of a module hash. if called after sub load_modules ($$), then
# only the successfully loaded modules will exist and be printed
#
# arg1: modules in arg2 are required (no = $OPTMO, yes = $REQMO)
# arg2: name of the module group, use undef for none
# arg3: hash reference with structure { 'Module::Name' => [ "symbols", "to", "import" ] }
#
sub show_modules ($$$);

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
# runs pod2usage showing the specified sections and then exits program
#
# arg1: program return code
# arg2: display sections (see %pod hash definition for options)
#
sub pod ($$);

#
# accepts as input a list of length at least 2. the first element of the list is 
# interpreted as TARGET, and all succeding elements are SOURCE
#
# if more than 1 SOURCE exists, TARGET must be a directory. otherwise, both may be
# either a file or a directory
#
# on success, returns a list whose first element is TARGET, second element is the file 
# type of TARGET ($FTYPE = file, $DTYPE = directory), and each following element is a
# SOURCE. 
#
# on failure, prints an error message and stops program execution 
#
# NOTE: absolute path resolution is performed on all existing SOURCE files, and it is 
#       guaranteed they all have the necessary permissions for reading.
#
# NOTE: however, no absolute path resolution is performed on TARGET, and no check is
#       performed to verify TARGET may be created or written to (see: sub copy_file).
#
sub parse_filenames (@);

#
# arg1: source file
# arg2: target file
# arg3: target file type
#
sub copy_file ($$$);


####[ main line ]#########################################################################


init;

load_modules $REQMO, \%required_module;
load_modules $OPTMO, \%optional_module;

pod $ALLOK, "manpage" if $option{m_manpg};
pod $ALLOK, "usage" if $option{h_usage};

my ($target, $fdtype, @source) = parse_filenames reverse @ARGV;

for my $path (@source)
{
  print_message $WARNG, "$path: directory copy not implemented (ignoring)" and next
    if -d $path;

    copy_file($path, $target, $fdtype);
}

exit $ALLOK;


####[ subroutines ]#######################################################################


sub init
{
  load_modules 1, \%bootstrp_module;
  parse_options \%option;
}

sub print_message ($@)
{
  my ($ret, @msg) = @_;

  if ($ret == $NOTIC)
  {
    printf STDOUT "%s$/  %s$/$/", "notice:", join "$/  ", @msg
      if $option{v_debug};
  }
  elsif ($ret == $WARNG)
  {
    printf STDERR "%s$/  %s$/$/", "warning:", join "$/  ", @msg; 
  }
  elsif ($ret == $ERROR)
  {
    printf STDERR "%s$/  %s$/$/", "error:", join "$/  ", @msg;
    exit $ONOES;
  }
  else
  {
    printf STDERR "[%s]$/  %s$/$/", $0, join "$/  ", @msg;
  }
}

sub load_modules ($$)
{
  my ($msg, $req, $mod) = (undef, shift, shift);

  while (my ($pkg, @sym) = map { (ref) ? @{$_} : $_ } each %{$mod})
  {
    if (eval "require $pkg; 1")
    {
      foreach (@sym)
      {
        $msg = "export not found: $pkg\:\:$_" and last
          unless eval "$pkg->import('$_'); 1";
      }
    }
    else
    {
      $msg = "module not found: $pkg";
    }

    if (defined $msg)
    {
      delete $$mod{$pkg} if $req == $OPTMO;

      ( sub { print_message $NOTIC, shift },
        sub { print_message $ERROR, shift }, )[$req == $REQMO]->($msg);
    }
  }
}

sub show_modules ($$$)
{
  my ($req, $gid, %mod) = (shift, shift, %{(shift)});

  my $wid = 0;
  (length > $wid) && ($wid = length) for keys %mod;

  printf "%s %smodules:$/", 
    $req == $REQMO ? "required" : "optional",
    defined $gid ? $gid . " " : ""; 
  
  printf "  %${wid}s$/$/", "none" and return unless keys %mod > 0;

  while (my ($pkg, @sym) = map { (ref) ? @{$_} : $_ } each %mod)
  {
    printf "  %${wid}s => [%s]$/", $pkg, @sym ? " @sym " : "";
  }
  print $/;
}

sub parse_options ($)
{
  my $opt = shift;

  Getopt::Long::Configure('bundling');

  # override SIGWARN to make Getopt shut up
  {
    local $SIG{__WARN__} = sub { }; # do nothing

    Getopt::Long::GetOptions
    (
      eval join ',',
        map 
        { 
          '${$$opt{'.$_.'}}[0] => \${$$opt{'.$_.'}}[1]' 
        } 
        keys %{$opt}
    )
    or print_message $ERROR, 'wat? see --usage for more information';
  }

  $$opt{$_} = ${$$opt{$_}}[1] for keys %{$opt};

  if ($$opt{v_debug} > 1)
  {
    printf "command-line options:$/";

    while (my ($k, $v) = each %{$opt}) 
    { 
      printf "%9s = %-s$/", $k, $v; 
    }
    printf "%9s = (%-s)$/$/", 'args', join(', ', @ARGV);
  }  
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
  if ($option{v_debug} > 1)
  {
    show_modules $REQMO, "bootstrap", \%bootstrp_module;
    show_modules $REQMO, "feature", \%required_module;
    show_modules $OPTMO, "feature", \%optional_module;
  }
    
  print_message $ERROR, "required source and target files not provided (try --usage)" 
    unless @_ > 1;

  my ($target, @source, $fdtype, %unique) = shift @_;

  %unique = map { $_ => undef } @_;

  foreach (keys %unique)
  {
    print_message $WARNG, "no such file or directory: $_" and next 
      unless -e;

    if (-f) 
    {    
      print_message $WARNG, "cannot read file: $_" and next
        unless -r;
    } 
    elsif (-d) 
    { 
      print_message $WARNG, "cannot read directory: $_" and next
        unless -r;
    }       
    else 
    { 
      print_message $WARNG, "unknown file type: $_" and next;
    }

    push @source, Cwd::realpath($_);
  }

  $fdtype = ($FTYPE, $DTYPE)[ @_ > 1 || -d $target || (grep { -e && -d } @_) > 0 ];

  print_message $ERROR, "no valid source files provided" 
    unless @source;

  print_message $ERROR, "target must be a directory " .
                        "when copying a directory or more than one file" 
    if $fdtype == $DTYPE and -f $target;

  # no more error checking below this line

  if ($option{v_debug} > 1)
  {
    printf "source files:$/  %s$/$/", join("$/  ", @source);
      
    printf "target %s:$/  %s%s$/$/", 
      $fdtype == $DTYPE ? "directory" : "file", $target, -e $target ? "" : " (new)";
  }

  return $target, $fdtype, @source;
}

sub copy_file ($$$)
{
  my ($VOL, $DIR, $FIL) = 0 .. 2;

  my ($source, $target, $fdtype) = @_;
  
  my @source = File::Spec->splitpath($source);
  my @target = File::Spec->splitpath(File::Spec->rel2abs($target));

  if ($fdtype == $DTYPE)
  {
    $target[$DIR] = File::Spec->catdir($target[$DIR], $target[$FIL]);
    $target[$FIL] = $source[$FIL];
  }

  print_message $ERROR, 
    sprintf "invalid path: directory does not exist: $target[$DIR] ".
            "(use --force to create directory)"
      unless -d $target[$DIR] or $option{f_force};

  print_message $ERROR, sprintf "cannot create directory: $target[$DIR]: $!"
    unless -d $target[$DIR] or File::Path::mkpath($target[$DIR]);

  print_message $ERROR, sprintf "invalid path: cannot write to directory: $target[$DIR]"
    unless -w $target[$DIR];

  $source = File::Spec->catpath(@source);
  $target = File::Spec->catpath(@target);

  print_message $ERROR, "cannot copy: file exists: $target (use --force)"
    unless not -f $target or $option{f_force};

  print_message $ERROR, "cannot overwrite file: $target: $!"
    unless not -f $target or unlink $target;  
  
  if ($option{v_debug})
  {
    print_message $NOTIC, sprintf "copy: [ %s ] -> [ %s ]", $source, $target;
  }

  print_message $ERROR, "copy failed: $!"
    unless File::Copy::copy($source, $target);
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


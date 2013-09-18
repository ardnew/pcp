#!/usr/bin/env perl

use strict;
use warnings;


####[ globals ]###########################################################################


our $GINFO = 0; # "general" message level
our $NOTIC = 1; # "notice" (only prints if -v)
our $WARNG = 2; # "warning"
our $ERROR = 3; # "error"

our $FTYPE = 0; # "file"
our $DTYPE = 1; # "directory"

our $OPTMO = 0; # optional module
our $REQMO = 1; # required module

our $ALLOK = 0; # good
our $ONOES = 1; # bad

our $BUFFS = 512000; # default I/O byte buffer size (500 KiB = 512 KB)

our $IOCTL = 'sys/ioctl.ph'; # Perl header file for Term::ReadKey fallback ioctl
our $DEFTW = 60; # default terminal width if Term::ReadKey and ioctl aren't available

our $TRASH = '/dev/null'; # UNIX-only for now


####[ constants ]#########################################################################


my %bootstrp_module = # these modules are needed for bootstrapping other features
(
  'Getopt::Long'    => [ qw[] ],
  'Pod::Usage'      => [ qw[] ],  
);

my %required_module =
(
  'File::Path'      => [ qw[] ],
);

my %optional_module =
(
  'Term::ReadKey'   => [ qw[] ],
  'Benchmark'       => [ qw[ :all ] ],
);

my %option =
(
  b_buffs => [ qw[                     buffer|b=i ],   $BUFFS   ], 
  c_cksum => [ qw[                   checksum|c=s           0 ] ], # 0 is "default value"
  d_depth => [ qw[                      depth|d=i          -1 ] ],  
  f_force => [ qw[                      force|f             0 ] ],
  h_usage => [ qw[    usage|help|what|wat|u|h|?             0 ] ],
  i_inter => [ qw[                interactive|i             0 ] ], 
  m_manpg => [ qw[                manpage|man|m             0 ] ],
  p_progr => [ qw[                   progress|p             0 ] ],
  r_cycle => [ qw[                        crc|r=i           0 ] ],
  s_simul => [ qw[                   simulate|s             0 ] ],
  t_bench => [ qw[                       test|t=i           0 ] ],
  v_debug => [ qw[            debug|verbose|d|v+            0 ] ],
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
# performs some pre-processing for optional modules after options have been parsed
# but before any file processing occurs
#
sub configure;

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
sub parse_filenames (@);

#
# all necessary permissions and directories of TARGET are validated (and created if
# the --force option is enabled).
#
# arg1: target file
# arg2: target file type
# arg3..N: source file list
#
sub prepare_copy ($$@);

#
# performs a block-level copy of one file
#
# arg1: source file counter
# arg2: total number of source files
# arg3: source file
# arg4: target file
# arg5: target file type
# arg6: terminal width (in chars), undef if user did not enable option
#
sub copy_file ($$$$$$);

#
# uses Benchmark module to compare timings of sub copy_file with various buffer sizes
#
# arg1: source file counter
# arg2: total number of source files
# arg3: source file
# arg4: target file
# arg5: target file type
# arg6: terminal width (in chars), undef if user did not enable option
#
sub test_buffers ($$$$$$);

#
# computes the terminal width (in chars) using Term::ReadKey. if Term::ReadKey does not
# exist, then ioctl is used instead. if ioctl is also not found, returns a width = $DEFTW
#
sub get_terminal_width;

#
# arg1: ratio of completion progress
# arg2: terminal width (in chars)
# arg3: filehandle for output
#
sub show_progress ($$$);


####[ main line ]#########################################################################


init;

load_modules $REQMO, \%required_module;
load_modules $OPTMO, \%optional_module;

pod $ALLOK, "manpage" if $option{m_manpg};
pod $ALLOK, "usage" if $option{h_usage};

configure;

my ($target, $fdtype, @source) = parse_filenames reverse @ARGV;

prepare_copy $target, $fdtype, @source;

my ($scount, $stotal) = (0, scalar @source);

my ($termsz) = $option{p_progr} ? get_terminal_width : undef;

for my $srccur (@source)
{
  print_message $WARNG, "$srccur: directory copy not implemented (ignoring)" and next
    if -d $srccur;

  if ($option{t_bench})
  {
    test_buffers($scount, $stotal, $srccur, $target, $fdtype, $termsz)
  }
  else
  {
    copy_file(++$scount, $stotal, $srccur, $target, $fdtype, $termsz);
  }
}

exit $ALLOK;


####[ subroutines ]#######################################################################


sub init
{
  load_modules 1, \%bootstrp_module;
  parse_options \%option;

  print_message $ERROR, "module not found: Benchmark is required for I/O buffer tests"
    unless not $option{t_bench} or exists $optional_module{'Benchmark'};

  print_message $WARNG, "specified buffer too small: $option{b_buffs}: using $BUFFS"
    and $option{b_buffs} = $BUFFS unless $option{b_buffs} > 0;

  print_message $WARNG, "specified buffer too large: $option{b_buffs}: using $BUFFS"
    and $option{b_buffs} = $BUFFS unless $option{b_buffs} < 0x7FFFFFFF; # too big...? 
}

sub print_message ($@)
{
  my ($ret, @msg) = @_;

  if ($ret == $GINFO)
  {
    printf STDOUT "%s$/  %s$/$/", "info:", join "$/  ", @msg; 
  }
  elsif ($ret == $NOTIC)
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

sub configure
{
  print_message $NOTIC, 'using ioctl instead of Term::ReadKey'
    unless not $option{p_progr} or exists $optional_module{'Term::ReadKey'};
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

  $fdtype = ($FTYPE, $DTYPE)[ @_ > 1 
    || (-d $target || $target =~ /\/$/) 
    || (grep { -e && -d } @_) > 0 ];

  print_message $ERROR, "no valid source files provided" 
    unless @source;

  return $target, $fdtype, @source;
}

sub prepare_copy ($$@)
{
  my ($VOL, $DIR, $FIL) = 0 .. 2;

  my ($target, $fdtype, @source, @target) = @_;

  print_message $ERROR, "target must be a directory " .
                        "when copying a directory or more than one file" 
    if $fdtype == $DTYPE and -f $target;

  if ($option{v_debug} > 1)
  {
    printf "source files:$/  %s$/$/", join("$/  ", @source);
      
    printf "target %s:$/  %s%s$/$/", 
      $fdtype == $DTYPE ? "directory" : "file", $target, -e $target ? "" : " (new)";
  }

  print_message $NOTIC, "enabling --force for benchmarking tests"
    if $option{t_bench} and not $option{f_force} and $option{f_force} = 1;

  for my $srccur (@source)
  {
    my $tarcur = $target;

    my @srcdir = File::Spec->splitpath($srccur);
    my @tardir = File::Spec->splitpath(File::Spec->rel2abs($tarcur));

    if ($fdtype == $DTYPE)
    {
      $tardir[$DIR] = File::Spec->catdir($tardir[$DIR], $tardir[$FIL]);
      $tardir[$FIL] = $srcdir[$FIL];
    }

    $srccur = File::Spec->catpath(@srcdir);
    $tarcur = File::Spec->catpath(@tardir);

    my ($srcdir, $tardir) = map { File::Basename::dirname($_) } ($srccur, $tarcur);

    print_message $ERROR, "cannot copy: file exists: $tarcur (use --force)"
      unless not -f $tarcur or $option{f_force};
    print_message $ERROR, "cannot overwrite file: $tarcur: $!"
      unless not -f $tarcur or unlink $tarcur;  

    print_message $ERROR, "cannot copy: file exists: $tardir (use --force)"
      unless not -f $tardir or $option{f_force};
    print_message $ERROR, "cannot overwrite file: $tardir: $!"
      unless not -f $tardir or unlink $tardir;        

    print_message $ERROR, 
      sprintf "invalid path: directory does not exist: $tardir[$DIR] ".
              "(use --force to create directory)"
        unless -d $tardir[$DIR] or $option{f_force};

    print_message $ERROR, sprintf "cannot create directory: $tardir[$DIR]: $!"
      unless -d $tardir[$DIR] or File::Path::mkpath($tardir[$DIR]);

    print_message $ERROR, sprintf "invalid path: cannot write to directory: $tardir[$DIR]"
      unless -w $tardir[$DIR];
  }  
}

sub copy_file ($$$$$$)
{
  my ($scount, $stotal, $source, $target, $fdtype, $termsz) = @_;

  my $cwidth = int(log($stotal) / log(10) + 1); # log10($stotal)+1 = number of digits

  if ($option{s_simul})
  {
    $target = $TRASH;
  }
  else
  {
    if ($fdtype == $DTYPE)
    {
      $target = File::Spec->catfile(File::Spec->splitdir($target), 
                                   (File::Spec->splitpath($source))[2]);
    }
  }

  {
    my $read; # source file "read" handle
    my $writ; # target file "write" handle
    my $buff; # byte buffer

    print_message $ERROR, sprintf "cannot open file for reading: $source: $!"
      unless open $read, '<', $source;
    print_message $ERROR, sprintf "cannot put file in binary mode: $source: $!"
      unless binmode $read;

    print_message $ERROR, sprintf "cannot open file for writing: $target: $!"
      unless open $writ, '>', $target;
    print_message $ERROR, sprintf "cannot put file in binary mode: $target: $!"
      unless binmode $writ;

    my $fsize = $option{t_bench} ? $BUFFS : $option{b_buffs} || $BUFFS;
    my $rsize = -s $read || 1000;
    my $wsize = 0;
    my $width = int(log($rsize) / log(10) + 1);
    my $iters = undef;
    my $cperr = undef; 

    if ($option{t_bench})
    {
      my $tcount = ($scount - 1) % $option{t_bench};

      if ($option{v_debug})
      {
        $iters = sprintf "ITERATION %d / %d", $tcount + 1, $option{t_bench};
      }
      elsif ($tcount == 0)
      {
        $iters = sprintf "ITERATIONS %d", $option{t_bench};
      }

      print_message $GINFO,
        sprintf "[ TEST %*d / %*d | SIZE %*d bytes | BUFFER %d bytes | %s ] %s -> %s",
          $cwidth, $scount, $cwidth, $stotal, $cwidth, $rsize, $fsize, $iters, 
          $source, $target unless not defined $iters;

    }
    elsif ($option{s_simul} or $option{v_debug} )
    {
      print_message $NOTIC, 
        sprintf 
          "[ FILE %*d / %*d | SIZE %*d bytes | BUFFER %d bytes ] %s -> %s", 
        $cwidth, $scount, $cwidth, $stotal, $cwidth, $rsize, $fsize, 
        $source, $target;
    }


    {
      my ($r, $w, $t, $p) = (0, 0, 0, 0);

      $cperr = sprintf "sysread(): cannot read file: $source: $!" and last
        unless defined ($r = sysread $read, $buff, $fsize);

      last unless $r;

      for ($w = 0; $w < $r; $w += $t)
      {
        $cperr = sprintf "syswrite(): cannot write file: $target: $!" and last
          unless $t = syswrite $writ, $buff, $r - $w, $w;

        $wsize += $t;

        $p = $wsize / $rsize;

        if (defined $termsz)
        {
          show_progress($p, $termsz, \*STDOUT);
        }
        else
        {
          if ($option{v_debug} > 2)
          {
            printf "      [ %*d / %*d ] ( %6.2f%% )$/", 
              $width, $wsize, $width, $rsize, $p * 100.0;
          }
        }
      }

      redo;
    }

    select \*STDOUT if defined $termsz;

    if ($wsize > 0)
    {
      if ($option{p_progr}) { print "$/$/" }
                       else { print "$/" if ($option{v_debug} > 2 ) };
    }

    close $writ;
    close $read;

    print_message $ERROR, $cperr if defined $cperr;
  }
}

sub test_buffers ($$$$$$)
{
  my ($scount, $stotal, $source, $target, $fdtype, $evcode, $termsz) = @_;

  # 
  # define which buffers should be tested (in 1 bytes units)
  #
  @_ = 
  (
    #1024 ** 0             ,# 1.00 B   =           1 byte
    #1024 ** 1 / 4         ,# 0.25 KiB =         256
    #1024 ** 1 / 2         ,# 0.50 KiB =         512
    1024 ** 1             ,# 1.00 KiB =        1024
    1024 ** 2 / 4         ,# 0.25 MiB =      262144
    1024 ** 2 / 3.2       ,# 0.31 MiB =      327680
    1024 ** 2 / 2.048     ,# 0.49 MiB =      512000
    1024 ** 2 / 2         ,# 0.50 MiB =      524288
    1024 ** 2 / 1.6       ,# 0.63 MiB =      655360
    1024 ** 2 / 1.31072   ,# 0.76 MiB =      800000
    1024 ** 2 / 1.024     ,# 0.98 MiB =     1024000
    1024 ** 2             ,# 1.00 MiB =     1048576
    #1024 ** 3 / 4         ,# 0.25 GiB =   268435456
    #1024 ** 3 / 2         ,# 0.50 GiB =   536870912
    #1024 ** 3             ,# 1.00 GiB =  1073741824
  );

  $stotal = $stotal * $option{t_bench} * scalar @_; 
  $evcode = "copy_file(++\$scount, $stotal, \"$source\", \"$target\", $fdtype, \$termsz)";

  cmpthese($option{t_bench}, { map {("[ $_ B ]" => "\$BUFFS = $_; $evcode")} @_ });
}

sub get_terminal_width
{
  my ($wchar, $hchar, $wpixl, $hpixl) = (0, 0, 0, 0);

  if (exists $optional_module{'Term::ReadKey'})
  {
    ($wchar, $hchar, $wpixl, $hpixl) = @_ 
      if 0 < scalar (@_ = Term::ReadKey::GetTerminalSize());
  }
  else
  {
    if (eval "require \'$IOCTL\'; 1")
    {
      my $wins =         ''; # buffer for ioctl returned struct
      my $ttyd = '/dev/tty'; # path to default TTY device
      my $ttyh;              # file handle for $ttyd

      print_message $ERROR, "constant TIOCGWINSZ not found in ioctl"
        unless defined &TIOCGWINSZ;

      print_message $ERROR, "cannot open: $ttyd: $!"
        unless open $ttyh, '+<', $ttyd;

      print_message $ERROR, sprintf 'ioctl TIOCGWINSZ (%08x: %s)', &TIOCGWINSZ, $!
        unless ioctl $ttyh, &TIOCGWINSZ, $wins;

      ($wchar, $hchar, $wpixl, $hpixl) = unpack('S4', $wins);      
    }
    else
    {
      print_message $NOTIC, "header not found: \'$IOCTL\'";
      print_message $NOTIC, 'using terminal width of 60 chars';

      $wchar = $DEFTW;
    }
  }

  return $wchar;
}

sub show_progress ($$$)
{
  my ($cr, $tw, $fh) = @_;

  my $cf = select($fh); 
       $_= $|; 
       $|=  1;
       $|= $_;
       select($_);

  my $as = ~~($tw - 16);    # entire space for progress bar (subtract details)
  my $pr = ~~($cr * 100);  # percent complete
  my $ns = $cr * $as;      # symbol count
  my $ni = '*' x $ns;      # progress bar symbols
  my $rs = $as - $ns;      # remaining space for progress bar  

  printf $fh "\r[%-*s] %s", $as, $ni, $pr >= 100 ? "(done)" : "$pr%";
}

__END__


####[ POD ]###############################################################################

=head1 NAME

=over 4

=item B<pccp> -- Copy files and directories with optional progress indicator

=back

=head1 SYNOPSIS

B<pccp> [ options ] [ B<-?bcdfhimprsuv> ] F<source-file> F<target-file>

B<pccp> [ options ] [ B<-?bcdfhimprsuv> ] F<source-file(s)> F<target-directory>

=head1 DESCRIPTION

B<pccp> will perform a block-level copy on a set of files or directories from one location to another, and it can display a real-time progress indicator with checksum details of the resulting copy operation.

The program does not currently support asynchronous I/O, so copy operations from one disk to another may be slower than necessary.

=head1 OPTIONS

=over 8

=item B<--buffer=>F<bytes>, B<-b> F<bytes>

Read and write F<bytes> of data during the copy operation. The default buffer size B<500 KiB> (B<512 KB>).

=item B<--checksum=>F<hash>, B<-c> F<hash>

B<(NOT IMPLEMENTED)> Print checksum of source file and resulting copied file using hash function F<hash>. The following functions are available:

  city = CityHash (32-bit)
  md5  = MD5
  sha  = SHA-1

=item B<--crc=>F<bits>, B<-r> F<bits>

B<(NOT IMPLEMENTED)> Perform a cyclic redundancy check (CRC) with a check value of size F<bits>.

=item B<--depth=>F<depth>, B<-d> F<depth>

B<(NOT IMPLEMENTED)> When copying a directory, do not copy files more than F<depth> levels deep.

=item B<--force>, B<-f>

Force copy even if destination file already exists or if target path (up to target file) does not exist.

=item B<--help>, B<--usage>, B<--wat>, B<-h>, B<-u>, B<-w>, B<-?>

Print synopsis and options to STDOUT and exit.

=item B<--interactive>, B<-i>

B<(NOT IMPLEMENTED)> Before performing each file copy, prompt the user for approval.

=item B<--manpage>, B<-m>

Display the manual page and exit.

=item B<--progress>, B<-p>

B<(NOT IMPLEMENTED)> Use visual indicator to show progress of copy operation.

=item B<--simulate>, B<-s>

Do not actually perform the copy operation, but print to STDOUT the operations that would be performed instead (UNIX: writes to F</dev/null>).

=item B<--test=>F<iterations>, B<-t> F<iterations>

Requires F<Benchmark> (Perl 5 core module). Performs F<iterations> copy operations for each of the following buffer sizes:

     1024 bytes = 1.0 KiB
   262144 bytes
   327680 bytes
   512000 bytes = default
   524288 bytes = 0.5 MiB
   655360 bytes
   800000 bytes
  1024000 bytes
  1048576 bytes = 1.0 MiB

The F<Benchmark> module then prints a nice comparison table.

=item B<--debug>, B<--verbose>, B<-d>, B<-v>

Print verbose debug information (additional flags increases level of detail).

=back

=cut



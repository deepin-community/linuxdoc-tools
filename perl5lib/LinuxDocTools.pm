#! /usr/bin/perl
#
#  LinuxDocTools.pm
#
#  LinuxDoc-Tools driver core. This contains all the basic
#  functionality we need to control all other components.
#
#  Copyright (C) 1996, Cees de Groot.
#  Copyright (C) 2000, Taketoshi Sano
#  Copyright (C) 2006-2020, Agustin Martin
# -------------------------------------------------------------------
package LinuxDocTools;

use 5.006;
use strict;
use LinuxDocTools::Data::Latin1ToSgml qw{ldt_latin1tosgml};

=head1 NAME

LinuxDocTools - SGML conversion utilities for LinuxDoc DTD.

=head1 SYNOPSIS

  use LinuxDocTools;
  LinuxDocTools::init;
  @files = LinuxDocTools::process_options ($0, @ARGV);
  for $curfile (@files) {
    LinuxDocTools::process_file ($curfile);
  }

=head1 DESCRIPTION

The LinuxDocTools package encapsulates all the functionality offered by
LinuxDoc-Tools. It is used, of course, by LinuxDoc-Tools;
but the encapsulation should provide for a simple interface for other users as well.

=head1 FUNCTIONS

=over 4

=cut

use File::Copy;
use File::Temp qw(tempdir);
use File::Basename qw(fileparse);
use LinuxDocTools::Lang;
use LinuxDocTools::Utils qw(
  cleanup
  create_temp
  ldt_log
  remove_tmpfiles
  trap_signals
  usage
  );
use LinuxDocTools::Vars;

sub BEGIN
{
  #
  #  Make sure we're always looking here. Note that "use lib" adds
  #  on the front of the search path, so we first push dist, then
  #  site, so that site is searched first.
  #
  use lib "$main::DataDir/dist";
  use lib "$main::DataDir/site";
}

# -------------------------------------------------------------------
sub ldt_searchfile {
  # -----------------------------------------------------------------
  # Look for a readable file in the locations. Return first math.
  # -----------------------------------------------------------------
  my $files = shift;
  foreach my $file  ( @$files ){
    return $file if -r $file;
  }
}

# -------------------------------------------------------------------
sub ldt_getdtd_v1 {
  # -----------------------------------------------------------------
  # Get the dtd
  # -----------------------------------------------------------------
  my $file         = shift;
  my $error_header = "LinuxdocTools::ldt_getdtd_v1";
  my $dtd;

  open ( my $FILE, "< $file")
    or die "$error_header: Could not open \"$file\" for reading. Aborting ...\n";

  while ( <$FILE> ) {
    tr/A-Z/a-z/;
    # check for [<!doctype ... system] type definition
    if ( /<!doctype\s*(\w*)\s*system/ ) {
      $dtd = $1;
      last;
      # check for <!doctype ... PUBLIC ... DTD ...
    } elsif ( /<!doctype\s*\w*\s*public\s*.*\/\/dtd\s*(\w*)/mi ) {
      $dtd = $1;
      last;
      # check for <!doctype ...
      #          PUBLIC  ... DTD ...
      # (multi-line version)
    } elsif ( /<!doctype\s*(\w*)/ ) {
      $dtd = "precheck";
      next;
    } elsif ( /\s*public\s*.*\/\/dtd\s*(\w*)/ && $dtd eq "precheck" ) {
      $dtd = $1;
      last;
    }
  }
  close $FILE;

  # Warn about non-supported DTDs
  if ( ( $dtd ne "linuxdoc" ) && ( $dtd ne "linuxdoctr" ) ) {
    print STDERR " DTD check - Error: this linuxdoc-tools package supports";
    print STDERR " Linuxdoc DTD only.\n\n";

    # This is Debian Specific, but if debiandoc dtd is used on other system,
    # then that user may needs the debiandoc-sgml anyway.
    if ( $dtd eq "debiandoc" ) {
      print STDERR "   If you wish to convert DebianDoc DTD files,\n";
      print STDERR "     then please install and use";
      print STDERR " debiandoc-sgml package.\n\n";
    } else {
      print STDERR "   If you wish to convert DocBook or other DTD files,\n";
      print STDERR "     then please install and use";
      print STDERR " SGMLTools-Lite or Jade/OpenJade package.\n\n";
    }
    die " --- LinuxDoc-Tools aborting.\n";
  }

  return $dtd;
}

# -------------------------------------------------------------------
sub ldt_getdtd_v2 {
  # -----------------------------------------------------------------
  # Second way of getting dtd, fron nsgmls output.
  # -----------------------------------------------------------------
  my $preaspout    = shift;
  my $error_header = "LinuxdocTools::ldt_getdtd_v2";
  my $dtd2;

  open (my $TMP,"< $preaspout")
    or die "%error_header: Could not open $preaspout for reading. Aborting ...\n";
  while ( defined ($dtd2 = <$TMP>) && ! ( $dtd2 =~ /^\(/) ) { };
  close $TMP;
  $dtd2 =~ s/^\(//;
  $dtd2 =~ tr/A-Z/a-z/;
  chomp $dtd2;
  return $dtd2;
}

# -------------------------------------------------------------------

=item LinuxDocTools::init

Takes care of initialization of package-global variables (which are actually
defined in L<LinuxDocTools::Vars>). The package-global variables are I<$global>,
a reference to a hash containing numerous settings, I<%Formats>, a hash
containing all the formats, and I<%FmtList>, a hash containing the currently
active formats for help texts.

Apart from this, C<LinuxDocTools::init> also finds all distributed and site-local
formatting backends and C<require>s them.

=cut

# -------------------------------------------------------------------
sub init {
# -------------------------------------------------------------------
  trap_signals;

  # Register the ``global'' pseudoformat. Apart from the global settings, we
  # also use $global to keep the global variable name space clean everything
  # that we need to provide to other modules is stuffed into $global.
  $global              = {};
  $global->{NAME}      = "global";
  $global->{HELP}      = "";
  $global->{OPTIONS}   = [
			  { option => "backend",
			    type => "l",
			    'values' => [ "html", "info", "latex", "lyx", "rtf", "txt", "check" ],
			    short => "B" },
			  { option => "papersize",
			    type => "l",
			    'values' => [ "a4", "letter" ],
			    short => "p" },
			  { option => "language",
			    type => "l",
			    'values' => [ @LinuxDocTools::Lang::Languages ],
			    short => "l" },
			  { option => "charset",   type => "l",
			    'values' => [ "latin", "ascii", "nippon", "euc-kr" , "utf-8"],
			    short => "c" },
			  { option => "style",     type => "s", short => "S" },
			  { option => "tabsize",   type => "i", short => "t" },
			  # { option => "verbose",   type => "f", short => "v" },
			  { option => "debug",     type => "f", short => "d" },
			  { option => "define",    type => "s", short => "D" },
			  { option => "include",   type => "s", short => "i" },
			  { option => "pass",      type => "s", short => "P" }
			  ];
  $global->{backend}   = "linuxdoc";
  $global->{papersize} = "a4";
  $global->{language}  = '';
  $global->{charset}   = "ascii";
  $global->{style}     = "";
  $global->{tabsize}   = 8;
  $global->{verbose}   = 0;
  $global->{define}    = "";
  $global->{debug}     = 0;
  $global->{include}   = "";
  $global->{logfile}   = '';
  $global->{pass}      = "";
  $global->{InFiles}   = [];
  $global->{fmtlist}   = "";            # List of loaded fmt files
  $Formats{$global->{NAME}} = $global;	# All formats we know.
  $FmtList{$global->{NAME}} = $global;  # List of formats for help msgs.

  $global->{sgmlpre}   = "$main::AuxBinDir/sgmlpre";
  my $error_header     = "LinuxdocTools::init";

  if ( -e "/etc/papersize" ){
    open (my $PAPERSIZE,"< /etc/papersize") ||
      die "$error_header: Count not open \"/etc/papersize\" for reading\n";
    chomp (my $paper = <$PAPERSIZE>);
    $global->{papersize} = "letter" if ( $paper eq "letter");
    close $PAPERSIZE;
  }

  # automatic language detection: disabled by default
  # {
  #    my $lang;
  #    foreach $lang (@LinuxDocTools::Lang::Languages)
  #     {
  #       if (($ENV{"LC_ALL"} =~ /^$lang/i) ||
  #           ($ENV{"LC_CTYPE"} =~ /^$lang/i) ||
  #           ($ENV{"LANG"} =~ /^$lang/i)) {
  #	    $global->{language}  = Any2ISO($lang);
  #       }
  #     }
  # }

  # -------------------------------------------------------------------
  $global->{preNSGMLS} = sub {
    # -----------------------------------------------------------------
    #  Define a fallback preNSGMLS. Used when the format is "global"
    #  (from sgmlcheck).
    # -----------------------------------------------------------------
    $global->{NsgmlsOpts}   .= " -s ";
    $global->{NsgmlsPrePipe} = "cat $global->{file}";
  };

  # We need to load all fmt files here, so the allowed options for all
  # format are put into $global and a complete usage message is built,
  # including options for all formats.
  my %locations = ();
  foreach my $path ("$main::DataDir/site",
		    "$main::DataDir/dist",
		    "$main::DataDir/fmt"){
    foreach my $location (<$path/fmt_*.pl>){
      my $fmt =  $location;
      $fmt    =~ s/^.*_//;
      $fmt    =~ s/\.pl$//;
      $locations{$fmt} = $location unless defined $locations{$fmt};
    }
  }

  foreach my $fmt ( keys %locations ){
    $global->{fmtlist}   .= "  Loading $locations{$fmt}\n";
    require $locations{$fmt};
  }
}

# ------------------------------------------------------------------------

=item LinuxDocTools::process_options ($0, @ARGV)

This function contains all initialization that is bound to the current
invocation of LinuxDocTools. It looks in C<$0> to deduce the backend that
should be used (ld2txt activates the I<txt> backend) and parses the
options array. It returns an array of filenames it encountered during
option processing.

As a side effect, the environment variable I<SGML_CATALOG_FILES> is
modified and, once I<$global->{format}> is known, I<SGMLDECL> is set.

=cut

# -------------------------------------------------------------------
sub process_options {
  # -----------------------------------------------------------------
  my $progname  = shift;
  my @tmpargs   = @_;
  my @args      = ();
  my $format    = '';
  my $msgheader = "LinuxDocTools::process_options";

  # Try getting the format. We need to do this here so process_options
  # knows which is the format and which format options are allowed

  # First, see if we have an explicit backend option by looping over command line.
  # Do not shift in the while condition itself, 0 in options like '-s 0' will
  # otherwise stop looping
  while ( @tmpargs ){
    $_ = shift @tmpargs;
    if ( s/--backend=// ){
      $format = $_;
    } elsif ( $_ eq "-B" ){
      $format = shift @tmpargs;
    } else {
      push @args, $_;
    }
  }

  unless ( $format ){
    my ($tmpfmt, $dummy1, $dummy2) = fileparse($progname, "");
    if ( $tmpfmt =~ s/^sgml2// ) {       # Calling program through sgml2xx symlinks
      $format = $tmpfmt;
    } elsif ( $tmpfmt eq "sgmlcheck" ) { # Calling program through sgmlcheck symlink
      $format = "global";
    }
  }

  if ( $format ) {
    if ( $format eq "check" ){
      $format = "global";
    } elsif ( $format eq "latex" ){
      $format = "latex2e";
    }
    $FmtList{$format} = $Formats{$format} or
      usage("$format: Unknown format");
    $global->{format} = $format;
  } else {
    usage("");
  }

  # Parse all the options from @args, and return files.
  my @files    = LinuxDocTools::Utils::process_options(@args);

  # Check the number of given files
  $#files > -1 || usage("No filenames given");

  # Normalize language string
  $global->{language} = Any2ISO($global->{language})
    if ( defined $global->{language} );

  # Fine tune japanese and korean charsets when not utf-8
  if ($global->{charset} ne "utf-8") {
    if ($global->{language} eq "ja" ){
      $global->{charset} = "nippon";
    } elsif ($global->{language} eq "ko"){
      if ($global->{format} eq "groff") {
	$global->{charset} = "latin1";
      } else {
	$global->{charset} = "euc-kr";
      }
    }
  }

  # Setup the SGML environment.
  my @sgmlcatalogs =
    (# SGML iso-entities catalog location in Debian sgml-data package
     "$main::isoentities_prefix/share/sgml/entities/sgml-iso-entities-8879.1986/catalog",
     # SGML iso-entities catalog location in ArchLinux, Fedora and Gentoo
     "$main::isoentities_prefix/share/sgml/sgml-iso-entities-8879.1986/catalog",
     # SGML iso-entities catalog location when installed from linuxdoc-tools
     "$main::isoentities_prefix/share/sgml/iso-entities-8879.1986/iso-entities.cat",
     # dtd/catalog for SGML-Tools
     "$main::DataDir/linuxdoc-tools.catalog",
     # The super catalog
     "/etc/sgml/catalog");

  @sgmlcatalogs = ($ENV{SGML_CATALOG_FILES}, @sgmlcatalogs) if defined $ENV{SGML_CATALOG_FILES};

  $ENV{SGML_CATALOG_FILES} = join(':', @sgmlcatalogs);

  # Set to one of these if readable, nil otherwise
  $ENV{SGMLDECL} = ldt_searchfile(["$main::DataDir/dtd/$global->{format}.dcl",
				   "$main::DataDir/dtd/$global->{style}.dcl",
				   "$main::DataDir/dtd/sgml.dcl"]);

  # Show the list of loaded fmt_*.pl files if debugging
  print STDERR $global->{fmtlist} if $global->{debug};

  # Return the list of files to be processed
  return @files;
}

# -------------------------------------------------------------------

=item LinuxDocTools::process_file

With all the configuration done, this routine will take a single filename
and convert it to the currently active backend format. The conversion is
done in a number of steps in tight interaction with the currently active
backend (see also L<LinuxDocTools::BackEnd>):

=over

=item 1. Backend: set NSGMLS options and optionally create a pre-NSGMLS pipe.

=item 2. Here: Run the preprocessor to handle conditionals.

=item 3. Here: Run NSGMLS.

=item 4. Backend: run pre-ASP conversion.

=item 5. Here: Run SGMLSASP.

=item 6. Backend: run post-ASP conversion, generating the output.

=back

All stages are influenced by command-line settings, currently active format,
etcetera. See the code for details.

=cut

# -------------------------------------------------------------------
sub process_file {
  # ----------------------------------------------------------------
  my $file            = $global->{origfile} = shift (@_);
  my $saved_umask     = umask;
  my $error_header    = "LinuxdocTools::process_file";
  my $fmtopts         = $Formats{$global->{format}};

  print "Processing file $file\n";
  umask 0077;

  my ($filename, $filepath, $filesuffix) = fileparse($file, "\.sgml");
  $global->{filename} = $filename;
  $global->{filepath} = $filepath;
  $global->{file}     = ldt_searchfile(["$filepath/$filename.sgml",
					"$filepath/$filename.SGML"])
    or die "$error_header: Cannot find $file. Aborting ...\n";

  my $dtd = ldt_getdtd_v1("$global->{file}");
  print STDERR "DTD: " . $dtd . "\n" if $global->{debug};

  # -- Prepare temporary directory
  my $tmpdir    = $ENV{'TMPDIR'} || '/tmp';
  $tmpdir       = tempdir("linuxdoc-tools.XXXXXXXXXX", DIR => "$tmpdir");

  # -- Set common base name for temp files and temp file names
  my $tmpbase   = $global->{tmpbase} = $tmpdir . '/sgmltmp.' . $filename;
  my $precmdout = "$tmpbase.01.precmdout";
  my $nsgmlsout = "$tmpbase.02.nsgmlsout";   # Was $tmpbase.1
  my $preaspout = "$tmpbase.03.preaspout";   # Was $tmpbase.2
  my $aspout    = "$tmpbase.04.aspout";      # Was $tmpbase.3

  # -- Set $global->{logfile} and initialize logfile.
  $global->{logfile} = "$tmpbase.$global->{format}.log";
  open (my $LOGFILE, ">", "$global->{logfile}")
    or die "$error_header: Could not open \"$global->{logfile}\" logfile for write.\n";
  print $LOGFILE "--- Opening \"$global->{logfile}\" logfile ---\n";
  close $LOGFILE;

  # -- Write info about some global options
  ldt_log "--- Begin: Info about global options";
  foreach ( sort keys %$global ){
    next if m/fmtlist|InFiles|OPTIONS/;
    ldt_log "$_:  $global->{$_}";
  }
  ldt_log "--- End: Info about global options";
  ldt_log "$global->{fmtlist}";

  # -- Write info about some backend options
  ldt_log "--- Begin: Info about backend options";
  foreach ( sort keys %$fmtopts ){
    next if m/fmtlist|InFiles|OPTIONS/;
    ldt_log "$_:  $fmtopts->{$_}";
  }
  ldt_log "--- End: Info about backend options";

  # Set up the preprocessing command. Conditionals have to be
  # handled here until they can be moved into the DTD, otherwise
  # a validating SGML parser will choke on them.

  # -- Check if output option for latex is pdf or not
  if ($global->{format} eq "latex2e") {
    if ($Formats{$global->{format}}{output} eq "pdf") {
      $global->{define} .= " pdflatex=yes";
    }
  }

  # -- Set the actual pre-processing command
  my($precmd) = "| $global->{sgmlpre} output=$global->{format} $global->{define}";
  ldt_log "  ${error_header}::precmd:\n    $precmd";

  # -- Make sure path of file to be processed is in SGML_SEARCH_PATH
  $ENV{"SGML_SEARCH_PATH"} .= ":$filepath";

  # -- You can hack $NsgmlsOpts here, etcetera.
  $global->{NsgmlsOpts}   .= "-D $main::prefix/share/sgml -D $main::DataDir";
  $global->{NsgmlsOpts}   .= "-i$global->{include}" if ($global->{include});

  # If a preNSGMLS function is defined in the fmt file, pipe its output to $FILE,
  # otherwise just open $global->{file} as $IFILE
  # -----------------------------------------------------------------
  ldt_log "- PreNsgmls stage started.";
  my $IFILE;
  if ( defined $Formats{$global->{format}}{preNSGMLS} ) {
    $global->{NsgmlsPrePipe} = &{$Formats{$global->{format}}{preNSGMLS}};
    ldt_log  "  ${error_header}::NsgmlsPrePipe: $global->{NsgmlsPrePipe} |";
    open ($IFILE,"$global->{NsgmlsPrePipe} |")
      || die "$error_header: Could not open pipe from $global->{NsgmlsPrePipe}. Aborting ...\n";
  } else {
    ldt_log "  ${error_header}: No prepipe. Just opening \"$global->{file}\" for read";
    open ($IFILE,"< $global->{file}")
      || die "$error_header: Could not open $global->{file} for reading. Aborting ...\n";
  }

  # -- Create a temp file with $precmd output
  my $precmd_command    = "$precmd > $precmdout";
  ldt_log "  ${error_header}::precmd_command:\n    $precmd_command";

  open (my $PRECMDOUT, "$precmd_command")
    or die "$error_header: Could not open pipe to $precmdout. Aborting ...\n";

  # -- Convert latin1 chars to sgml entities for html backend
  if ( $global->{format} eq "html"
       && $global->{charset} eq "latin"  ) {
    ldt_log "  ${error_header}: Converting latin1 chars to sgml entities for html backend";
    print $PRECMDOUT ldt_latin1tosgml($IFILE);
  } else {
    copy($IFILE,$PRECMDOUT);
  }

  close $IFILE;
  close $PRECMDOUT;
  ldt_log "- PreNsgmls stage finished.";

  ldt_log "- Nsgmls stage started.";

  # -- Pass apropriate envvars to nsgmls to better deal with utf-8
  my $NSGMLS_envvars = ($global->{charset} eq "utf-8")
    ? "SP_CHARSET_FIXED=yes SP_ENCODING=utf-8" : "";

  # -- Process with nsgmls.
  my $nsgmls_command = "$NSGMLS_envvars $main::progs->{NSGMLS} $global->{NsgmlsOpts} $ENV{SGMLDECL} $precmdout > $nsgmlsout";
  ldt_log "  ${error_header}::nsgmls_command:\n    $nsgmls_command";
  system($nsgmls_command) == 0
    or die "${error_header}: Error: \"$nsgmls_command\" failed with exit status: ",$? >> 8,"\n";

  #  -- Special case: if format is global, we're just checking.
  cleanup if ( $global->{format} eq "global");

  # -- If output file does not exists or is empty, something went wrong.
  if ( ! -e "$nsgmlsout" ) {
    die "$error_header: Can't create file $nsgmlsout. Aborting ...\n";
  } elsif ( -z "$nsgmlsout" ){
    die "$error_header: $nsgmlsout empty, SGML parsing error. Aborting ...\n";
  }

  print "- Nsgmls stage finished.\n" if $global->{debug};
  ldt_log "- Nsgmls stage finished.";

  #  If a preASP stage is defined, let the format handle it.
  #  --------------------------------------------------------
  ldt_log "- PreASP stage started.";
  open (my $PREASP_IN, "< $nsgmlsout")
    or die "$error_header: Could not open $nsgmlsout for reading. Aborting ...\n";
  open (my $PREASP_OUT, "> $preaspout")
    or die "$error_header: Could not open $preaspout for writing. Aborting ...\n";

  if (defined $Formats{$global->{format}}{preASP}) {
    # Usage: preASP ($INHANDLE, $OUTHANDLE);
    &{$Formats{$global->{format}}{preASP}}($PREASP_IN, $PREASP_OUT) == 0
      or die "$error_header: Error pre-processing $global->{format}.\n";
  } else {
    copy ($PREASP_IN, $PREASP_OUT);
  }

  close $PREASP_IN;
  close $PREASP_OUT;

  die "$error_header: Can't create $preaspout file. Aborting ...\n"
    unless -e "$preaspout";

  print "- PreASP stage finished.\n" if ( $global->{debug} );
  ldt_log "- PreASP stage finished.";

  # Run sgmlsasp, with an optional style if specified.
  # -----------------------------------------------------------
  ldt_log "- ASP stage started.";
  my $dtd2 = ldt_getdtd_v2($preaspout)
    or die "$error_header: Could not read dtd from $preaspout. Aborting ...\n";

  ldt_log "  $error_header: dtd_v1: $dtd, dtd_v2: $dtd2, both must match, dtd_v2 prevails";
  unless ( $dtd eq $dtd2 ){
    print STDERR "Warning: Two different values for dtd, dtd1: $dtd, dtd2: $dtd2\n";
    $dtd = $dtd2;
  }

  $global->{'dtd'} = $dtd;

  #  Search order:
  #  - datadir/site/<dtd>/<format>
  #  - datadir/dist/<dtd>/<format>

  my $style = ($global->{style}) ?
    ldt_searchfile(["$main::DataDir/site/$dtd/$global->{format}/$global->{style}mapping",
		    "$main::DataDir/dist/$dtd/$global->{format}/$global->{style}mapping",
		    "$main::DataDir/mappings/$global->{format}/$global->{style}mapping"])
    :
    '';

  my $mapping = ldt_searchfile(["$main::DataDir/site/$dtd/$global->{format}/mapping",
				"$main::DataDir/dist/$dtd/$global->{format}/mapping",
				"$main::DataDir/mappings/$global->{format}/mapping"])
    or die "$error_header: Could not find mapping file for $dtd/$global->{format}. Aborting ...\n";

  $mapping = "$style $mapping" if $style;

  if ($global->{format} eq "groff"){
    if ($dtd eq "linuxdoctr") {
      $mapping = "$main::DataDir/mappings/$global->{format}/tr-mapping";
    }
  }

  my $sgmlsasp_command = "$main::progs->{SGMLSASP} $mapping < $preaspout |
      expand -t $global->{tabsize} > $aspout";
  ldt_log "  ${error_header}::sgmlsasp_command:\n    $sgmlsasp_command";
  system ($sgmlsasp_command) == 0
    or die "$error_header: Error running $sgmlsasp_command. Aborting ...\n";

  die "$error_header: Can't create $aspout file. Aborting ...\n"
    unless -e "$aspout";

  print "- ASP stage finished.\n" if ( $global->{debug} );
  ldt_log "- ASP stage finished.";

  #  If a postASP stage is defined, let the format handle it.
  # ----------------------------------------------------------------
  ldt_log "- postASP stage started.";
  umask $saved_umask;

  open (my $INPOSTASP, "< $aspout" )
    or die "$error_header: Could not open $aspout for reading. Aborting ...\n";
  if (defined $Formats{$global->{format}}{postASP}) {
    # Usage: postASP ($INHANDLE)
    # Should leave whatever it thinks is right based on $INHANDLE.
    &{$Formats{$global->{format}}{postASP}}($INPOSTASP) == 0
      or die "$error_header: Error post-processing $global->{format}. Aborting ...\n";
  }
  close $INPOSTASP;

  print "- postASP stage finished.\n" if ( $global->{debug} );
  ldt_log "- postASP stage finished.";

  # -- Reset $global->{logfile} for next file
  $global->{logfile} = '';

  # -- All done, remove the temporaries.
  remove_tmpfiles($tmpbase) unless ( $global->{debug} );
}

=pod

=back

=head1 SEE ALSO

Documentation for various sub-packages of LinuxDocTools.

=head1 AUTHOR
SGMLTools are written by Cees de Groot, C<E<lt>cg@cdegroot.comE<gt>>,
and various SGML-Tools contributors as listed in C<CONTRIBUTORS>.
Taketoshi Sano C<E<lt>sano@debian.org<gt>> rename to LinuxDocTools.

=cut
1;

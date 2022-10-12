#
#  fmt_info.pl
#
# ------------------------------------------------------------------
#  GNU Info-specific driver stuff
#
#  Copyright (C) 1994-1996, Matt Welsh
#  Copyright (C) 1996, Cees de Groot
#  Copyright (C) 1999-2000, Taketoshi Sano
#  Copyright (C) 2008-2020 Agustin Martin
# ------------------------------------------------------------------

package LinuxDocTools::fmt_info;
use strict;

use LinuxDocTools::Vars;

use File::Copy;
use Text::EntityMap;
use LinuxDocTools::CharEnts;
use LinuxDocTools::Lang;
use LinuxDocTools::Vars;
use LinuxDocTools::InfoUtils qw{info_process_texi};

my $info = {};
$info->{NAME}           = "info";
$info->{HELP}           = "";
$Formats{$info->{NAME}} = $info;
$info->{OPTIONS}        = [
			   ];

# ------------------------------------------------------------------
$info->{preNSGMLS} = sub {
# ------------------------------------------------------------------
  $global->{NsgmlsOpts} .= " -ifmtinfo ";
  $global->{NsgmlsPrePipe} = "cat  $global->{file}";
};

# ------------------------------------------------------------------
my $info_escape = sub {
# ------------------------------------------------------------------
# Ascii escape sub.  this is called-back by `parse_data' below in
# `info_preASP' to properly escape `\' characters coming from the SGML
# source.
# ------------------------------------------------------------------
  my ($data) = @_;

  #    $data =~ s|"| \"|g;	# Insert zero-width space in front of "
  #    $data =~ s|^\.| .|;	# ditto in front of . at start of line
  #    $data =~ s|\\|\\\\|g;	# Escape backslashes

  return ($data);
};

# ------------------------------------------------------------------
$info->{preASP} = sub {
# ------------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;
  my $suffix     = ( $global->{charset} eq "latin1" ) ? '.2l1texi' : '.2texi';
  my $char_maps  = load_char_maps ($suffix, [ Text::EntityMap::sdata_dirs() ]);
  my $inpreamble = 1;
  my $inheading;

  # Replace some symbols in the file before sgmlsasp is called. This
  # has been done in preNSGMLS, but if the specified sgml file is
  # divided into multiple pieces, the preNSGMLS is not enough.
  while ( <$INFILE> ) {
    s/\@/\@\@/g;
    s/\{/\@\{/g;
    s/\}/\@\}/g;
#      s/-\((.*)\)/-\'\($1\)\'/;
    s/-\((.*)\)/-\[$1\]/;
    s/\\\|urlnam\\\|/ /g;
    s/\\\|refnam\\\|/ /g;

    if ( s/^-// ) {
      chomp;
      s/([^\\])\\n/$1 /g if $inheading;      # Remove spurious \n in headings
      s/(\\n|^)\\011/$1/g if $inpreamble;    # Remove leading tabs in abstract.
      print $OUTFILE "-" .
	parse_data ($_, $char_maps, $info_escape) . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get translated also
	$value = parse_data ($value, $char_maps, $info_escape);
      }
      print $OUTFILE "A$name $type $value\n";
    } else {
      if (/^\(HEADING/){
        $inheading = 1;
	$inpreamble = '';          # No longer in preamble if found a HEADING
      } elsif (/^\)HEADING/){
        $inheading = '';
      }
      #  Default action if not skipped over by previous conditions: copy in to out.
      print $OUTFILE $_;
    }
  }

  return 0;
};

# ------------------------------------------------------------------
$info->{postASP} = sub {
# ------------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# ------------------------------------------------------------------
  my $INFILE    = shift;                       # File handle reference to input file
  my $rawtexi   = "$global->{tmpbase}.2.texi"; # Encoding replaced if appropriate
  my $texifile  = "$global->{tmpbase}.3.texi"; # File ready for makeinfo
  my $infofile0 = "$global->{tmpbase}.4.info"; # makeinfo output
  my $infofile  = "$global->{filename}.info";  # Final info file.

  my $msgheader = "fmt_info::postASP";
  my $fileinfo  = "info file generated from $global->{file} by means of linuxdoc-tools";

  my @tmp_texi = <$INFILE>;

  # Explicitly set encoding if required. texinfo default is now utf-8
  # texinfo seems not to support other linuxdoc supported encodings
  my $info_charset_mapping = { # map linuxdoc charset names to texinfo names
     'latin' => "ISO-8859-1",
     'uft-8' => "UTF-8"
    };
  for (@tmp_texi) {
    if ( defined $info_charset_mapping->{$global->{charset}} ){
      s/\@comment \@encoding\@/\@documentencoding $info_charset_mapping->{$global->{charset}}/;
    }
  }

  open (my $OUTFILE, "> $rawtexi")
    or die "fmt_info::postASP: Could not open \"$rawtexi\" for writing. Aborting ...\n";
  print $OUTFILE @tmp_texi;
  close $OUTFILE;

  # Preprocess the raw texinfo file
  info_process_texi($rawtexi,$texifile,$infofile);

  system ("makeinfo $texifile -o $infofile") == 0
    or die "$msgheader: Failed to run makeinfo. Aborting ...\n";

  move $infofile, $infofile0;

  my $infotext;
  open ( my $TMPINFO, "< $infofile0")
    or die "Could not open $infofile0 for read. Aborting ... \n";
  {
    local $/ = undef;
    $infotext = <$TMPINFO>;
  }
  close $TMPINFO;

  # Change origin filename given by makeinfo to something useful
  $infotext =~ s/\Q$texifile\E/$fileinfo/;

  # Remove not needed line in resulting info file. Only first match.
  $infotext =~ s/\\input texinfo//;

  open (my $OUTFILE, "> $infofile")
    or die "Could not open $infofile for write. Aborting ... \n";
  print $OUTFILE $infotext;
  close $OUTFILE;

  return 0;
};

1;

#
#  fmt_rtf.pl
#
# -----------------------------------------------------------
#  RTF-specific driver stuff
#
#  Copyright (C) 1994-1996, Matt Welsh
#  Copyright (C) 1996, Cees de Groot
#  Copyright (C) 1998, Sven Rudolph
#  Copyright (C) 1999-2001, Taketoshi Sano
#  Copyright (C) 2008-2020, Agustin Martin
# -----------------------------------------------------------

package LinuxDocTools::fmt_rtf;
use strict;

use File::Copy;
use Encode qw/encode/;
use LinuxDocTools::Vars;
use LinuxDocTools::CharEnts;
use LinuxDocTools::Utils qw(ldt_log);

my $rtf = {};
$rtf->{NAME} = "rtf";
$rtf->{HELP} = "";
$rtf->{OPTIONS} = [
  { option => "twosplit",
    type => "f",
    short => "2" }
  ];
$rtf->{twosplit}  = 0;

$Formats{$rtf->{NAME}} = $rtf;

# -----------------------------------------------------------------------
sub rtf2unicode {
  # ---------------------------------------------------------------------
  # Replace utf-8 chars by their rtf representation, braced and doubly
  # escaped (e.g., {\\u123?}, ? stands for write ? if char unavailable
  # in font). Will process it later to something like \uxxx?
  # ---------------------------------------------------------------------
  my $string = shift;

  if ( $global->{charset} eq "utf-8" ) {
    my @chars = split '', $string;
    foreach (@chars){
      if ( ord($_) > 127 ){
	$_ = "{\\\\u" . unpack("s", encode("utf16-le", $_)) . "?}";
      }
    }
    return join("", @chars);
  } else {
    return $string;
  }
}

# -----------------------------------------------------------------------
my $rtf_escape = sub {
  # ---------------------------------------------------------------------
  # Ascii escape sub to properly escape some characters, if required.
  # Passed to `parse_data' below in rtf_preASP .
  # ---------------------------------------------------------------------
  my ($data) = @_;

  return ($data);
};

# -------------------------------------------------------------
$rtf->{preASP} = sub {
  # -------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;
  my $verbatim;
  my $inheading;

  # `sdata_dirs' passed as anonymous array to make a single argument
  my $rtf_char_maps = load_char_maps (
    '.2rtf',
    [ Text::EntityMap::sdata_dirs() ]);

  # Declare $INFILE as utf-8 if charset is utf-8
  if ( $global->{charset} eq "utf-8" ){
    binmode($INFILE, ":utf8");
  }

  while (<$INFILE>){
    chomp;
    # RTF does not treat newline as whitespace, so we need to turn
    # "\n" into " \n". Without the extra space, two words separated
    # only by a newline will get jammed together in the RTF output.
    # ------------------------------------------------------------
    s/([^\\])\\n/$1 \\n/g;

    if ( s/^-// ) {
      print $OUTFILE "-" . parse_data(rtf2unicode($_), $rtf_char_maps, $rtf_escape) . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get also translated
	$value = parse_data (rtf2unicode($value), $rtf_char_maps, $rtf_escape);
      }
      print $OUTFILE "A$name $type $value\n";
    } else {
      if (/^\(HEADING/){
        $inheading = 1;
      } elsif (/^\)HEADING/){
        $inheading = '';
      } elsif (/^\((VERB|CODE)/) {
	$verbatim = 1;
      } elsif (/^\)(VERB|CODE)/) {
	$verbatim = '';
      }
      print $OUTFILE rtf2unicode($_) . "\n";
    }
  }
};

# -------------------------------------------------------------
$rtf->{postASP} = sub {
# -------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# -------------------------------------------------------------
  my $INFILE  = shift;
  my $rtf2rtf = "$main::AuxBinDir/rtf2rtf";
  my $split   = ($rtf->{twosplit}) ? "-2" : "";
  my $pipe_in = "$global->{tmpbase}.fmt_rtf.01.rtf";
  my $prefile = "$global->{filename}";
  my $rtffile = "$global->{filename}.rtf";
  my $msghead = "fmt_rtf.pl::postASP";

  # Preprocess raw file before piping to rtf2rtf
  open ( my $RTF_PIPE_IN, "> $pipe_in");
  while (<$INFILE>){
    # Change {\\u323?} type strings to something like \u323? (or
    # \u-xx?) Needed for sgmlsasp not complaining about bad escapes.
    s/\{\\(\\u[\-\d]+\?)\}/$1/g;

    print $RTF_PIPE_IN $_;
  }
  close $RTF_PIPE_IN;

  open ( my $RTF_PIPE,"| $rtf2rtf $split $prefile > $rtffile" )
    or die "$msghead: Could not open pipe to $rtf2rtf. Aborting ...\n";
  copy ($pipe_in, $RTF_PIPE);
  close $RTF_PIPE;

  ldt_log "$msghead: cat $pipe_in | $rtf2rtf $split $prefile > $rtffile";

  return 0;
};

1;

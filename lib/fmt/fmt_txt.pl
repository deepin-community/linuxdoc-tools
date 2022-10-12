#
#  fmt_txt.pl
#
# ---------------------------------------------------
#  TXT-specific driver stuff
#
#  Copyright (C) 1994-1996, Matt Welsh
#  Copyright (C) 1996, Cees de Groot
#  Copyright (C) 1999-2001, Taketoshi Sano
#  Copyright (C) 2007-2020, Agustin Martin
# ---------------------------------------------------

package LinuxDocTools::fmt_txt;
use strict;

use File::Copy;
use Text::EntityMap;
use Text::Wrap;
use LinuxDocTools::CharEnts;
use LinuxDocTools::Lang;
use LinuxDocTools::Vars;
use LinuxDocTools::Utils qw(create_temp ldt_log);

my $txt = {};
$txt->{NAME}    = "txt";
$txt->{HELP}    = "";
$txt->{OPTIONS} = [
		   { option => "manpage", type => "f", short => "m" },
		   { option => "filter",  type => "f", short => "f" },
		   { option => "blanks",  type => "i", short => "b" }
		   ];
$txt->{manpage} = 0;
$txt->{filter}  = 0;
$txt->{blanks}  = 3;

$Formats{$txt->{NAME}} = $txt;

# ---------------------------------------------------------------
sub txt_parse_data
# ---------------------------------------------------------------
# Wrapper to parse_data, removing some things if not in verbatim
# ---------------------------------------------------------------
{
  my $string     = shift;
  my $verbatim   = shift;
  my $char_maps  = shift;
  my $txt_escape = shift;
  my $msgheader  = "fmt_txt::txt_parse_data";

  die "$msgheader: Bad number of arguments\n" unless $txt_escape;

  $string =  &parse_data ($string, $char_maps, $txt_escape);

  unless ( $verbatim ){
    $string =~ s/([^\\])\\011/$1 /g;      # No tabulars in text
    $string =~ s/\s+/ /g;                 #
  }

  return $string;
}

# ---------------------------------------------------------------
$txt->{preNSGMLS} = sub
# ---------------------------------------------------------------
#  Set correct NsgmlsOpts
# ---------------------------------------------------------------
{
  my $msgheader = "fmt_txt::preNSGMLS";

  $global->{NsgmlsOpts} .= ( $txt->{manpage} ) ? " -iman " : " -ifmttxt ";

  # Adjust charset names for groff
  $global->{charset} = "latin1" if $global->{charset} eq "latin";

  # Adjust format names for groff
  $global->{format}  = $global->{charset};
  $global->{format}  = "groff"  if $global->{format} eq "latin1";
  $global->{format}  = "groff"  if $global->{format} eq "ascii";
  $global->{format}  = "groff"  if $global->{format} eq "nippon";
  $global->{format}  = "groff"  if $global->{format} eq "euc-kr";
  $global->{format}  = "groff"  if $global->{format} eq "utf-8";
  $global->{format}  = "man"    if $txt->{manpage};

  $ENV{SGML_SEARCH_PATH} =~ s/txt/$global->{format}/;

  $Formats{"groff"}  = $txt;
  $Formats{"latin1"} = $txt;
  $Formats{"man"}    = $txt;

  ldt_log "  ${msgheader}:\n    format: $global->{format}, charset: $global->{charset}, lang: $global->{language}";

  my $nsgmlsprepipecommand = "cat $global->{file} | sed 's/_/\\&lowbar;/g' ";
  ldt_log "  ${msgheader}::NsgmlsPrePipe:\n    $nsgmlsprepipecommand";

  $global->{NsgmlsPrePipe} = "$nsgmlsprepipecommand";
};

# ---------------------------------------------------------------
my $txt_escape = sub
# ---------------------------------------------------------------
# Ascii escape sub. This is called-back by `parse_data' below in
# `txt_preASP' to properly escape `\' characters coming from the SGML
# source.
# ---------------------------------------------------------------
{
  my ($data) = @_;

  $data =~ s|"|\\\&\"|g;   # Insert zero-width space in front of "
  $data =~ s|^\.|\\&.|;	   # ditto in front of . at start of line
  $data =~ s|^\'|\\&\'|;   # ditto in front of ' at start of line
  $data =~ s|\\|\\\\|g;	   # Escape backslashes

  return ($data);
};

# ---------------------------------------------------------------
$txt->{preASP} = sub
# ---------------------------------------------------------------
# Pre-process file before sgmlsasp and create a TOC unless producing
# a manpage. Code based in the genertoc utility and in code from FJM.
# ---------------------------------------------------------------
{
  my ($INFILE, $OUTFILE) = @_;
  my $char_maps = ( $global->{charset} eq "latin1" ) ? '.2l1tr' : '.2tr';
  # Note: `sdata_dirs' list made an anonymous array to have a single argument
  $char_maps = load_char_maps ($char_maps, [ Text::EntityMap::sdata_dirs() ]);

  if ($txt->{manpage}){
    while (<$INFILE>){
      if ( s/^-// ){
	chomp;
	print $OUTFILE "-" . &parse_data ($_, $char_maps, $txt_escape) . "\n";
      } elsif (/^A/) {
	/^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	  || die "bad attribute data: $_\n";
	my ($name,$type,$value) = ($1,$2,$4);
	if ($type eq "CDATA"){
	  # CDATA attributes get also translated
	  $value = &parse_data ($value, $char_maps, $txt_escape);
	}
	print $OUTFILE "A$name $type $value\n";
      } else {
	print $OUTFILE $_;
      }
    }
    return;
  }

  # ---------------------------------
  # Pre-process file and extract TOC info
  # ---------------------------------

  my $inheading    = 0;
  my $headertext   = '';
  my $sectionlevel = '';
  my $appendix     = 0;
  my $txtout       = "";
  my $thetoc       = '';
  my $chapterskip  = 0;
  my $verbatim     = 0;
  my @tocarray     = ();
  my @header       = ();
  my @prevheader   = ();

  while ( <$INFILE> ) {
    if ($inheading){
      next if ( /^(\(|\))(BF|EM|IT|LABEL|TT)/ );
      next if ( /^\)TOC/ );

      if ( s/^-// ) {                # Header text
	chomp;
	$headertext .= $_;
	$headertext .= " ";
      } elsif (/^\)HEADING/){        # End of header: Write full header text
	$headertext =~ s/[ \n]*$//;
	if ( $headertext ) {
	  $headertext = &txt_parse_data ($headertext, $verbatim, $char_maps, $txt_escape);
	  $headertext =~ s/^\\n/ /g;      # No newlines in header text BOL
	  $headertext =~ s/([^\\])\\n/$1 /g;  # No unescaped \n in headertext
	} else {
	  $headertext = " ";
	}
	$txtout .= "-" . $headertext . "\n";
	push @tocarray, [$sectionlevel, $headertext];
	$inheading    = 0;
	$sectionlevel = '';
	$txtout .= $_;
      } else {                       # labels and friends: copy to output
	$txtout .= $_;
      }

    } else { # --- Not in heading
      if ( s/^-// ) {
	chomp;
	$txtout .=  "-" . &txt_parse_data ($_, $verbatim, $char_maps, $txt_escape) . "\n";
      } elsif (/^A/) {
	/^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	  || die "bad attribute data: $_\n";
	my ($name,$type,$value) = ($1,$2,$4);
	if ($type eq "CDATA") {      # CDATA attributes get also translated
	  $value = &txt_parse_data ($value, $verbatim, $char_maps, $txt_escape);
	}
	$txtout .= "A$name $type $value\n";
      } elsif (/^\(TOC/) {           # Placeholder for TOC
	$txtout .= "##TOC##";
      } else {       # Nothing below changes output, just info is recorded
	if (/^\(HEADING/) {          #  Go into heading processing mode.
	  $headertext   = '';
	  $inheading    = 1;
	} elsif (/^\(CHAPT/) {
	  $sectionlevel = 0;
	  $chapterskip  = 1;         # Start sectioning with chapter
	  if ( $appendix ) {
	    $sectionlevel = "A$sectionlevel";
	    $appendix     = 0;
	  }
	} elsif (/^\(SECT(.*)/) {
	  $sectionlevel = $1 ? $1 : 0;
	  $sectionlevel += $chapterskip;
	  if ( $appendix ) {
	    $sectionlevel = "A$sectionlevel";
	    $appendix     = 0;
	  }
	} elsif (/^\(APPEND(.*)/) {  # appendix mode
	  $appendix = 1;
	} elsif (/^\(VERB/) {        # verbatim mode
	  $verbatim = 1;
	} elsif (/^\)VERB/){         # end of verbatim
	  $verbatim = 0;
	}
	$txtout .= $_;
      }
    }
  } # end of  while (<$INFILE>) loop

  # ----------------------------
  # Post-process the TOC, if any
  # ----------------------------

  if ( @tocarray ) {
    my $toclinelength = 72;          # Length of a normal line
    @header = @prevheader = ();
    $thetoc = join ("\n",("(HLINE",
			  ")HLINE",
			  "(P",
			  "-" . Xlat ("Table of Contents"),
			  ")P",
			  "(VERB\n"));

    foreach my $entry ( @tocarray ) {
      my $level  = $$entry[0];       # Section level
      my $text   = $$entry[1];       # section entry
      my $number = '';               # Numbering of the item
      my $nwhite = '';               # Will be length($number) times " "

      $text =~ s/(\(|\))(BF|EM|IT|LABEL|TT)//g;
      $text =~ s/AID * CDATA.*$//g;
      $text =~ s/\s+/ /g;

      @prevheader = @header;
      @header     = @header[0..$level];

      if ( $level =~ s/^A// ){
	$header[$level] = "A";
      } else {
	$header[$level]++;
      }

      $number = join ('.',@header);

      if ( ! $#header ) {
	# put a . after top level sections
	$number .= '.';
	# put a newline before top-level sections unless previous is one
	$number = "\\n" . $number unless (!$#prevheader);
	$number = "-" . $number;
      } else {
	# subsections get indentation matching hierarchy
	$number = "-" . "   " x $#header . $number;
      }
      unless ( $text =~ /^(\(|\))(NCDX|NIDX)$/ ){
	$nwhite = $number;
	$nwhite =~ s/^[-\\n]*//;
	$nwhite = "-" . " " x length($nwhite);
	$Text::Wrap::columns = $toclinelength - length($nwhite);
	foreach ( split("\n",wrap('','',$text)) ){
	  $thetoc .= "$number $_\\n\n";
	  $number = $nwhite;     # Whitespaces if number is already printed
	}
      }
    }
    $thetoc .= join ("\n",(")VERB",
			   "(HLINE",
			   ")HLINE\n"));
  } # Parsed @tocarray

  if ( $thetoc ){
    $txtout =~ s/^\#\#TOC\#\#/$thetoc/m;
  } else {
    $txtout =~ s/^\#\#TOC\#\#//m;
  }
  print $OUTFILE $txtout;
  return 0;
};

# ---------------------------------------------------------------
$txt->{postASP} = sub
# ---------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# ---------------------------------------------------------------
{
  my $INFILE    = shift;
  my $OUTFILE;
  my $TXTFILE;
  my $GROFFOUT;
  my $manfile   = "$global->{filename}.man";
  my $txtfile   = "$global->{filename}.txt";
  my $groffout  = "$global->{tmpbase}.groffout";
  my $txtout    = ( $global->{language} eq "en" ) ? "" : ".nr HY 0\n";
  my $txtout0   = "$txtout";
  my $msgheader = "fmt_txt::postASP";

  # Put document in a single large page. 99999 lines should be enough.
  $txtout .= q/.\" Trim page to total height of text.
.de sp-adj
.  br
.  pl \\n[nl]u
..
.
.\" Set single-page mode
.de sp-set
.  pl 99999
.  em sp-adj
..
.sp-set
/;

  while ( <$INFILE> ) {    #  Feed $txtout with roff input.
    $txtout0 .= $_;
    unless (/^\.DS/.../^\.DE/)  {
      s/^[ \t]{1,}(.*)/$1/g;
    }
    s/^\.[ \t].*/\\\&$&/g;
    s/\\fC/\\fR/g;
    s/^.ft C/.ft R/g;
    $txtout .= $_;
  }

  # Remove some extra .Pp
  $txtout =~ s/(\.Pp\n){2,}/\.Pp\n/g;  # Collapse adjacent .Pp
  $txtout =~ s/\.Pp\n(\.(IP|NH))/$1/g; # Remove .Pp before headers and exdented pars

  if ( $global->{debug} ){
    my $GROFF0;
    my $groff0 = "$global->{tmpbase}.groff.0";
    open ( $GROFF0, "> $groff0")
      or die "${msgheader}: Could not open \"$groff0\" for write.\n";
    print $GROFF0 $txtout0;
    close $GROFF0;

    my $GROFF;
    my $groff  = "$global->{tmpbase}.groff";
    open ( $GROFF, "> $groff")
      or die "${msgheader}: Could not open \"$groff\" for write.\n";
    print $GROFF $txtout;
    close $GROFF;
  }

  if ( $txt->{manpage} ) {
    open ( $OUTFILE, "> $manfile" )
      or die "${msgheader}: Could not open \"$manfile\" for writing\n";
  } else {
    unless ( $global->{pass} ){  # Use old overstrike format
      $global->{pass} = $txt->{filter} ? "-P-cbou" : "-P-c";
    }
    my $groffdevice  = ($global->{charset} eq "utf-8") ? "-k -Kutf8 -Tutf8 " : "-T $global->{charset}";
    my $groffcommand = "| $main::progs->{GROFF} $global->{pass} $groffdevice -t $main::progs->{GROFFMACRO} > $groffout";
    ldt_log "  ${msgheader}::groffcommand:\n    $groffcommand";
    open ( $OUTFILE, $groffcommand )
      or die "${msgheader}: Could not open pipe to groff:\n  $groffcommand\n";
    print STDERR "groff_PIPE: $groffcommand\n"
      if ( $global->{debug} &&  exists $ENV{'LDT_DEBUG'} );
  }

  print $OUTFILE $txtout;
  close $OUTFILE;

  die " ${msgheader}: Empty output file, error when calling groff. Aborting...\n"
    if ( ! $txt->{manpage} && -z $groffout );

  #  Unless making a manpage, a bit of work is left.

  unless ( $txt->{manpage} ) {
    open ( $TXTFILE, "> $txtfile")
      or die "${msgheader}: Could not open \"$txtfile\" for writing\n";

    open ( $GROFFOUT, "< $groffout")
      or die "${msgheader}: Could not open \"$groffout\" for reading\n";

    if ( $txt->{blanks} ) { # No more than $txt->{blanks} continuous blank lines
      my $count = 0;
      while ( <$GROFFOUT> ){
	$count = ( /^$/ ) ? $count + 1  : 0;
	print $TXTFILE $_ if ( $count <= $txt->{blanks} );
      }
    } else {
      copy ($GROFFOUT, $TXTFILE);
    }

    close $TXTFILE;
    close $GROFFOUT;
  }
  return 0;
};

# Ensure we evaluate to true.
1;

__END__

# Local Variables:
#  mode: perl
#  perl-indent-level: 2
# End:

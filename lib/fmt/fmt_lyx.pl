#
#  fmt_lyx.pl
#
# -----------------------------------------------------------------------
#  Lyx-specific driver stuff
#
#  Copyright (C) 1994-1996, Matt Welsh
#  Copyright (C) 1996, Cees de Groot
#  Copyright (C) 2006-2020, Agustin Martin
# -----------------------------------------------------------------------

package LinuxDocTools::fmt_lyx;
use strict;

use LinuxDocTools::CharEnts;
use LinuxDocTools::Vars qw{
  %Formats
  $global
  %FmtList
  $VERSION
  $lyx_afterslash_sep};
use LinuxDocTools::Lang qw{ISO2English};

my $lyx                = {};
$lyx->{NAME}           = "lyx";
$lyx->{HELP}           = "";
$Formats{$lyx->{NAME}} = $lyx;
$lyx->{OPTIONS}        = [
			  ];

# -----------------------------------------------------------------------
$lyx->{preNSGMLS} = sub {
# -----------------------------------------------------------------------
  $global->{NsgmlsOpts}   .= " -ifmtlyx ";
  # We need to pre-process the sgml file
  my $perlfilter           = "$main::DataDir" . "/filters/lyx-preNSGMLS.pl";
  $global->{NsgmlsPrePipe} = "perl -f $perlfilter < $global->{file} ";
};

# -----------------------------------------------------------------------
my $lyx_escape = sub {
# -----------------------------------------------------------------------
# Passed to `parse_data' below in lyx_preASP
# -----------------------------------------------------------------------
    my ($data) = @_;

    # The single exception backslash is treated below
    return ($data);
};

# -----------------------------------------------------------------------
$lyx->{preASP} = sub {
# -----------------------------------------------------------------------
#  Take the nsgmls output, and prepare it a bit.
#  Note that currently LyX works only with isolatin1
# -----------------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;
  my $verbatim;
  my $inheading;
  my $lyx_char_map = ( $global->{charset} eq "utf-8" ) ? '.2u8b' : '.2l1b';

  # `sdata_dirs' list is passed as anonymous array to make a single argument
  my $char_maps = load_char_maps ($lyx_char_map,
				  [ Text::EntityMap::sdata_dirs() ]);

  while (<$INFILE>) {
    chomp;
    # It is necessary to escape backslash (\) to (\backslash) char \
    s|\\\\|\Q\\backslash\E |g;
    # bsol& entity
    s/\Q\|[bsol\E  \Q]\|/\Q\\backslash\E /g;
    s/\\\|urlnam\\\|/ /g;
    s/\\\|refnam\\\|/ /g;

    if ( s/^-// ) {
      print $OUTFILE "-" . parse_data($_, $char_maps, $lyx_escape) . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get translated also
	$value = parse_data ($value, $char_maps, $lyx_escape);
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
      print $OUTFILE $_ . "\n";
    }
  }
  return 0;
};

# -----------------------------------------------------------------------
$lyx->{postASP} = sub {
# -----------------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# -----------------------------------------------------------------------
  my $INFILE         = shift;
  my $lyxfile        = "$global->{filename}.lyx";
  my $lyx_encodings  = {  "euc-kr" => "euc-kr",
			  "latin"  => "iso8859-1",
			  "latin1" => "iso8859-1",
			  "nippon" => "euc-jp",
			  "utf-8"  => "utf8"
    };
  my $inputenc = ( defined $lyx_encodings->{$global->{charset}} ) ?
    $lyx_encodings->{$global->{charset}} : "default" ;

  my $lyx_language  = ( defined $global->{language} ) ?
    ISO2English($global->{language}) : "default";
  $lyx_language  = "norsk" if ( $lyx_language eq "norwegian" );

  my @level_layout;
  my $indent_level   = -1;
  my $verb_last_line = "";
  my $verbatim       = 0;
  my $inlookchange   = 0;
  my $inheading;
  my $initem;
  my $intag;
  my $intt;
  my $tscreen;
  my $lyxout         = "#This file was created by LinuxDoc-SGML
#(conversion : Frank Pavageau and Jose' Matos)
\\lyxformat 2.15
\\textclass \@textclass\@
\\language $lyx_language
\\inputencoding $inputenc
\\fontscheme default
\\graphics default
\\paperfontsize default
\\spacing single
\\papersize Default
\\use_geometry 0
\\use_amsmath 0
\\paperorientation portrait
\\secnumdepth 3
\\tocdepth 3
\\paragraph_separation indent
\\defskip medskip
\\quotes_language default
\\quotes_times 2
\\papercolumns 1
\\papersides 1
\\paperpagestyle default\n";

  while( <$INFILE> ) {
    next if ( /^\s*$/ );
    chomp;

    if ( /^\@(article|book|report)\@/ ) {
      my $class = $1;
      $lyxout =~ s/\@textclass\@/$class/;
    } # Itemize; Enumerate and Description. $indent_level counts the level
    elsif( /^\@itemize\@/ ) {           # --- Itemized list begins
      $indent_level++;
      $level_layout[$indent_level] = "Itemize";
      $lyxout .= "\\begin_deeper\n" if ($indent_level);
    } elsif ( /^\@\/itemize\@/ ) {        # --- Itemized list ends
      $lyxout .= "\\end_deeper\n"   if ($indent_level);
      $indent_level--;
      if ( $initem ) {
	$initem = 0 unless ( $indent_level >= 0);
	$lyxout .= "\\layout Standard\n";
      }
    } elsif ( /^\@enumerate\@/ ) {        # --- Enumerated list begins
      $indent_level++;
      $level_layout[$indent_level] = "Enumerate";
      $lyxout .= "\\begin_deeper\n" if ($indent_level);
    } elsif( /^\@\/enumerate\@/ ) {       # --- Enumerated list ends
      $lyxout .= "\\end_deeper\n"   if ($indent_level);
      $indent_level--;
      if ( $initem ) {
	$initem = 0 unless ( $indent_level >= 0);
	$lyxout .= "\\layout Standard\n";
      }
    } elsif ( /^\@descrip\@/ ) {          # --- Description list begins
      $indent_level++;
      $lyxout .= "\\begin_deeper\n" if ($indent_level);
    } elsif( /^\@\/descrip\@/ ) {        # --- Description list ends
      $lyxout .= "\\end_deeper\n"   if ($indent_level);
      $indent_level--;
      if ( $initem ) {
	$initem = 0 unless ( $indent_level >= 0);
	$lyxout .= "\\layout Standard\n";
      }
    } elsif ( /^\@item\@/ ) {
      $lyxout .= "\\layout Standard\n" if $initem;
      $initem = 1;
      $lyxout .= "\\layout $level_layout[$indent_level]\n";
    } elsif( /^\@tag\@/ ) {
      $intag = 1;
      $lyxout .= "\\layout Description\n";
    } elsif( /^\@\/tag@/ ) {
      $intag = 0;
    } # tscreen
    elsif( /^\@tscreen\@/ ) {
      $tscreen = 1;
    } elsif ( /^\@\/tscreen\@/ ) {
      $tscreen = 0;
      $lyxout .= "\\layout Standard\n";
    } # Verbatim
    elsif( /^\@verb\@/ ) {
      $verbatim = 1;
    } elsif ( /^\@\/verb\@/ ) {
      $verbatim = 0;
    } else {
      $inheading    = 1 if ( /^\\layout (Part|Chapter|.*section|.*paragraph)/ );
      $inlookchange = 1 if ( m/^\\(family|series|shape)/ && ! m/default/ );
      $intt         = 1 if ( /^\\family typewriter.*$/ );

      # For LyX file clarity
      s/\\backslash/\n\\backslash\n/g unless ( $verbatim or $inheading or $intt);
      s/\s+/ /g unless ( $verbatim or $intt or $tscreen );

      if ( $intag ) {
	s/\s+/\n\\protected_separator\n/g unless m/^\\(family|series|shape)/;
      } elsif ( $tscreen ) {
	if ( $verbatim ) {
	  # If verbatim, there are no line breaks when things like
	  # <tt/../ appear.
	  $_ = "\\layout LyX-Code\n$_";
	} else {
	  # We do not want to have LyX-Code commands when line breaks
	  # are caused by look changing commands like
	  # \family .... This also applies to the line after
	  # \... default (so the $inlookchange == 2 hack below.)
	  $_ = "\\layout LyX-Code\n$_" unless $inlookchange;
	}
      } elsif ( $inheading) {
	s/\s+/ /g;
      }

      $inheading      = 0 if ( /^\\layout Standard/ );

      if ( /^\\family default.*$/ ) {
	$intt         = 0;
	# Signal for next line processing that this is an
	# end-look-change command
	$inlookchange = 2;
      } elsif ( $inlookchange == 2 ) {
	# Line previous to this one was an end-look-change command
	$inlookchange = 0;
      }


      $lyxout .= "$_\n";
    }
  }

  # Some cosmetic changes
  $lyxout =~ s/(\\layout Standard\n)+\\begin_deeper/\\begin_deeper\n\\layout Standard/gms;

  # Handle $lyx_afterslash_sep hack introduced in preNSGMLS filter
  # - Change occurrences related to abbreviated tags (e.g. <tt/../)
  $lyxout =~ s/\n$lyx_afterslash_sep\s*\n/\n /gms;
  # - Change occurrences related to plain trailing backslash
  #   (e.g. http://mydir/)
  $lyxout =~ s/\/$lyx_afterslash_sep\n/\/\n /gms;
  $lyxout =~ s/^ \\/\\/gms;
  $lyxout =~ s/(\\layout Standard\n)\s+/$1/gms;

  # Collapse multiple consecutive layout commands to the last one
  $lyxout =~ s/(\\layout \w+\n)+\\layout/\\layout/gms;

  # More cosmetic changes
  $lyxout =~ s/\\begin_deeper/\n\\begin_deeper/gms;
  $lyxout =~ s/\\end_deeper/\\end_deeper\n/gms;

  # Print result
  open (my $OUTFILE, "> $lyxfile")
    or die "fmt_lyx::postASP: Could not open \"$lyxfile\" for writing. Aborting ...";
  print $OUTFILE $lyxout;
  close $OUTFILE;

  return 0;
};

1;

__END__

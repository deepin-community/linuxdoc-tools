#
#  fmt_latex2e.pl
#
# ------------------------------------------------------------------
#  LaTeX-specific driver stuff
#
#  Copyright (C) 1994-1996, Matt Welsh
#  Copyright (C) 1996, Cees de Groot
#  Copyright (C) 1999-2002, Taketoshi Sano
#  Copyright (C) 1999, Kazuyuki Okamoto (euc-jp support in sgml2txt, sgml2html, and sgml2latex)
#  Copyright (C) 1999, Tetsu ONO (euc-jp support in sgml2txt, sgml2html, and sgml2latex)
#  Copyright (C) 2000, Juan Jose Amor (Support for PDF files)
#  Copyright (C) 2006-2020, Agustin Martin
# ------------------------------------------------------------------

package LinuxDocTools::fmt_latex2e;
use strict;

use LinuxDocTools::Utils qw(
  ldt_err_log
  ldt_log
  ldt_which
  );
use LinuxDocTools::CharEnts;
use LinuxDocTools::Vars;
use LinuxDocTools::Lang;

use File::Copy;

my $latex2e = {};
$latex2e->{NAME} = "latex2e";
$latex2e->{HELP} = "
  Note that this output format requires LaTeX 2e.

";
$latex2e->{OPTIONS} = [
		       { option => "output",
			 type => "l",
			 'values' => [ "dvi", "tex", "ps", "pdf" ],
			 short => "o" },
		       { option => "bibtex",
			 type => "f",
			 short => "b" },
		       { option => "makeindex",
			 type => "f",
			 short => "m" },
		       { option => "pagenumber",
			 type => "i",
			 short => "n" },
		       { option => "quick",
			 type => "f",
			 short => "q" },
		       { option => "dvips",
			 type => "l",
			 'values' => [ "dvips", "dvi2ps", "jdvi2kps" ],
			 short => "s" },
		       { option => "latex",
			 type => "l",
			 'values' => [ "latex", "hlatexp", "platex", "jlatex" ],
			 short => "x" },
		       { option => "verbosity",
			 type => "i",
			 short => "V" }
		       ];
$latex2e->{output}         = "tex";
$latex2e->{pagenumber}     = 1;
$latex2e->{quick}          = 0;
$latex2e->{bibtex}         = 0;
$latex2e->{makeindex}      = 0;
$latex2e->{makeindexopts}  = "";
$latex2e->{latex}          = "unknown";
$latex2e->{latexopts}      = "";
$latex2e->{dvips}          = "unknown";
$latex2e->{verbosity}      = -1;
$Formats{$latex2e->{NAME}} = $latex2e;

sub ldt_cat {
  my $file    = shift;

  open ( my $INPUT, "<$file")
    or print STDERR "ERROR: Could not open \"$file\" for read\n";
  while (<$INPUT>){
    print STDERR $_;
  }
  close $INPUT;
}

# ------------------------------------------------------------------
$latex2e->{preNSGMLS} = sub {
  # ----------------------------------------------------------------
  $global->{NsgmlsOpts} .= " -ifmttex ";
  my $msgheader = "fmt_latex2e::preNSGMLS";

  # NsgmlsPrePipe command
  my $NsgmlsPrePipe_command = "cat $global->{file} | sed 's/_/\\&lowbar;/g' ";
  ldt_log "  ${msgheader}::NsgmlsPrePipe_command\n    $NsgmlsPrePipe_command";

  $global->{NsgmlsPrePipe} = $NsgmlsPrePipe_command;
};

# extra `\\' here for standard `nsgmls' output
my %latex2e_escapes;
$latex2e_escapes{'#'} = '\\\\#';
$latex2e_escapes{'$'} = '\\\\$';
$latex2e_escapes{'%'} = '\\\\%';
$latex2e_escapes{'&'} = '\\\\&';
$latex2e_escapes{'~'} = '\\\\~{}';
$latex2e_escapes{'_'} = '\\\\_';
$latex2e_escapes{'^'} = '\\\\^{}';
$latex2e_escapes{'\\'} = '\\verb+\\+';
$latex2e_escapes{'{'} = '\\\\{';
$latex2e_escapes{'}'} = '\\\\}';
$latex2e_escapes{'>'} = '{$>$}';
$latex2e_escapes{'<'} = '{$<$}';	# wouldn't happen, but that's what'd be
$latex2e_escapes{'|'} = '{$|$}';

my $in_verb;
my $remove_comment; # added 2000 Jan 25 by t.sano

# ------------------------------------------------------------------
my $latex2e_escape = sub {
  # ----------------------------------------------------------------
  # passed to `parse_data' below in latex2e_preASP
  # ----------------------------------------------------------------
  my ($data) = @_;

  if (!$in_verb) {
    # escape special characters
    $data =~ s|([\#\$%&~_^\\{}<>\|])|$latex2e_escapes{$1}|ge;
  }

  return ($data);
};

# ------------------------------------------------------------------
$latex2e->{preASP} = sub {
# ------------------------------------------------------------------
#  Translate character entities and escape LaTeX special chars.
# ------------------------------------------------------------------
  my ($INFILE, $OUTFILE) = @_;

  # Note: `sdata_dirs' made an anonymous array to have a single argument
  my $tex_char_maps = load_char_maps ('.2tex', [ Text::EntityMap::sdata_dirs() ]);

  # ASCII char maps are used in the verbatim environment because TeX
  # ignores all the escapes
  my $ascii_char_maps = load_char_maps ('.2ab', [ Text::EntityMap::sdata_dirs() ]);
  $ascii_char_maps = load_char_maps ('.2l1b', [ Text::EntityMap::sdata_dirs() ]) if $global->{charset} eq "latin";

  my $char_maps = $tex_char_maps;

  # used in `latex2e_escape' anonymous sub to switch between escaping
  # characters from SGML source or not, depending on whether we're in
  # a VERB or CODE environment or not
  $in_verb = 0;

  # switch to remove empty line from TeX source or not, depending
  # on whether we're in a HEADING or ABSTRACT environment or not
  $remove_comment = 0;

  while (<$INFILE>) {
    if ( s/^-// ){
      chomp;
      s/^\\n/ /;          # Remove spurious leading \n (not real \\n)
      $_ = parse_data ($_, $char_maps, $latex2e_escape);
      if ($remove_comment){
	s/(\s+\\n)+//;
      }
      print $OUTFILE "-" . $_ . "\n";
    } elsif (/^A/) {
      /^A(\S+) (IMPLIED|CDATA|NOTATION|ENTITY|TOKEN)( (.*))?$/
	|| die "bad attribute data: $_\n";
      my ($name,$type,$value) = ($1,$2,$4);
      if ($type eq "CDATA") {
	# CDATA attributes get translated also
	if ($name eq "URL" or $name eq "ID" or $name eq "CA") {
	  # URL for url.sty is a kind of verbatim...
	  # CA is used in "tabular" element.
	  # Thanks to Evgeny Stambulchik, he posted this fix
	  # on sgml-tools list. 2000 May 17, t.sano
	  my $old_verb = $in_verb;
	  $in_verb = 1;
	  $value = parse_data ($value, $ascii_char_maps,
			       $latex2e_escape);
	  $in_verb = $old_verb;
	} else {
	  $value = parse_data ($value, $char_maps, $latex2e_escape);
	}
      }
      print $OUTFILE "A$name $type $value\n";
    } elsif (/^\((VERB|CODE)/) {
      print $OUTFILE $_;
      # going into VERB/CODE section
      $in_verb = 1;
      $char_maps = $ascii_char_maps;
    } elsif (/^\)(VERB|CODE)/) {
      print $OUTFILE $_;
      # leaving VERB/CODE section
      $in_verb = 0;
      $char_maps = $tex_char_maps;
    } elsif (/^\((HEADING|ABSTRACT)/) {
      print $OUTFILE $_;
      # empty lines (comment in sgml source) do harm
      # in HEADING or ABSTRACT
      $remove_comment = 1;
    } elsif (/^\)(HEADING|ABSTRACT)/) {
      print $OUTFILE $_;
      # leaving HEADING or ABSTRACT section
      $remove_comment = 0;
    } else {
      print $OUTFILE $_;
    }
  }
};

# ------------------------------------------------------------------
sub latex2e_defnam($) {
# ------------------------------------------------------------------
# return the string of the name of the macro for urldef
# ------------------------------------------------------------------
  my ($num) = @_;

  if ($num > 26*26*26) {
    die "Too many URLs!\n";
  }

  my $anum = ord("a");

  my $defnam = chr ($anum + ($num / 26 / 26)) .
    chr ($anum + ($num / 26 % 26)) .
    chr ($anum + ($num % 26));

  ldt_log "  fmt_latex2e::latex2e_defnam:\    num: $num, defnam: $defnam";
  return ($defnam);
};

# ------------------------------------------------------------------
sub latex2e_fine_tune_options {
  # ----------------------------------------------------------------
  # Set defaults and fine tune $latex2e->{latex,dvips,output}
  # ----------------------------------------------------------------
  my $latex2e = shift;
  my $msgheader = "fmt_latex2e::latex2e_fine_tune_options";

  ldt_log "  ${msgheader} general info before fine tuning:";
  ldt_log "    format: $global->{format}, charset: $global->{charset}, lang: $global->{language}";
  ldt_log "    latex: $latex2e->{latex}, dvips: $latex2e->{dvips}, output: $latex2e->{output}, verbosity: $latex2e->{verbosity}";

  # Set LaTeX verbosity if not explicitly set
  if ( $latex2e->{verbosity} == -1 ){
    $latex2e->{verbosity} = ( $global->{debug} ) ? 1 : 0;
  }

  # Fine tune $latex2e->{latex} for defaults
  if ( $latex2e->{latex} eq "unknown" ) {
    if ($global->{language} eq "ja"){
      if ($global->{charset} eq "utf-8") {
	$latex2e->{latex} = "uplatex";
      } else {
	$latex2e->{latex} = "platex";
      }
    } elsif ($global->{language} eq "ko") {
      if ($global->{charset} eq "utf-8") {
	$latex2e->{latex} = "pdflatex";
      } else {
	$latex2e->{latex} = "hlatexp";
      }
    } elsif ( $global->{language} =~ /^zh/ ) {
      die "$msgheader: Chinese requires utf-8. Aborting ...\n"
	unless ( $global->{'charset'} eq "utf-8" );
      $latex2e->{latex} = "xelatex";
    } else {
      $latex2e->{latex} = "latex";
    }
  }

  #  Fine tune $latex2e->{latex} and $latex2e->{latexopts} for special cases
  if ($latex2e->{latex} eq "hlatexp") {
    # for pdf: how about status?(for hlatex and hlatexp)
    $latex2e->{latex} = "hlatex";       # run hlatex if hlatexp is used
  } elsif  ($latex2e->{latex} eq "platex") {
    $latex2e->{latexopts} = "--kanji=euc"
  } elsif ( $latex2e->{latex} eq "latex" ){
    if ($latex2e->{output} eq "pdf" ) {
      $latex2e->{latex} = "pdflatex";
    }
  }

  # Fine tune $latex2e->{dvips} for defaults and special cases
  if ($latex2e->{dvips} eq "unknown") {
    if ($global->{language} eq "ja"){
      if ( $latex2e->{latex} eq "platex"
	   or
	   $latex2e->{latex} eq "uplatex"){
	$latex2e->{dvips}  = "dvipdfmx";
	# This sets output to pdf, but since behavior is dvips like we
	# need to cheat the program using "ps" not to break code
	# behind. This shoult be fixed in a cleaner way.
	if ( $latex2e->{output} eq "pdf" ) {
	  $latex2e->{output} = "ps";
	}
      } elsif ( $latex2e->{latex} eq "jlatex" ){
	$latex2e->{dvips} = "dvi2ps";
      } else {
	$latex2e->{dvips} = "dvips";
      }
    } else {
      $latex2e->{dvips} = "dvips";
    }
  }

  # Choose a sensible default if $latex2e->{bibtex} is set (to 1)
  if ( $latex2e->{bibtex} ) {
    if ( $latex2e->{latex} eq "platex" ){
      $latex2e->{bibtex} = "pbibtex";
    } elsif ( $latex2e->{latex} eq "uplatex" ) {
      $latex2e->{bibtex} = "upbibtex";
    } else {
      $latex2e->{bibtex} = "bibtex";
    }
  }

  # Choose a sensible default if $latex2e->{makeindex} is set (to 1)
  if ( $latex2e->{makeindex} ) {
    if ( $latex2e->{latex} eq "platex" ){
      $latex2e->{makeindex}     = "mendex";
      $latex2e->{makeindexopts} = "-E";
    } elsif ( $latex2e->{latex} eq "uplatex" ) {
      $latex2e->{makeindex}    = "mendex";
      $latex2e->{makeindexopts} = "-U";
    } else {
      $latex2e->{makeindex} = "makeindex";
    }
  }

  ldt_log "  ${msgheader} general info after fine tuning:";
  ldt_log "    format: $global->{format}, charset: $global->{charset}, lang: $global->{language}";
  ldt_log "    latex: $latex2e->{latex}, latexopts: $latex2e->{latexopts}, dvips: $latex2e->{dvips}";
  ldt_log "    bibtex: $latex2e->{bibtex}, makeindex: $latex2e->{makeindex}";
  ldt_log "    output: $latex2e->{output}, verbosity: $latex2e->{verbosity}";

  ldt_log "  Check if \"$latex2e->{latex}\" is available. ldt_which will fail otherwise";
  ldt_log "    ldt_which($latex2e->{latex}): " . ldt_which($latex2e->{latex})
    unless ( $latex2e->{output} eq "tex" );

  return $latex2e;
};

# -------------------------------------------------------------------
sub latex2e_clean_tmplatexdir {
  # -----------------------------------------------------------------
  # Clean LaTeX temporary directory
  # -----------------------------------------------------------------
  my $tmplatexdir = shift;
  my $tmplatexnam = shift;
  my $epsfiles    = shift;
  my $msgheader   = "fmt_latex2e::latex2e_clean_tmplatexdir";

  die "${msgheader}: tmplatexdir undefined or non existent: \"\"\n"
    unless ( -d $tmplatexdir );
  die "${msgheader}: tmplatexnam undefined.\n"
    unless ( $tmplatexnam );

  if ( $global->{debug} ){
    print "${msgheader}:\n"
      . " Temporary LaTeX files are in\n"
      . "  $tmplatexdir\n"
      . " Please check dir contents. They are to be removed manually.\n";
  } else {
    # ldt_log calls useful on LinucDocTools::Utils::remove_tmpfiles failure
    my @suffixes = qw(aux bbl blg dlog dvi idx ilg ind lof log lot out pdf ps tex toc);
    for my $suffix (@suffixes) {
      my $file = "$tmplatexnam.$suffix";
      if ( -e $file ) {
	ldt_log "    - Removing file \"$file\"";
	unlink "$file";
      }
    }
    # Clean epsf files if created
    for my $epsf ( @{$epsfiles} ) {
      my $tmpepsf = $tmplatexdir . "/" . $epsf;
      print $tmpepsf . "\n" if ( $global->{debug} );
      unlink ("$tmpepsf");
    }
    ldt_log "    - Removing dir \"$tmplatexdir\"";
    rmdir ($tmplatexdir) || return -1;
  }
};

# ------------------------------------------------------------------
$latex2e->{postASP} = sub
# ------------------------------------------------------------------
#  Take the sgmlsasp output, and make something useful from it.
# ------------------------------------------------------------------
{
  my $INFILE       = shift;
  my $OUTFILE;
  my $SGMLFILE;
  my $filename     = $global->{filename};
  my $tmplatexdir  = $global->{tmpbase} . "-latex-" . $$ . ".dir";
  my $tmplatexnam  = $tmplatexdir . "/" . $filename;
  my $msgheader    = "fmt_latex2e::postASP";
  my @epsfiles     = ();
  my @texlines     = ();
  my @urldefines   = ();
  my @urlnames     = ();
  my $urlnum       = 0;
  my $tmpepsf;
  my $saved_umask  = umask;
  $ENV{TEXINPUTS} .= ":$main::DataDir";

  umask 0077;
  mkdir ($tmplatexdir, 0700)
    or die "Could not create \"$tmplatexdir\" directory.\n";

  # Set defaults and fine tune $latex2e->{latex,dvips,output}
  $latex2e = latex2e_fine_tune_options($latex2e);

  # check epsfile is specified in source file
  {
    my $epsf;
    open $SGMLFILE, "<$filename.sgml";
    while (<$SGMLFILE>){
      # for epsfile
      if ( s/^\s*<eps\s+file=(.*)>/$1/ ) {
	s/\s+angle=.*//;
	s/\s+height=.*//;
	s/\"//g;
	$epsf = $_;
	chop ( $epsf );
	push @epsfiles, $epsf;
      }
      if ($latex2e->{output} eq "pdf") {
	if ( s/^\s*<img\s+src=(.*)>/$1/ ) {
	  s/\"//g;
	  $epsf = $_;
	  chop ( $epsf );
	  push @epsfiles, $epsf;
	}
      }
    }
    close $SGMLFILE;
  }

  # Parse TeX file and check nameurl specified in source file
  {
    my $urlid;
    my $urlnam;
    my $urldef;

    while (<$INFILE>){
      # Read TeX file
      push @texlines, $_;
      # and check for nameurl
      if ( /\\nameurl/ ){
	($urlid, $urlnam) = ($_ =~ /\\nameurl\{(.*)\}\{(.*)\}/);
	print $urlnum . ": " . $urlid . "\n" if ( $global->{debug} );

	$urldef = latex2e_defnam($urlnum) . "url";
	s/\\nameurl\{.*\}\{.*\}/\\emph{$urlnam} \\texttt{\\$urldef}/;
	push @urlnames, $_;
	push @urldefines, "\\urldef{\\$urldef} \\url{$urlid}\n";
	$urlnum++;
      }
    }
    close $INFILE;
  }

  # --------------------------------------------------------------------
  #  Set the correct \documentclass and packages options.
  # --------------------------------------------------------------------
  {
    my $hlatexopt = "";

    # Getting document class prefix
    my $classprefix = "";
    if ($global->{charset} eq "nippon") {
      if ($latex2e->{latex} eq "platex") {
	$classprefix = "j";
      } elsif ($latex2e->{latex} eq "jlatex") {
	$classprefix = "j-";
      }
    }

    # Getting class options
    my $classoptions = $global->{papersize} . 'paper';

    # Getting and setting latex language
    my $latex_language = ISO2English ($global->{language});
    my $use_babel      = 1;
    if (( not defined $global->{language} )
	||
	( $global->{language} =~ /^zh/  )
	||
	($global->{charset} eq "nippon")
	||
	($global->{charset} eq "euc-kr")
	||
	($global->{language} eq "ja" && $global->{charset} eq "utf-8")
      ){
      $use_babel = '';
    }
    ldt_log "  ${msgheader} general info:";
    ldt_log "    format: $global->{format}, charset: $global->{charset}, lang: $global->{language}";
    ldt_log "    latex: $latex2e->{latex}, classprefix: $classprefix, latex_language: $latex_language, use_babel: $use_babel";

    open ($OUTFILE, "> $tmplatexnam.tex")
      or die "fmt_latex2e::postASP: Could not open \"$tmplatexnam.tex\" for write.\n";

    # Loop over the TeX file
    my $inpreamble = 1;
    while (defined($texlines[0])) {
      $_ = shift @texlines;

      if ( $inpreamble ) {
	if (/%end-preamble/) {
	  $inpreamble = '';

	  if ($latex2e->{pagenumber}) {
	    $_ = $_ . '\setcounter{page}{' .
	      $latex2e->{pagenumber} .
	      "}\n";
	  } else {
	    $_ = $_ . "\\pagestyle{empty}\n";
	  }

	  # Now include the explicitly added stuff
	  $_ = $_ . $global->{pass} . "\n" if ($global->{pass});

	  print $OUTFILE $_;

	  # Add to preamble url definitions for \urldef
	  if ($urlnum && $latex2e->{output} ne "pdf") {
	    foreach my $thisurl ( @urldefines ) {
	      print $OUTFILE $thisurl;
	    }
	  }
	} else {   # -- Not in last line of linuxdoc-tools added preamble
	  # Set correct class name and options in the header
	  if (/^\\documentclass\[\@CLASSOPTIONS\@\]/) {
	    s/\@(ARTICLE|REPORT|BOOK)\@/$classprefix . lc($1)/e;
	    s/\@CLASSOPTIONS\@/$classoptions/;
	    $_ = $_ . "\\makeindex\n" if ($latex2e->{makeindex});
	  }
	  # Set correct DTD name
	  elsif (/^\\usepackage\{\@LINUXDOC_DTD\@-sgml\}/) {
	    my $dtd = $global->{"dtd"};
	    s/\@LINUXDOC_DTD\@/$dtd/;
	  }
	  # Set correct language package and babel options if needed
	  elsif (/^\@\@LANG_PACKAGE\@\@/) {
	    if ( $global->{'language'} eq "zh_CN" ){
	      s/\@\@LANG_PACKAGE\@\@/\\usepackage\[UTF8\]\{ctex\}/;
	    } elsif ($latex2e->{latex} eq "platex") {
	      s/\@\@LANG_PACKAGE\@\@/\\UseRawInputEncoding/;
	    } elsif ( $global->{'language'} eq "ko" ){
	      my $ko_langpkg;
	      if ( $global->{'charset'} eq "utf-8" ){
		$ko_langpkg = "\\usepackage{kotex}";
	      } elsif ($global->{charset} eq "euc-kr"){
		my $hlatexopt = ($latex2e->{latex} eq "hlatexp") ?
		  "[noautojosa]" : "";
		$ko_langpkg ="\\usepackage" . "$hlatexopt" . "{hangul}";
	      }
	      s/\@\@LANG_PACKAGE\@\@/$ko_langpkg/;
	    } elsif ( $use_babel ) {
	      s/\@\@LANG_PACKAGE\@\@/\\usepackage\[$latex_language\]\{babel\}/;
	    } else {
	      s/^/%%/;
	    }
	  }

	  # Deal with input encoding
	  elsif ( /\\usepackage\[\@CHARSET\@\]\{inputenc\}/ ) {
	    if ( $global->{charset} eq "latin" ) {
	      s/\@CHARSET\@/latin1/;
	    } elsif ( $global->{charset} eq "utf-8" ) {
	      s/\@CHARSET\@/utf8/;
	    } else {
	      s/^/%%/;
	    }
	  }
	  # nippon or euc-kr do not use T1 encoding
	  elsif ( (/\\usepackage\[T1\]\{fontenc\}/)    &&
		  ( ($global->{charset} eq "nippon")   ||
		    ($global->{charset} eq "euc-kr"))) {
	    s/^/%%/;
	  }
	  print $OUTFILE $_;
	}
      } else {   # -- Not in linuxdocsgml added preamble
	#
	if (/\\nameurl/ && $latex2e->{output} ne "pdf") {
	  $_ = shift @urlnames;
	}
	print $OUTFILE $_;
      }
    }
  }
  close $OUTFILE;

  #  LaTeX, dvips, and assorted cleanups.
  if ($latex2e->{output} eq "tex") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.tex" ) {
    #          rename ("$filename.tex", "$filename.tex.back");
    #      }

    umask $saved_umask;
    copy ("$tmplatexnam.tex", "$filename.tex");
    latex2e_clean_tmplatexdir($tmplatexdir,$tmplatexnam,\@epsfiles);
    return 0;
  }

  # Run LaTeX in nonstop mode so it won't prompt & hang on errors.
  # Default behavior is to supress LaTeX output on all passes, unless
  # error, to avoid large number of spurious warnings.
  # With --verbosity=1 (-V 1) it will be shown info about last run,
  # once references have been resolved. With '2' info about all passes
  # will be shown.

  my $current_dir;
  chop ($current_dir = `pwd`);
  print $current_dir . "\n" if ( $global->{debug} );

  # copy epsfiles specified in tex file
  for my $epsf ( @epsfiles ) {
    $tmpepsf = $tmplatexdir . "/" . $epsf;
    print $epsf . " " . $tmpepsf . "\n" if ( $global->{debug} );
    copy ("$epsf", "$tmpepsf") or die "can not copy graphics\n";
  }

  # go to the temporary directory
  chdir ($tmplatexdir);

  # Prepare actual LaTeX run(s)
  my ($latexcommand) = "$latex2e->{latex} $latex2e->{latexopts} '\\nonstopmode\\input{$filename.tex}'";
  ldt_log "  ${msgheader}:latexcommand\n    $latexcommand";

  # Control verbosity for the different LaTeX runs
  my $latex1suppress  = ' >/dev/null';
  my $latex2suppress  = ' >/dev/null';
  my $latex3suppress  = "";
  my $bibtexsuppress  = "";
  my $makeindexsuppress  = "";

  if ( $latex2e->{verbosity} > 1  ) {
    $latex1suppress  = "";
    $latex2suppress  = "";
  } elsif ( $latex2e->{verbosity} == 0 ) {
    $latex3suppress = ' >/dev/null';
    $bibtexsuppress =  ' >/dev/null';
    $makeindexsuppress =  ' >/dev/null';
  } elsif ( $latex2e->{quick} ) {
    $latex1suppress  = "";
  }

  unless ( system ($latexcommand . $latex1suppress) == 0 ){
    ldt_cat("$filename.log") unless ( $latex1suppress eq "" );
    die "$msgheader: LaTeX first run problem. Aborting ...\n";
  }

  # Run bibtex if --bibtex option is set.
  if ( $latex2e->{bibtex} ) {
    my $bibtex_command = "$latex2e->{bibtex} $filename";
    ldt_log "  ${msgheader}:bibtex_command\n    $bibtex_command";
    system ( $bibtex_command . $bibtexsuppress ) == 0
      or print STDERR "$msgheader: Problems running \"$latex2e->{bibtex}\". Ignoring ...\n";
  } else {
    ldt_log "  ${msgheader}: bibtex disabled";
  }

  # Second and third run
  unless ( $latex2e->{quick} ){
    ldt_log "  ${msgheader}: Starting laTeX second run.";
    system ($latexcommand . $latex2suppress) == 0
      or die "$msgheader: LaTeX second run problem. Aborting ...\n";
    if ( $latex2e->{makeindex} ) {
      ldt_log "  ${msgheader}: Starting makeindex run.";
      my $idx_filename = "$filename.idx";
      my $makeindex_command = "$latex2e->{makeindex} $latex2e->{makeindexopts} $idx_filename";
      ldt_log "  ${msgheader}:makeindex_command\n    $makeindex_command";
      if ( -e "$idx_filename" ) {
	system ( $makeindex_command . $makeindexsuppress ) == 0
	  or print STDERR "$msgheader: Problems running  $latex2e->{makeindex}. Ignoring ...\n";
      } else {
	ldt_err_log "  ${msgheader}: \"$idx_filename\" not found. Skipping makeindex step.";
      }
    } else {
      ldt_log "  ${msgheader}: makeindex disabled.";
    }
    ldt_log "  ${msgheader}: Starting LaTeX third run.";
    system ( $latexcommand . $latex3suppress) == 0
      or die "$msgheader: LaTeX third run problem. Aborting ...\n";
  }

  # go back to the working directory
  chdir ($current_dir);

  # output dvi file
  if ($latex2e->{output} eq "dvi") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.dvi" )
    #        {
    #          rename ("$filename.dvi", "$filename.dvi.back");
    #        }
    umask $saved_umask;
    copy ("$tmplatexnam.dvi", "$filename.dvi");
    latex2e_clean_tmplatexdir($tmplatexdir,$tmplatexnam,\@epsfiles);
    return 0;
  }

  # output pdf file
  if ($latex2e->{output} eq "pdf") {
    # comment out, because this backup action is not documented yet.
    #
    #      if ( -e "$filename.pdf" )
    #         {
    #          rename ("$filename.pdf", "$filename.pdf.back");
    #        }
    umask $saved_umask;
    copy ("$tmplatexnam.pdf", "$filename.pdf");
    latex2e_clean_tmplatexdir($tmplatexdir,$tmplatexnam,\@epsfiles);
    return 0;
  }

  # convert dvi into ps using dvips command
  chdir ($tmplatexdir);
  my $dvips_command_line;
  if ($latex2e->{dvips} eq "dvipdfmx") {
    # dvipdfmx really produces pdf
    $dvips_command_line = "dvipdfmx -q -p $global->{papersize} -o $tmplatexnam.pdf $filename.dvi";
  } elsif ($latex2e->{dvips} eq "dvi2ps") {
    $dvips_command_line = "dvi2ps -q -o $global->{papersize} -c $tmplatexnam.ps $filename.dvi";
  } elsif ($latex2e->{dvips} eq "jdvi2kps") {
    $dvips_command_line = "jdvi2kps -q -pa $global->{papersize} -o $tmplatexnam.ps $filename.dvi";
  } else {
     $dvips_command_line = "dvips -R -q -t $global->{papersize} -o $tmplatexnam.ps $filename.dvi";
  }
  ldt_log "  ${msgheader}::dvips_command_line\n    $dvips_command_line";
  `$dvips_command_line`;
  chdir ($current_dir);

  # comment out, because this backup action is not documented yet.
  #
  #   if ( -e "$filename.ps" )
  #    {
  #      rename ("$filename.ps", "$filename.ps.back");
  #    }
  umask $saved_umask;
  if ($latex2e->{dvips} eq "dvipdfmx"){
    copy ("$tmplatexnam.pdf", "$filename.pdf");
    unlink ("$tmplatexnam.pdf");
  } else {
    copy ("$tmplatexnam.ps", "$filename.ps");
    unlink ("$tmplatexnam.ps");
  }
  latex2e_clean_tmplatexdir($tmplatexdir,$tmplatexnam,\@epsfiles);
  return 0;
};

1;

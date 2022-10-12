/* -*- c -*- */

/* Butchered version of html2html.l to post-process RTF files
 *
 * Steve Tynor (tynor@atlanta.twr.com). I'm not proud of this code. It's a hack
 * foisted upon a hack, nested within another hack or two.  It sort of works
 * well enough for my purposes (generating WinHelp .RTF files for my documents),
 * but it could definitely use a redesign/rewrite. I shamelessly blame the RTF
 * format for most of the hackery here -- RTF is not a _language_ like LaTeX or
 * ROFF -- it's just a file format. So, we can't rely on RTF to do even simple
 * things like "insert a paragraph break here only if the previous token was not
 * also a paragraph break. Since the SGML front end has no conditional processing
 * capabilities, multiple blank likes in the SGML get translated to multiple para
 * breaks in the RTF (actually, that's why I use the <@@par> crap....).
 *
 * XREF: BROKEN_DELIMITERS:  We say "{}K{\footnote .." instead of just
 * "\nK{\footnote .." since the MicroS$ft RTF parser does not (always?) treat
 * white space as a delimeter before a hyperlink markup.
 *
 * ESR reordered the @@indent rules to eliminate a generation-time warning.
 */

%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* #define DEBUG */

  /* NOTE: must be kept in sync with the <p></p> defs in mapping */
#define LEFTMARGIN 500
#define NEWPAR "\\par\\pard\\plain\\li500\\sb200\\fi0"
#define INDENT_AMT 500 /* twips for each level of indentation */

const static char* header =
    "{\\rtf1\\ansi\n"
    "{\\fonttbl\n"
    "{\\f0\\fswiss Helvetica;}\n"
    "{\\f1\\fmodern Courier;}\n"
    "{\\f2\\froman Times;}\n"
    "{\\f3\\froman Symbol;}\n"
    "}\n"
    "{\\info{\\comment Translated from SGML to RTF w/ Linuxdoc-SGML}}\n"
    ;

int big_page_mode = 1; /* default is backwards compatible */

/* <report> style uses <chapt> as the top-level section; <article> uses
   <sect>.  We need to know whether a <sect> should be numbered as "n"
   or "n.m".  We assume <article> more unless we see a <chapt> */
int chapter_mode = 0;
int section_id = 0; /* used for TOC hyperlinks */
int in_appendix = 0;

FILE *out;
FILE *idx_fp;

char buf[2048], sectname[256], labeltxt[256];
char firstname[256], outname[262];
char ssectname[256], Tmp1[4096], Tmp2[256], headname[256];
char urlname[256], Headbuf[4096], refname[256];

int indent = 0;
int nofill = 0;
int filenum = 1;
int filecount = 1;
int tmpfn;
int secnr = 0;
int ssecnr;
int current;
int skipnewline = 0;

extern char *yytext;

#if (YY_FLEX_MAJOR_VERSION == 2 && YY_FLEX_MINOR_VERSION == 5 && YY_FLEX_SUBMINOR_VERSION > 35) \
 || (YY_FLEX_MAJOR_VERSION == 2 && YY_FLEX_MINOR_VERSION == 6 && YY_FLEX_SUBMINOR_VERSION == 0)
extern yy_size_t yyleng;
#else
extern int yyleng;
#endif

#define CHAPTER 1
#define SECTION 2
#define SUBSECT 3

void fatal_perror ( char *fmt, char *arg )
  {
    fprintf( stderr, "rtf2rtf: Fatal: " );
    fprintf( stderr, fmt, arg);
    perror( "\nReason");
    exit(1);
  }

int getstr( char *str, int n )
  {
#ifdef DEBUG
    fprintf( stderr, "DEBUG: yytext: <<%s>>\n", yytext );
#endif
    if( strlen( yytext ) == n )
      return 0;
    strncpy( str, yytext+n, yyleng-n);
    str[ yyleng-n ] = 0;
    return 1;
  }

void
put_reference (FILE *fp, char *str)
  {

    char *p;
    char buf[2] = {0, 0};
    /* trim trailing spaces: */
    while (str[strlen(str)-1] == ' ') {
      str[strlen(str)-1] = '\0';
    }
    /* replace non-legal topic-id characters with underscores */
    p = str;
    while (*p) {
      buf[0] = *p;
      if (! strpbrk(buf,
		    "abcdegfhijklmnopqrstuvwxyz"
		    "ABCDEGFHIJKLMNOPQRSTUVWXYZ"
		    "0123456789")) {
	fprintf (fp, "_");
      } else {
	fprintf (fp, "%c", *p);
      }
      p++;
    }
  }

void
put_secnum (FILE *fp, int s1, int s2)
  {
    if (in_appendix) {
      if (s2 == 0) {
	fprintf (fp, "%c", 'A'-1+s1);
      } else {
	fprintf (fp, "%c.%d", 'A'-1+s1, s2);
      }
    } else {
      if (s2 == 0) {
	fprintf (fp, "%d", s1);
      } else {
	fprintf (fp, "%d.%d", s1, s2);
      }
    }
  }

void
heading (char *str, int s1, int s2, int newpage)
   {
     if (newpage && (out == stdout))
       {
	 sprintf (outname, "%s-0.rtf", firstname);
	 out = fopen (outname, "w");
	 if (! out )
	   {
	     fatal_perror ("Could not open file \"%s\"", outname);
	   }
    	 fputs (header, out);
       }

     /*     fprintf (out, "\n\\page{\\pard\\plain\\s2\\f0\\fs%d\\b\\fi0\\li576\\sb160\\sa160\\tx576 { }",
	    (s2==0 ? 36 : 24) ); */

     if (newpage)
       {
	 fprintf (out, "\n\\page{\\pard\\plain\\keepn\\f0\\fs%d\\b\\tx576{",
		  (s2==0 ? 36 : 24) );
       }
     else
       {
	 fprintf (out, "\n{\\pard\\sb200\\plain\\f0\\fs%d\\b\\tx576{",
		  (s2==0 ? 36 : 24) );
       }
     put_secnum (out, s1, s2);
     fprintf (out, " %s}}", str);

     /* Used as a target for the link on the TOC page. Use a SECT_ prefix
	just in case the document has any explicit <label>'s with the same
	`id' as a section header */
     /* XREF: BROKEN_DELIMITERS: See above for why we say "{}#{\footnote .."
      * instead of just "\n#{\footnote ..".
      */
     fprintf (out, "\n{}#{\\footnote TOC_%d}\n", section_id);
     if (newpage)
       {
	 fprintf (out, "\n${\\footnote ");
	 put_reference (out, str);
	 fprintf (out, "}\n");
	 fprintf (out, "+{\\footnote browse}\n");
	 fprintf (out, "%s\n", NEWPAR);
       }
     /* XREF: BROKEN_DELIMITERS: See above for why we say "{}K{\footnote .."
      * instead of just "\nK{\footnote ..".
      */
     fprintf (out, "{}K{\\footnote %s}\n", str);
/*     fprintf (out, "\\par\\pard\n");*/

     fprintf (idx_fp, "\\li%d\\fi-200{\\f3\\\'B7} ",
	      (s2==0 ? 1 : 2) * 500);
     put_secnum (idx_fp, s1, s2);
     fprintf (idx_fp, " {\\uldb ");
     fprintf (idx_fp, "%s}{\\v TOC_%d}\\par\n", str, section_id);
     section_id++;
   }

void
subheading (char *str, int chapter_size)
  {
    /*     fprintf (fp, "\n{\\pard\\plain\\s2\\f0\\fs%d\\b \\fi0\\li576\\sb160\\sa160\\tx576 { }%s}\n",
	   (chapter_size ? 36 : 24), str);*/

    fprintf (out, "\n{\\pard\\plain\\f0\\sb200\\fs%d\\b\\tx576{%s}}\n",
	     (chapter_size ? 36 : 24), str);
     /* XREF: BROKEN_DELIMITERS: See above for why we say "{}K{\footnote .."
      * instead of just "\nK{\footnote ..".
      */
    fprintf (out, "{}K{\\footnote %s}%s\n", str, NEWPAR);
  }

%}

%s SECT

%%

"<@@indent+>\n"		{ indent++; }
"<@@indent->\n"		{ indent--; }
"<@@indent>\n"		{ fprintf( out, "\\li%d{}", LEFTMARGIN+indent*INDENT_AMT); }

(\\par\\pard\\plain\n"<@@indent>"\n\\sb200\\fi0\n)+ {
  /* HACK: Filter out redundant paragraph marks. I'd rather not put them
   * in in the first place, but it's just TOO HARD.
   */
  fprintf (out, "\\par\\pard\\plain\n\\li%d{}\n\\sb200\\fi0\n",
	   LEFTMARGIN+indent*INDENT_AMT);
}

(("<@@par>"\n)|("<@@indent"[\+\-]">"\n))+ {
  /* Unfortunately, <@@par>'s and <@@indent+>'s get mixed together at the start
   * of <itemize>'s and <descrip>'s.  This hack allows us to treat them as a
   * single <@@par>.
   *
   * Adjust the indentation based on the number of <@@indent+/->'s we see
   */
  char *p = yytext;
  while (*p) {
    if (*p == '+') {
      indent++;
    } else if (*p == '-') {
      indent--;
    }
    p++;
  }
  fprintf (out, "\\par\\pard\\plain\n\\li%d{}\n\\sb200\\fi0\n",
	   LEFTMARGIN+indent*INDENT_AMT);
}

^"<@@chapt><@@head>".*$		{
  chapter_mode = 1;
  /*    skipnewline=1; */
  getstr( sectname, 17 ) ;
  current=SECTION;
  secnr++;
  ssecnr=0;
  heading( sectname, secnr, 0, 1);

}

^"<@@sect><@@head>".*$		{

  /*    skipnewline=1; */
  if (chapter_mode)
    {
      getstr( ssectname, 16 ) ;
      current=SECTION;
      ssecnr++;
      heading( ssectname, secnr, ssecnr, !big_page_mode);
    }
  else
    {
      getstr( sectname, 16 ) ;
      current=CHAPTER;
      secnr++;
      ssecnr=0;
      heading( sectname, secnr, 0, 1);
    }
}

^"<@@ssect><@@head>".*$		{
  /*    skipnewline=1;*/
  getstr( ssectname, 17 ) ;
  current=SUBSECT;
  if (! chapter_mode)
    {
      ssecnr++;
      heading( ssectname, secnr, ssecnr, !big_page_mode );
    }
  else
    {
      current=SUBSECT;
      subheading( ssectname, 0 );
    }
}


^"<@@appendix>".*$		{
  in_appendix = 1; secnr=0; ssecnr=0;
  fprintf (idx_fp, "\\par\\pard\\qc{\\b Appendix}\\par\\pard\n");
}

^"<@@part><@@head>".*$		{
  fprintf (idx_fp, "\\par\\pard\\qc{\\b %s}\\par\\pard\n", yytext+16);
}

^"<@@head>".*$		{

  /*  skipnewline=1; */
  getstr( ssectname, 8 ) ;
  current=SUBSECT;
  subheading( ssectname, 0 );
}

^"<@@label>".*$		{

     /* XREF: BROKEN_DELIMITERS: See above for why we say "{}K{\footnote .."
      * instead of just "\nK{\footnote ..".
      */
  fprintf (out, "{}#{\\footnote ");
  put_reference (out, yytext+9 );
  fprintf (out, "}\n");
/* Grrr.  WinHelp uses K footnotes for references from without the .HLP file */
/* (e.g. via the WinHelp API) */
  fprintf (out, "{}K{\\footnote ");
  put_reference (out, yytext+9 );
  fprintf (out, "}\n");
}

^"<@@title>".*$		{

  /*    skipnewline=1;*/
  getstr( ssectname, 9 ) ;
  subheading( ssectname, 1 );
}

"<@@nofill>\n"		{ indent++; nofill = 1; fprintf( out, "\\par\\pard\\sb200\\keep\\li%d{}", LEFTMARGIN+indent*INDENT_AMT); }
"<@@endnofill>\n"	{ indent--; nofill = 0; fprintf( out, "\\par\\pard\\sb200\\li%d{}", LEFTMARGIN+indent*INDENT_AMT); }

..*			{

  if (skipnewline) {
    /*    strcat(Headbuf, yytext ); */
  } else if( out != stdout ) {
    fprintf( out, "%s", yytext );
  } else {
    ECHO;
  }
}

\n			{

/*  fprintf( out, " ");*/		/* Add a space at the end of each line since RTF does
				   not treat EOL as whitespace and will concatenate
				   tokents spanning lines */
  if (nofill)
    {
      fprintf( out, "\\line");
    }
  if(!skipnewline)
    {
      if( out != stdout )
	{
	  fprintf( out, "%s", yytext );
	}
      else
	{
	  ECHO;
	}
    }
}


%%

int
main( int argc, char **argv )
{
  int i;

  out = stdout;
  idx_fp = stdout;

  strcpy( firstname, "RTF" );

  for (i = 1; i < argc; i++)
    {
      if (0 == strcmp("-2", argv[i]))
	{
	  big_page_mode = 0;
	}
      else if (argv[i][0] != '-')
	{
	  strncpy( firstname, argv[i], 256 );
	}
      else
	{
	  fprintf (stderr,
		   "%s: Warning: unhandled command line option \"%s\"\n",
		   argv[0], argv[i]);
	}
    }

  fputs (header, out);
  fprintf (out, "+{\\footnote browse}\n");


  secnr=0;
  yylex();

  if( out != stdout )
    {
      fclose( out );
    }

  fputs ("\n}\n", idx_fp);
  fclose( idx_fp );

  exit( 0 );
}

/* Use the existing indentation style:
 Local variables:
 c-indent-level: 2
 c-continued-statement-offset: 2
 c-brace-offset: 0
 c-label-offset: -2
 End:
 */

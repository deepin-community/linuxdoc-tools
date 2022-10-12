%{
/*
 * sgmlpre -- handle SGML conditionalization for SGML-tools
 *
 * by Eric S. Raymond <esr@thyrsus.com>, 3 Nov 1997
 *
 * Filter SGML according to conditionalizing markup.  Argument/value pairs
 * from the command line are matched against the attributes of <#if> and
 * <#unless> tags.  Spans between <#if>/</#if> are passed through unaltered
 * if there is no attribute mismatch; spans between <#unless></#unless> are
 * passed if there is at least one attribute mismatch.  An attribute mismatch
 * happens  if an attribute occurs in both the command-line arguments and the
 * tag, but the values do not match.  Value matching is by string equality,
 * except that "|" is interpreted as an alternation character.  Even if a span
 * is not passed through, its newlines are (this to avoid messing up the
 * line  numbers in error messages).
 *
 * This lexer requires flex.  Limitations; attribute names may only be
 * 256 chars long, values may be only 16384 (YY_BUF_SIZE) characters long.
 * Doesn't do checking that only </if> matches <if> and </unless> matches
 * <unless> (that would need a stack and introduce another limit).
 */
#include <string.h>

#define TRUE	1
#define FALSE	0

static char **selections;	/* selection tokens */
static int nselections;		/* number of selections */
static int nest;		/* how deep are we nested? */
static int ifsense;		/* sense of last `if' or unless seen */
static int firstoff;		/* nesting depth of first turnoff */
static char attribute[256];	/* last attribute scanned */

static int value_match(char *valu, char *against)
/* return TRUE if values match (handles alternation syntax) */
{
    char *vp, *ap;
    int vn, an;

#ifdef DEBUG
    printf("<%s, %s>", valu, against);
#endif /* DEBUG */

    for (vp = valu; *vp; vp += vn)
    {
	vn = strcspn(vp, "|");
	for (ap = against; *ap; ap += an)
	{
	    an = strcspn(ap, "|");
	    if (an == vn && memcmp(ap, vp, an) == 0)
		return(TRUE);
	    if (ap[an] == '|')
		an++;
	}
	if (vp[vn] == '|')
	    vn++;
    }

    return(FALSE);
}

static int restrictP(char *attr, char *valu)
/* does a given attribute/value pair turn off inclusion? */
{
    int	i;

#ifdef DEBUG
    printf("(%d, %s, %s)", nest, attr, valu);
#endif /* DEBUG */
    for (i = 0; i < nselections; i++)
    {
	int eqoffset = strcspn(selections[i], "=");

	if (strncasecmp(selections[i], attr, eqoffset) == 0)
	    if (!value_match(valu, selections[i] + eqoffset + 1))
		return(TRUE);
    }

    return(FALSE);
}

%}

ATTRIBUTE	[a-z][a-z0-9]*
WORD		[a-z][a-z0-9_]*
STRING		\"[^"]*\"
WS		[ \t\n]*

%option caseless
%x attrib val

%%
<INITIAL>\<\#if{WS}	{BEGIN(attrib); ifsense = TRUE;  ++nest;}
<INITIAL>\<\#unless{WS}	{BEGIN(attrib); ifsense = FALSE; ++nest;}

<INITIAL>"</#if>"|"</#unless>"	{if (firstoff == nest) firstoff = 0; --nest;}

<attrib>{ATTRIBUTE}		{strncpy(attribute,yytext,sizeof(attribute));}
<attrib>=			{BEGIN(val);}
<attrib>\>			{BEGIN(INITIAL);}

<val>{WORD}			{
				    if (restrictP(attribute, yytext) == ifsense)
					firstoff = nest;
				    BEGIN(attrib);
				}
<val>{STRING}			{
				    yytext[strlen(yytext)-1]='\0';
				    if (restrictP(attribute, yytext+1) == ifsense)
					firstoff = nest;
				    BEGIN(attrib);
				}
<val>\>				{
				    fprintf(stderr,
					"sgmlpre: > where value expected\n");
				    exit(1);
				}

<INITIAL>.			{
				    if (!firstoff && yytext[0] != '\n')
					putchar(yytext[0]);
				}

%%
#include <string.h>

int yywrap() {exit(0);};

int main(int argc, char *argv[])
{
    int i;

    selections = argv + 1;
    nselections = argc - 1;

    for (i = 0; i < nselections; i++)
        if (strchr(selections[i], '=') == 0)
	{
	    fprintf(stderr, "sgmlpre: malformed argument %d\n", i);
	    exit(1);
	}

    yylex();
}

/* sgmlpre.l ends here */

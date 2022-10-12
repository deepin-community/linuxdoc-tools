################################################################################
#
# $Id: Makefile,v 1.1.1.1 2001/05/24 15:57:40 sano Exp $
#
################################################################################

# Name des aktuellen Subdirectory's und Version der Software
PACKAGE	=

SHELL	= /bin/sh

################################################################################
#                                                                              #
#                    Start of system configuration section.                    #
#                                                                              #
################################################################################


################################################################################
#                                                                              #
#                              Implicit Rules                                  #
#                                                                              #
################################################################################


# ETEX 2 GIF
%.gif: %.etex
	wrapetex $< | latex | dvips f | pstogif

# GIF 2 EPS
%.eps: %.tif
	tiff2ps $< > $@

%.tif: %.gif
	gif2tiff $< $@

%.txt:  %.sgml
	sgml2txt $<

%.tex:	%.sgml
	sgml2latex -d $<

%.dvi:	%.sgml
	sgml2latex $<

%.info: %.sgml
	sgml2info $<

%.ps:	%.dvi
	dvips $<

%.html:	%.sgml
	sgml2html $<


# Test suite, more to come.
all:	ldoc97 sgmlt ldocs


# Checking Linuxdoc96 (Strict)
ldoc97: minimal sample \
	entity section lists glossary96

# Checking Linuxdoc97 (Extended)
sgmlt:  glossary code math tables picture citation \
	appendix refs notes

# Documentation
ldocs:    example guide aspdoc

# Work in progress
work:    unsupp


clean:
	rm -f *.html *.tex *.txt *.dos *.dvi *.ps *~
	rm -f *.info *.glo *.aux *.log

#
# Test files
#
minimal:   minimal.ps minimal.html minimal.txt minimal.info
sample:	   sample.ps sample.html sample.txt sample.info
entity:	   entity.ps entity.html entity.txt entity.info
section:   section.ps section.html section.txt section.info
lists:     lists.ps lists.html lists.txt lists.info

glossary96:	\
	   glossary96.html glossary96.ps glossary96.txt glossary96.info



glossary:  glossary.html glossary.ps glossary.txt glossary.info
appendix:  appendix.html appendix.ps appendix.txt appendix.info
notes:     notes.html notes.ps notes.txt notes.info

tables:    tables.ps tables.html tables.txt tables.info
code:	   code.html code.ps code.txt code.info
refs:	   refs.html refs.ps refs.txt refs.info

math:	   math.etex f.etex \
	   math.html math.ps math.txt math.info


picture:   picture.eps picture.gif \
	   small_picture.eps small_picture.gif \
	   picture.ps picture.html picture.txt picture.info \

citation:  sgmltool.bib bibtex.bib \
	   citation.ps citation.html citation.txt citation.info


#
# These might fail.
#
subdoc:	   subdoc.html subdoc.ps subdoc.txt subdoc.info
test:	test.eps test.ps test.html test.txt test.info
unsupp:	 unsupp.ps unsupp.html unsupp.txt unsupp.info

#
# Linuxdoc SGML stuff, temporary
#
example: example.ps example.html example.txt example.info
guide:	guide.ps guide.html guide.txt guide.info
aspdoc:	aspdoc.ps aspdoc.html aspdoc.txt aspdoc.info

howto:  howto.ps howto.html howto.txt howto.info

#
# Kludge, kludge
#
SGMLT=/usr/local/lib/sgml-tools/
archive:
	rm -f test/*
	cp -a Makefile *.sgml *.gif *.bib *.eps *.etex  test/
	rm -f test.tgz
	tar -zcvf test.tgz test
	cat test.tgz | uuencode test.tgz > test.uue

dtd:
	rm -f dtd/*
	cp -a $(SGMLT)/dtd/*  dtd/
	rm -f dtd.tgz
	tar -zcvf dtd.tgz dtd
	cat dtd.tgz | uuencode dtd.tgz > dtd.uue


#	rm -f fixed/*
#	cp -a $(SGMLT)/rep/html/mapping fixed/html.mapping
#	cp -a $(SGMLT)/rep/latex2e/mapping  fixed/latex2e.mapping
#	cp -a $(SGMLT)/linuxdoc-sgml.sty     fixed/
#	cp -a $(SGMLT)/fmt_html.pl      fixed/
#	cp -a $(SGMLT)/fmt_latex2e.pl   fixed/


### Emacs specials
###
### Local Variables: ***
### mode:text ***
### tab-width:8 ***
### End: ***

#! /bin/make -f
#
# Makefile to convert the example.sgml

# old multiple commands way
# COMMAND=sgml2

# new single command approach
COMMAND=linuxdoc --backend=

srcfiles = example.sgml example-tr.sgml logo.png logo.eps.gz Makefile
allext   = .txt .html .tex .dvi .ps .pdf .info .lyx .rtf
files    = $(addprefix example, $(allext))
trfiles  = $(addprefix example-tr, $(allext))
allfiles = $(files) $(trfiles)

all: $(allfiles)
	@echo "all output formats are created!"


%.txt: %.sgml
	$(COMMAND)txt $<

%.html: %.sgml
	$(COMMAND)html  $<

%.tex: %.sgml
	$(COMMAND)latex -o tex  $<

%.dvi: %.sgml logo.eps
	$(COMMAND)latex -o dvi  $<

%.ps: %.sgml logo.eps
	$(COMMAND)latex -o ps  $<

%.pdf: %.sgml logo.eps
	$(COMMAND)latex -o pdf  $<

%.info: %.sgml
	$(COMMAND)info  $<

%.lyx: %.sgml logo.eps
	$(COMMAND)lyx  $<

%.rtf: %.sgml
	$(COMMAND)rtf $<

logo.eps: logo.eps.gz
	gzip -d -c $< > $@

pack: distclean
	tar -cvzf ../linuxdoc-test-tr.tar.gz $(srcfiles)

distclean: clean
	rm -f *~ logo.eps

clean:
	rm -f *.txt *.html *.tex *.dvi *.ps *.pdf *.info *.lyx *.rtf


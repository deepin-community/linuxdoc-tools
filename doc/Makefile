

%.txt: %.sgml
	@echo "- Building txt docs" >&2
	$(TMPDIR)/linuxdoc --backend=txt --filter --blanks=1 $<

%.pdf: %.sgml
	@echo "- Building pdf docs" >&2
	$(TMPDIR)/linuxdoc --backend=latex \
			--output=pdf \
			--pass="\usepackage{times}" $<

%.info: %.sgml
	@echo "- Building info docs" >&2
	$(TMPDIR)/linuxdoc --backend=info $<

%.lyx: %.sgml
	@echo "- Building lyx docs" >&2
	$(TMPDIR)/linuxdoc --backend=lyx $<

html/%.html: %.sgml
	@echo "- Building html docs" >&2
	$(TMPDIR)/linuxdoc --imagebuttons --backend=html $<
	mv -f ./guide*.html ./html

rtf/%.rtf: %.sgml
	@echo "- Building rtf docs" >&2
	$(TMPDIR)/linuxdoc --backend=rtf $<
	mkdir -m 755 -p ./rtf
	mv -f ./guide*.rtf ./rtf

%.dvi: %.sgml
	@echo "- Building dvi docs" >&2
	$(TMPDIR)/linuxdoc --backend=latex \
			--output=dvi \
			--pass="\usepackage{times}" $<

%.ps: %.dvi
	@echo "- Building ps docs" >&2
	dvips -t $(DVIPS_PAPER) -o $@ $<

%.ps.gz: %.ps
	@echo "- Building ps.gz docs" >&2
	gzip -fn $<

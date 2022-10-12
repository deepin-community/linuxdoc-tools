# Makefile for sgmls on Unix.

# Common prefix for installation directories.
# This is used in the definitions of BINDIR and MANDIR.
# It is also used by configure to choose DEFAULT_PATH.
PREFIX=..
# Where to install the sgmls and sgmlsasp binaries.
BINDIR=$(PREFIX)/bin
# Permissions mode to use for binaries
BINMODE=755
# Extension (without the `.') to use for the man pages.
MANEXT=1
# Where to install man pages.
MANDIR=$(PREFIX)/man/man$(MANEXT)
# Permissions mode to use for man pages.
MANMODE=444

# Additional libraries needed.
# Ultrix needs -li
LIBS=

# This is needed only by the format target.
TBL=gtbl
NROFF=groff -Tascii -P-buo

# You shouldn't need to change anything after this point.

ETAGS=etags
SHELL=/bin/sh

PROG1=sgmls

SRCS1=lexrf.c pcbrf.c synrf.c context.c md1.c md2.c pars1.c pars2.c serv.c \
      sgml1.c sgml2.c sgmlmsg.c sgmlxtrn.c traceset.c entgen.c sgmlio.c \
      xfprintf.c main.c unixproc.c sgmldecl.c version.c strerror.c getopt.c \
      msgcat.c lineout.c ambig.c exclude.c lextaba.c

OBJS1=lexrf.o pcbrf.o synrf.o context.o md1.o md2.o pars1.o pars2.o serv.o \
      sgml1.o sgml2.o sgmlmsg.o sgmlxtrn.o traceset.o entgen.o sgmlio.o \
      xfprintf.o main.o unixproc.o sgmldecl.o version.o strerror.o getopt.o \
      msgcat.o lineout.o ambig.o exclude.o lextaba.o

PROG2=sgmlsasp

OBJS2=sgmlsasp.o replace.o sgmls.o strerror.o getopt.o
SRCS2a=sgmlsasp.c replace.c sgmls.c
SRCS2=$(SRCS2a) strerror.c getopt.c

PROG3=rast

SRCS3a=rast.c
SRCS3=$(SRCS3a) sgmls.c strerror.c
OBJS3=rast.o sgmls.o strerror.o getopt.o

PROG4=genlex
SRCS4a=genlex.c ebcdic.c
SRCS4=$(SRCS4a) lextaba.c lexrf.c
OBJS4=genlex.o ebcdic.o lextaba.o lexrf.o

SRCS=$(SRCS1) $(SRCS2a) $(SRCS3a) $(SRCS4a) lextabe.c

HDRS=action.h adl.h entity.h error.h etype.h sgmldecl.h keyword.h lextoke.h \
     msg.h sgmlaux.h sgmlfnsm.h sgmlincl.h sgmlmain.h lineout.h sgmlxtrn.h \
     source.h synxtrn.h tools.h trace.h context.h getopt.h msgcat.h std.h \
     appl.h sgmls.h sgmlsasp.h replace.h lexcode.h latin1.h ebcdic.h

PROGS=$(PROG1) $(PROG2) $(PROG3)

MANPAGES=sgmls.man sgmlsasp.man rast.man
FMANPAGES=sgmls.txt sgmlsasp.txt rast.txt

# Miscellaneous files to go in the distribution
MISC=README NEWS INSTALL ChangeLog LICENSE TODO Makefile Makefile.bcc \
     Makefile.vms Makefile.cms dos.cfg unix.cfg thinkc.cfg vms.cfg cms.cfg \
     dosproc.c portproc.c stklen.c sgmls.pl configure sgml-mode.el

# Files to go in the distribution.
DIST=$(MISC) $(MANPAGES) $(FMANPAGES) $(SRCS) $(HDRS)

.SUFFIXES: .man .txt

.man.txt:
	-rm -f $@
	$(TBL) $< | $(NROFF) -man >$@

all: $(PROGS)

format: $(FMANPAGES)

$(PROG1): $(OBJS1)
	$(CC) -o $(PROG1) $(LDFLAGS) $(OBJS1) $(LIBS)

saber_$(PROG1):
	#setopt program_name ./$(PROG1)
	#load -C $(SRCS1)

$(PROG2): $(OBJS2)
	$(CC) -o $(PROG2) $(LDFLAGS) $(OBJS2) $(LIBS)

saber_$(PROG2):
	#setopt program_name ./$(PROG2)
	#load -C $(SRCS2)

$(PROG3): $(OBJS3)
	$(CC) -o $(PROG3) $(LDFLAGS) $(OBJS3) $(LIBS)

saber_$(PROG3):
	#setopt program_name ./$(PROG3)
	#load -C $(SRCS3)

$(PROG4): $(OBJS4)
	$(CC) -o $(PROG4) $(LDFLAGS) $(OBJS4) $(LIBS)

config.h: unix.cfg configure
	@echo Generating config.h from unix.cfg.
	@echo If this fails, copy unix.cfg to config.h and then edit config.h.
	@echo This may take a minute or two...
	chmod +x configure
	CC="$(CC)" CFLAGS="$(CFLAGS)" LIBS="$(LIBS)" PREFIX="$(PREFIX)" \
	  ./configure

lextabe.c: genlex
	-rm -f lextabe.c
	./genlex >$@

install: $(PROGS)
	-test -d $(BINDIR) || mkdir $(BINDIR)
	for f in $(PROGS); do \
	  rm -f $(BINDIR)/$$f; \
	  cp $$f $(BINDIR)/$$f; \
	  chmod $(BINMODE) $(BINDIR)/$$f; \
	done

install.man: $(MANPAGES)
	-test -d $(MANDIR) || mkdir $(MANDIR)
	for f in $(MANPAGES); do \
	  t=$(MANDIR)/`basename $$f .man`.$(MANEXT); \
	  rm -f $$t; \
	  cp $$f $$t; \
	  chmod $(MANMODE) $$t; \
	done

clean:
	-rm -f *.o $(PROGS) core a.out

realclean: clean
	-rm -f $(FMANPAGES)

test: FORCE $(PROGS)
	cd test; $(SHELL) RUN

TAGS: $(SRCS) $(HDRS)
	$(ETAGS) $(SRCS) $(HDRS)

dist: FORCE
	-rm -fr temp
	mkdir temp
	cd test; ./CLEAN
	@version=`sed -n -e \
           '/version_string/s/.*= "\([0-9.]*\).*/\1/p' version.c`; \
	echo making sgmls-$$version.tar.Z; \
	rm -f sgmls-$$version.tar.Z; \
	mkdir temp/sgmls-$$version; \
	ln $(DIST) temp/sgmls-$$version; \
	cd temp/sgmls-$$version; \
	rm Makefile; \
	sed -e '/^CC=/s/=.*/=cc/' -e '/^PROFILE=/s/=.*/=/' \
	  -e '/^OPTIMIZE=/s/=.*/=-O/' -e '/^DEBUG=/s/=.*/=/' \
	  -e '/^INCLUDE=/s/=.*/=/'  -e '/^WARN=/s/=.*/=/' \
	  -e '/^LIBS=/s/=.*/=/' ../../Makefile >Makefile; \
	ln -s ../../test .; \
	cd ..; \
	tar cfh - sgmls-$$version | compress >../sgmls-$$version.tar.Z
	-rm -fr temp

dist: $(DIST)

depend: FORCE
	gcc -MM $(SRCS) >.depend
	cp Makefile Makefile.bak
	sed -e '/^# Do not delete this line./{' -e 'r .depend' -e q -e '}' \
	    Makefile.bak >Makefile
	-rm -f .depend

depend: $(SRCS)

FORCE:

# Do not delete this line.
lexrf.o :  lexrf.c config.h latin1.h entity.h tools.h msgcat.h synxtrn.h \
  action.h lexcode.h
pcbrf.o :  pcbrf.c config.h latin1.h entity.h tools.h msgcat.h action.h \
  synxtrn.h adl.h
synrf.o :  synrf.c config.h latin1.h entity.h tools.h msgcat.h synxtrn.h \
  adl.h
context.o :  context.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h \
  context.h
md1.o :  md1.c sgmlincl.h config.h latin1.h std.h entity.h tools.h msgcat.h \
  action.h adl.h error.h etype.h keyword.h lextoke.h source.h synxtrn.h \
  sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
md2.o :  md2.c sgmlincl.h config.h latin1.h std.h entity.h tools.h msgcat.h \
  action.h adl.h error.h etype.h keyword.h lextoke.h source.h synxtrn.h \
  sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
pars1.o :  pars1.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
pars2.o :  pars2.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
serv.o :  serv.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
sgml1.o :  sgml1.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
sgml2.o :  sgml2.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
sgmlmsg.o :  sgmlmsg.c config.h latin1.h sgmlaux.h std.h entity.h tools.h \
  msgcat.h sgmldecl.h msg.h
sgmlxtrn.o :  sgmlxtrn.c sgmlincl.h config.h latin1.h std.h entity.h \
  tools.h msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h \
  source.h synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h \
  sgmlfnsm.h
traceset.o :  traceset.c sgmlincl.h config.h latin1.h std.h entity.h \
  tools.h msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h \
  source.h synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h \
  sgmlfnsm.h
entgen.o :  entgen.c config.h latin1.h sgmlaux.h std.h entity.h tools.h \
  msgcat.h sgmldecl.h
sgmlio.o :  sgmlio.c config.h latin1.h sgmlaux.h std.h entity.h tools.h \
  msgcat.h sgmldecl.h
xfprintf.o :  xfprintf.c config.h latin1.h
main.o :  main.c config.h latin1.h std.h getopt.h entity.h tools.h msgcat.h \
  adl.h sgmlmain.h appl.h
unixproc.o :  unixproc.c config.h latin1.h std.h entity.h tools.h msgcat.h \
  appl.h
sgmldecl.o :  sgmldecl.c sgmlincl.h config.h latin1.h std.h entity.h \
  tools.h msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h \
  source.h synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h \
  sgmlfnsm.h
version.o :  version.c
strerror.o :  strerror.c config.h latin1.h
getopt.o :  getopt.c config.h latin1.h
msgcat.o :  msgcat.c config.h latin1.h std.h msgcat.h
lineout.o :  lineout.c config.h latin1.h std.h entity.h tools.h msgcat.h \
  adl.h sgmlmain.h lineout.h appl.h
ambig.o :  ambig.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
exclude.o :  exclude.c sgmlincl.h config.h latin1.h std.h entity.h tools.h \
  msgcat.h action.h adl.h error.h etype.h keyword.h lextoke.h source.h \
  synxtrn.h sgmlxtrn.h trace.h sgmlmain.h sgmlaux.h sgmldecl.h sgmlfnsm.h
lextaba.o :  lextaba.c config.h latin1.h entity.h tools.h msgcat.h \
  lexcode.h sgmldecl.h lextoke.h
sgmlsasp.o :  sgmlsasp.c sgmlsasp.h config.h latin1.h std.h sgmls.h \
  replace.h getopt.h
replace.o :  replace.c sgmlsasp.h config.h latin1.h std.h replace.h
sgmls.o :  sgmls.c config.h latin1.h std.h sgmls.h lineout.h
rast.o :  rast.c config.h latin1.h std.h sgmls.h getopt.h
genlex.o :  genlex.c config.h latin1.h std.h tools.h
ebcdic.o :  ebcdic.c ebcdic.h
lextabe.o :  lextabe.c config.h latin1.h entity.h tools.h msgcat.h \
  sgmldecl.h

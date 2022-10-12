dnl
dnl Copyright (C) 1996 Ken MacLeod
dnl See the file COPYING for distribution terms.
dnl
dnl $Id: configure.ac,v 1.3 2001/11/30 23:41:44 sano Exp $
dnl
dnl This is an autoconf script.
dnl To rebuild the `configure' script from this, execute the command
dnl     autoconf
dnl in the directory containing this script.

AC_INIT(EntityMap.pm.in)
VERSION=0.1.0
AC_SUBST(VERSION)
PACKAGE=entity-map
AC_SUBST(PACKAGE)

AC_CONFIG_AUX_DIR(config)
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_LN_S
AC_ARG_PROGRAM

AC_CHECK_PROG(SED, sed, sed)
AC_PATH_PROGS(PERL5, perl5 perl)

AC_SUBST(docdir)
docdir=\${prefix}/share/doc/entity-map-\${VERSION}
AC_SUBST(perl5libdir)
perl5libdir=\${libdir}/perl5
AC_SUBST(textmoddir)
textmoddir=\${perl5libdir}/Text
AC_SUBST(entitymapdir)
entitymapdir=\${datadir}/entity-map/\${VERSION}
AC_SUBST(localentitymapdir)
localentitymapdir=\${datadir}/entity-map

AC_OUTPUT(Makefile)
AC_OUTPUT(sdata/Makefile)

dnl
dnl Copyright (C) 1996 Ken MacLeod
dnl See the file COPYING for distribution terms.
dnl
dnl $Id: configure.ac,v 1.5 2001/11/30 23:55:12 sano Exp $
dnl
dnl This is an autoconf script.
dnl To rebuild the `configure' script from this, execute the command
dnl     autoconf
dnl in the directory containing this script.

AC_INIT(iso-entities.cat)
VERSION=8879.1986.2
AC_SUBST(VERSION)
PACKAGE='iso-entities'
AC_SUBST(PACKAGE)

AC_CONFIG_AUX_DIR(config)
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_ARG_PROGRAM

AC_CHECK_PROG(SED, sed, sed)
AC_PATH_PROGS(PERL5, perl5 perl)

AC_SUBST(docdir)
docdir=\${datadir}/doc/\${PACKAGE}-\${VERSION}
AC_SUBST(sgmldir)
sgmldir=\${datadir}/sgml

# The ISO 8879:1986 character entities are static, the additional
# point release is the packaging, so we leave off the point release
# on the install directory.
AC_SUBST(isoentdir)
isoentdir=\${sgmldir}/\${PACKAGE}-8879.1986

AC_OUTPUT(Makefile)

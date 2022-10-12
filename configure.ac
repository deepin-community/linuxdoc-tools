dnl
dnl  configure.ac
dnl
dnl  Copyright (C) 2000-2001 Taketoshi Sano <sano@debian.org>
dnl  Copyright (C) 2008-2015 Agustin Martin <agmartin@debian.org>
dnl
dnl  Process this file with autoconf to produce a configure script.

AC_INIT(sgmls-1.1)

AC_PROG_INSTALL

AC_PATH_PROG(PERL, perl)
AC_SUBST(PERL)

dnl ------ Check if we have at least perl 5.004 ---------
if echo 'require 5.004;exit' | $PERL
then
  : # Solaris and OSF/1 /bin/sh don't know about negation operators...
else
  AC_MSG_ERROR(You don't have Perl 5.004...)
  exit 1
fi

dnl ------ Make perl a bit more verbose if desired ---------
AC_ARG_WITH(perl-w,
   [AS_HELP_STRING([--with-perl-w],
	[use perl -w option])],
   PERLWARN=-w,
   PERLWARN=
)
AC_SUBST(PERLWARN)

dnl ------ Check if groff is available ---------------------
AC_PATH_PROG(GROFF, groff)
AC_SUBST(GROFF)

dnl ------ Check if groff should take -mgs or -ms ----------
AC_CACHE_CHECK(whether ${GROFF} accepts -mgs, ac_cv_linuxdoctools_groff_mgs,
[  if test -z "`${GROFF} -mgs < /dev/null 2>&1`"; then
      ac_cv_linuxdoctools_groff_mgs=yes
   else
      ac_cv_linuxdoctools_groff_mgs=no
   fi
])

if test ${ac_cv_linuxdoctools_groff_mgs:-ERROR} = yes; then
  GROFFMACRO="-mgs"
else
  GROFFMACRO="-ms"
fi
AC_SUBST(GROFFMACRO)

dnl ------ Check for sgmls parser --------------------------
AC_PATH_PROGS(NSGMLS, nsgmls onsgmls, notfound)
AC_SUBST(NSGMLS)
   test "$NSGMLS" = "notfound" && AC_MSG_ERROR(neither onsgmls nor nsgmls is found)
   BUILD_NSGMLS=
AC_SUBST(BUILD_NSGMLS)

dnl ------ Check for sgmlsasp ------------------------------
AC_PATH_PROG(SGMLSASP, sgmlsasp)
AC_ARG_WITH(installed-sgmlsasp,
   [AS_HELP_STRING([--with-installed-sgmlsasp],
		   [use installed sgmlsasp])],
   test -n "$SGMLSASP" || AC_MSG_ERROR(sgmlsasp not found)
   BUILD_SGMLSASP=,
   SGMLSASP=\${prefix}/bin/sgmlsasp
   BUILD_SGMLSASP=true
)
AC_SUBST(SGMLSASP)
AC_SUBST(BUILD_SGMLSASP)

dnl ------- sgmlsasp build needs an awk variant ------
if test "$BUILD_SGMLSASP" = "true"
then
   AC_PATH_PROGS(AWK, awk, notfound)
   test "$AWK" = "notfound" && AC_MSG_ERROR(No awk program found)
fi

dnl ------ Check if we will use installed entity-map -------
AC_ARG_WITH(installed-entity-map,
   [AS_HELP_STRING([--with-installed-entity-map],
		   [use installed entity-map])],
   BUILD_ENTITY_MAP=,
   BUILD_ENTITY_MAP=true
)
AC_SUBST(BUILD_ENTITY_MAP)

dnl ------ Check if we will use installed iso-entities -----
AC_ARG_WITH(installed-iso-entities,
   [AS_HELP_STRING([--with-installed-iso-entities],
	           [use installed iso-entities])],
   BUILD_ISO_ENTITIES=,
   BUILD_ISO_ENTITIES=true
)
AC_SUBST(BUILD_ISO_ENTITIES)

dnl ------ Set dir for auxiliary programs like sgmlpre -----
AC_ARG_WITH(auxbindir,
  [AS_HELP_STRING([--with-auxbindir=dir],
		  [dir for internal use programs (default: EPREFIX/bin)])],
  auxbindir="$withval",
  auxbindir="\${exec_prefix}/bin"
)
AC_SUBST(auxbindir)

dnl ------ Set dir for package datadir --------------------
AC_ARG_WITH(pkgdatadir,
  [AS_HELP_STRING([--with-pkgdatadir=dir],
		  [dir for package datadir (default: PREFIX/share/linuxdoc-tools)])],
  pkgdatadir="$withval",
  pkgdatadir="\${prefix}/share/linuxdoc-tools"
)
AC_SUBST(pkgdatadir)

dnl ------ Set dir for package perl modules ---------------
AC_ARG_WITH(perllibdir,
  [AS_HELP_STRING([--with-perllibdir=dir],
		  [dir for package perl modules (default: PKGDATADIR)])],
  perl5libdir="$withval",
  perl5libdir="\${pkgdatadir}"
)
AC_SUBST(perl5libdir)

dnl ------ Set dir for tex style files --------------------
AC_ARG_WITH(texdir,
  [AS_HELP_STRING([--with-texdir=dir],
		  [dir for tex style files (default: PKGDATADIR)])],
  texdir="$withval",
  texdir="\${pkgdatadir}"
)
AC_SUBST(texdir)

dnl ------ Allow explicit setting of doc formats to build -----
BUILDDOC_FORMATS="txt pdf info lyx html rtf"
AC_ARG_ENABLE(docs,
   [AS_HELP_STRING([--enable-docs[[=types]]],
		   [Explicitly set doc formats to build.
		   Possible values: txt pdf info lyx html rtf dvi+ps.
		   --disable-docs will disable doc build and installation.
		   (Default: enabled with "txt pdf info lyx html rtf" value)]
			 )],
   [if test "x$enableval" != "xyes"; then
      if test "x$enableval" = "xno"; then
	 BUILDDOC_FORMATS=""
      else
	 BUILDDOC_FORMATS="$enableval"
      fi
   fi]
)
AC_SUBST(BUILDDOC_FORMATS)

dnl ------ Create list of possible extra subdirs -----------
if test "$BUILD_NSGMLS" = "true"
then
  AC_CONFIG_SUBDIRS([sp])
fi
if test "$BUILD_ENTITY_MAP" = "true"
then
  AC_CONFIG_SUBDIRS([entity-map])
fi

if test "$BUILD_ISO_ENTITIES" = "true"
then
  AC_CONFIG_SUBDIRS([iso-entities])
fi

AC_OUTPUT(Makefile)

if test "$BUILD_SGMLSASP" = "true"
then
  echo "Configuring sgmls-1.1";
  cd sgmls-1.1; make config.h; cd ..
fi

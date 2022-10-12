#! /bin/bash

set -e

# No need to build anything if only format is linuxdoc sgml
if [ "${BUILDDOC_FORMATS}" = "sgml" ]; then
    echo "Skip doc build. linuxdoc sgml is already present." >&2
    exit
fi

export TMPDIR=`mktemp -d ${TMPDIR:-/tmp}/ldt.XXXXXXXXXX`;

echo "-------- Building linuxdoc-tools docs ---------"
echo "Using temporary directory: $TMPDIR"

abort()
{
     sleep 1; rm -rf $TMPDIR; exit 1
}

trap 'abort' 1 2 3 6 9 15


PERL=`which perl`
TMPDATADIR=${TMPDIR}/linuxdoc-tools
mkdir -p ${TMPDATADIR}

( cd ${PKGDATADIR} && cp -r . ${TMPDATADIR} )
cp ../tex/*.sty ${TMPDATADIR}
cp ../VERSION ${TMPDATADIR}

if [ "${BUILD_ENTITY_MAP}" = "true" ]; then
    # Create a modified EntityMap.pm with entity-map location in doc
    # build temporary dir. Need to properly install entity-map there.
    mkdir $TMPDIR/Text
    ${MAKE} -C ../entity-map install DESTDIR="$TMPDIR"
    sed < ../entity-map/EntityMap.pm.in > $TMPDIR/Text/EntityMap.pm \
	-e 's|\@localentitymapdir\@|'${TMPDIR}${PREFIX}'/share/entity-map|g' \
	-e 's|\@entitymapdir\@|'${TMPDIR}${PREFIX}'/share/entity-map/0.1.0|g'

    # Set ${TMPDIR} first in perl load path (Will put Text dir there
    # for modified EntityMap.pm), then our perl5lib
    export PERL5LIB=${TMPDIR}:${PKGPERL5LIB}
else
    export PERL5LIB=${PKGPERL5LIB}
fi

# Set prefix for iso-entities location and make it available if needed.
if [ "${BUILD_ISO_ENTITIES}" = "true" ]; then
    # --without-installed-iso-entities: Install iso-entities in
    # "$TMPDIR/usr" and set it as iso-entities prefix.
    ${MAKE} -C ../iso-entities install DESTDIR="$TMPDIR"
    ISOENTITIES_PREFIX="${TMPDIR}${PREFIX}"
else
    # --with-installed-iso-entities: Use system prefix.
    ISOENTITIES_PREFIX="${PREFIX}"
fi

# Make sure our binaries are available in doc build environment
TMP_BINDIR=${TMPDIR}/bin
mkdir -p ${TMP_BINDIR}
install -m 0755 ../sgmlpre/sgmlpre ${TMP_BINDIR}
install -m 0755 ../rtf-fix/rtf2rtf ${TMP_BINDIR}
if [ -x "../sgmls-1.1/sgmlsasp" ]; then
    install -m 0755 ../sgmls-1.1/sgmlsasp ${TMP_BINDIR}
fi

export PATH=${PATH}:${TMP_BINDIR}

# Create a linuxdoc copy using our temporary locations.
sed < ../bin/linuxdoc.in > $TMPDIR/linuxdoc \
  -e 's!\@prefix\@!'${TMPDIR}/usr'!g' \
  -e 's!\@isoentities_prefix\@!'${ISOENTITIES_PREFIX}'!g' \
  -e 's!\@auxbindir\@!'${TMP_BINDIR}'!g' \
  -e 's!\@pkgdatadir\@!'${TMPDATADIR}'!g' \
  -e 's!\@perl5libdir\@!'${TMPDIR}'!g' \
  -e 's!\@GROFFMACRO\@!-ms!g' \
  -e 's!\@PERL\@!'${PERL}'!g' \
  -e 's!\@PERLWARN\@!!g'

chmod u+x $TMPDIR/linuxdoc

# Unless otherwise instructed, build docs for all formats
if [ -z "${BUILDDOC_FORMATS}" ]; then
    echo "- ++ Warning: \"\${BUILDDOC_FORMATS}\" unset. Building all doc formats:" >&2
    BUILDDOC_FORMATS="txt pdf info lyx html rtf dvi+ps"
fi

# Build actual documentation
echo "- Building documentation for formats: ${BUILDDOC_FORMATS}" >&2
BUILDDOC_MAKE=""
for docformat in ${BUILDDOC_FORMATS}; do
    case ${docformat} in
	txt)
	    if [ -n "`which groff`" ]; then
		echo "- Add to build list: guide.txt" >&2
		BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.txt"
	    else
		echo "- ++ Warning: groff not available, cannot build \"${docformat}\" format." >&2
	    fi
	    ;;
	pdf)
	    echo "- Add to build list: guide.pdf" >&2
	    BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.pdf"
	    ;;
	info)
	    echo "- Add to build list: guide.info" >&2
	    BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.info"
	    ;;
	lyx)
	    echo "- Add to build list: guide.lyx" >&2
	    BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.lyx"
	    ;;
	html)
	    echo "- Add to build list: guide.html" >&2
	    BUILDDOC_MAKE="${BUILDDOC_MAKE} html/guide.html"
	    ;;
	rtf)
	    echo "- Add to build list: guide.rtf" >&2
	    BUILDDOC_MAKE="${BUILDDOC_MAKE} rtf/guide.rtf"
	    ;;
	dvi+ps)
	    echo "- Building latex docs" >&2
	    if [ -n "`which latex`" ]; then
		echo "- Add to build list: guide.dvi" >&2
		BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.dvi"

		if [ -n "`which dvips`" ]; then
		    echo "   + dvips" >&2
		    DVIPS_PAPER="a4"
		    if [ -r /etc/papersize ]; then
			TMP_PAPER=`head -n 1 /etc/papersize`
			if [ "${TMP_PAPER}" = "letter" ]; then
			    DVIPS_PAPER="letter"
			fi
		    fi

		    if [ -n "`which gzip`" ]; then
			echo "- Add to build list: guide.ps.gz" >&2
			BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.ps.gz"
		    else
			echo "- Add to build list: guide.ps" >&2
			BUILDDOC_MAKE="${BUILDDOC_MAKE} guide.ps"
		    fi
		else
		    echo "- ++ Warning: dvips not available, cannot build \"guide.ps\"." >&2
		fi
	    else
		echo "- ++ Warning: latex not available, cannot build \"${docformat}\" format." >&2
	    fi
	    ;;
	sgml)
	    echo "- No need to build already present linuxdoc sgml." >&2
	    ;;
	*)
	    echo "- ++ Warning: Ignoring unknown \"${docformat}\" format." >&2
    esac
done

${MAKE} TMPDIR="${TMPDIR}" DVIPS_PAPER="${DVIPS_PAPER}" ${BUILDDOC_MAKE}

# Remove temporary directory.
rm -rf "${TMPDIR}"

exit 0

Description: Character Entity Mapping Tables
Name: entity-map
Version: @VERSION@
Release: 1
Source: entity-map-@VERSION@.tar.gz
Copyright: distributable
Group: Applications/Publishing/SGML
BuildRoot: /tmp/entity-map
# $Id: entity-map.spec,v 1.2 2001/11/30 23:41:44 sano Exp $

%prep
%setup

%build
./configure --prefix=/usr
make

%install
make prefix=${RPM_ROOT_DIR}/usr install installdoc

%files

%dir /usr/share/doc/entity-map-@VERSION@
/usr/share/doc/entity-map-@VERSION@/COPYING
/usr/share/doc/entity-map-@VERSION@/README

/usr/lib/perl5/Text/EntityMap.pm

%dir /usr/share/entity-map/@VERSION@

/usr/share/entity-map/@VERSION@/GFextra.2ab
/usr/share/entity-map/@VERSION@/GFextra.2as
/usr/share/entity-map/@VERSION@/GFextra.2l1b
/usr/share/entity-map/@VERSION@/GFextra.2l1s
/usr/share/entity-map/@VERSION@/GFextra.2rtf
/usr/share/entity-map/@VERSION@/GFextra.2tex
/usr/share/entity-map/@VERSION@/GFextra.2texi
/usr/share/entity-map/@VERSION@/ISOdia
/usr/share/entity-map/@VERSION@/ISOdia.2ab
/usr/share/entity-map/@VERSION@/ISOdia.2as
/usr/share/entity-map/@VERSION@/ISOdia.2html
/usr/share/entity-map/@VERSION@/ISOdia.2l1b
/usr/share/entity-map/@VERSION@/ISOdia.2l1s
/usr/share/entity-map/@VERSION@/ISOdia.2rtf
/usr/share/entity-map/@VERSION@/ISOdia.2tex
/usr/share/entity-map/@VERSION@/ISOdia.2texi
/usr/share/entity-map/@VERSION@/ISOdia.2tr
/usr/share/entity-map/@VERSION@/ISOlat1
/usr/share/entity-map/@VERSION@/ISOlat1.2ab
/usr/share/entity-map/@VERSION@/ISOlat1.2as
/usr/share/entity-map/@VERSION@/ISOlat1.2html
/usr/share/entity-map/@VERSION@/ISOlat1.2l1b
/usr/share/entity-map/@VERSION@/ISOlat1.2l1s
/usr/share/entity-map/@VERSION@/ISOlat1.2rtf
/usr/share/entity-map/@VERSION@/ISOlat1.2tex
/usr/share/entity-map/@VERSION@/ISOlat1.2texi
/usr/share/entity-map/@VERSION@/ISOlat1.2tr
/usr/share/entity-map/@VERSION@/ISOlat2
/usr/share/entity-map/@VERSION@/ISOlat2.2ab
/usr/share/entity-map/@VERSION@/ISOlat2.2as
/usr/share/entity-map/@VERSION@/ISOlat2.2l1b
/usr/share/entity-map/@VERSION@/ISOlat2.2l1s
/usr/share/entity-map/@VERSION@/ISOlat2.2rtf
/usr/share/entity-map/@VERSION@/ISOlat2.2tex
/usr/share/entity-map/@VERSION@/ISOlat2.2texi
/usr/share/entity-map/@VERSION@/ISOnum
/usr/share/entity-map/@VERSION@/ISOnum.2ab
/usr/share/entity-map/@VERSION@/ISOnum.2as
/usr/share/entity-map/@VERSION@/ISOnum.2html
/usr/share/entity-map/@VERSION@/ISOnum.2l1b
/usr/share/entity-map/@VERSION@/ISOnum.2l1s
/usr/share/entity-map/@VERSION@/ISOnum.2rtf
/usr/share/entity-map/@VERSION@/ISOnum.2tex
/usr/share/entity-map/@VERSION@/ISOnum.2texi
/usr/share/entity-map/@VERSION@/ISOnum.2tr
/usr/share/entity-map/@VERSION@/ISOpub
/usr/share/entity-map/@VERSION@/ISOpub.2ab
/usr/share/entity-map/@VERSION@/ISOpub.2as
/usr/share/entity-map/@VERSION@/ISOpub.2html
/usr/share/entity-map/@VERSION@/ISOpub.2l1b
/usr/share/entity-map/@VERSION@/ISOpub.2l1s
/usr/share/entity-map/@VERSION@/ISOpub.2rtf
/usr/share/entity-map/@VERSION@/ISOpub.2tex
/usr/share/entity-map/@VERSION@/ISOpub.2texi
/usr/share/entity-map/@VERSION@/ISOpub.2tr
/usr/share/entity-map/@VERSION@/ISOtech
/usr/share/entity-map/@VERSION@/ISOtech.2ab
/usr/share/entity-map/@VERSION@/ISOtech.2as
/usr/share/entity-map/@VERSION@/ISOtech.2html
/usr/share/entity-map/@VERSION@/ISOtech.2l1b
/usr/share/entity-map/@VERSION@/ISOtech.2l1s
/usr/share/entity-map/@VERSION@/ISOtech.2rtf
/usr/share/entity-map/@VERSION@/ISOtech.2tex
/usr/share/entity-map/@VERSION@/ISOtech.2texi
/usr/share/entity-map/@VERSION@/ISOtech.2tr
/usr/share/entity-map/@VERSION@/LDextra.2tr
/usr/share/entity-map/@VERSION@/LDextra.2html
/usr/share/entity-map/@VERSION@/greek.2html
/usr/share/entity-map/@VERSION@/lat1.2sdata

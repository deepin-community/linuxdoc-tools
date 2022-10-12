Summary: ISO Character Entity Sets
Name: iso-entities
Version: 8879.1986.2
Release: 1
Source: iso-entities-8879.1986.2.tar.gz
Copyright: distributable
Group: Applications/Publishing/SGML
BuildRoot: /tmp/iso-entities
# $Id: iso-entities-8879.1986.2.spec,v 1.2 2001/11/30 23:58:31 sano Exp $

%description
The ISO character entity sets are used by many SGML Document Type
Definitions (DTDs).

%prep
%setup

%build
./configure --prefix=/usr
make

%install
make prefix=${RPM_ROOT_DIR}/usr install

%files

%doc COPYING README ChangeLog

%dir /usr/share/sgml/iso-entities-8879.1986

/usr/share/sgml/iso-entities-8879.1986/iso-entities.cat
/usr/share/sgml/iso-entities-8879.1986/ISOamsa
/usr/share/sgml/iso-entities-8879.1986/ISOamsb
/usr/share/sgml/iso-entities-8879.1986/ISOamsc
/usr/share/sgml/iso-entities-8879.1986/ISOamsn
/usr/share/sgml/iso-entities-8879.1986/ISOamso
/usr/share/sgml/iso-entities-8879.1986/ISOamsr
/usr/share/sgml/iso-entities-8879.1986/ISObox
/usr/share/sgml/iso-entities-8879.1986/ISOcyr1
/usr/share/sgml/iso-entities-8879.1986/ISOcyr2
/usr/share/sgml/iso-entities-8879.1986/ISOdia
/usr/share/sgml/iso-entities-8879.1986/ISOgrk1
/usr/share/sgml/iso-entities-8879.1986/ISOgrk2
/usr/share/sgml/iso-entities-8879.1986/ISOgrk3
/usr/share/sgml/iso-entities-8879.1986/ISOgrk4
/usr/share/sgml/iso-entities-8879.1986/ISOlat1
/usr/share/sgml/iso-entities-8879.1986/ISOlat2
/usr/share/sgml/iso-entities-8879.1986/ISOnum
/usr/share/sgml/iso-entities-8879.1986/ISOpub
/usr/share/sgml/iso-entities-8879.1986/ISOtech

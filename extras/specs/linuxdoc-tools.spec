Summary: linuxdoc-tools is a toolset for processing LinuxDoc DTD SGML files
Name: linuxdoc-tools
Version: 0.9.10
Release: 1
Group: Applications/Publishing
Source0: linuxdoc-tools.tar.gz
URL: http://www.linux.or.jp/JF/workshop/archives/
Distribution: Kondara
BuildRoot: /var/tmp/linuxdoc-tools
Requires: openjade
Copyright: GPL2
Conflicts: sgml-tools

%description
Linuxdoc-Tools is in fact a small bug-fix version of SGML-Tools 1.0.9,
and is a toolset for processing LinuxDoc DTD SGML files.

%prep
%setup -q -n linuxdoc-tools-%{version}

rm -rf $RPM_BUILD_ROOT

%build
./configure --prefix=/usr
make

%install
make prefix=$RPM_BUILD_ROOT/usr install

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_DIR/linuxdoc-tools-%{version}

%files
%defattr(-,root,root)
/usr/bin/linuxdoc
/usr/bin/rtf2rtf
/usr/bin/sgml2html
/usr/bin/sgml2info
/usr/bin/sgml2latex
/usr/bin/sgml2lyx
/usr/bin/sgml2rtf
/usr/bin/sgml2txt
/usr/bin/sgmlcheck
/usr/bin/sgmlpre
/usr/bin/sgmlsasp
/usr/lib/entity-map
/usr/lib/linuxdoc-tools
/usr/lib/sgml
/usr/lib/perl5/Text/EntityMap.pm
/usr/man/man1/linuxdoc.1
/usr/man/man1/rtf2rtf.1
/usr/man/man1/sgml2html.1
/usr/man/man1/sgml2info.1
/usr/man/man1/sgml2latex.1
/usr/man/man1/sgml2lyx.1
/usr/man/man1/sgml2rtf.1
/usr/man/man1/sgml2txt.1
/usr/man/man1/sgmlcheck.1
/usr/man/man1/sgmlpre.1
/usr/man/man1/sgmlsasp.1
/usr/share/doc/linuxdoc-tools

%changelog
* Wed Jul 05 2000 HAYAKAWA Hitoshi <cz8cb01@linux.or.jp>
- I've only wrote the spec file:-)

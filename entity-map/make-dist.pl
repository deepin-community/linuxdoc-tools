#! @PERL5@
#
# Copyright (C) 1996 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: make-dist.pl,v 1.1.1.1 2001/05/24 15:57:40 sano Exp $
#

$package = "@PACKAGE@";
$version = "@VERSION@";

#
# XXX Note overrides to `Manifest' at the bottom of this file
#
use ExtUtils::Manifest;

require 'timelocal.pl';
use POSIX qw{strftime};

$prog = $0;

$prog =~ s|.*/||;

#
# These files will be skipped by `manicopy' and `fullcheck'
#
open (MANIFEST_SKIP, ">MANIFEST.SKIP")
    or die "$prog: could not open \`MANIFEST.SKIP' for writing: $!\n";
print MANIFEST_SKIP <<'EOF';
\bCVS\b
^MANIFEST\.
^Makefile$
^make-dist$
^\.release$
~$
EOF

close (MANIFEST_SKIP);

#
# Get a release number or snapshot into $release
#
if (open (RELEASE, ".release")) {
    # this is an official release

    $release = <RELEASE>;
    substr ($release, -1) = ""
	if (substr ($release, -1) eq "\n");
    die "$prog: \`.release' does not match version\n"
	if ($release ne $version);
    die "$prog: tar file for package \`$package-$version' already exists\n"
	if (-f "../$package-$version.tar.gz"
	    || -d "../$package-$version");
    close (RELEASE);
} else {
    # this is a development snapshot
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time);

    $dev_release .= "d" . strftime ("%y%m%d", $sec, $min, $hour, $mday, $mon, $year);
    if (-f "../$package-$version$dev_release.tar.gz"
	|| -d "../$package-$version$dev_release") {
	$dev_suffix = "a";
	while (-f "../$package-$version$dev_release$dev_suffix.tar.gz"
	       || -d "../$package-$version$dev_release$dev_suffix") {
	    $dev_suffix ++;
	}
	$dev_release .= $dev_suffix;
    }
    $version .= $dev_release;
}

$package_version = "$package-$version";

($missfile, $missentry) = ExtUtils::Manifest::fullcheck;
die "$prog: release does not check against manifest\n"
    if ($#{$missfile} != -1 || $#{$missentry} != -1);

ExtUtils::Manifest::manicopy(ExtUtils::Manifest::maniread,
			     "../$package_version");

unlink ("MANIFEST.SKIP");

#
# Create a ``version'' specific RPM `spec' file
#
open (SPEC, "$package.spec")
    or die "$prog: can't open \`$package.spec' for reading: $!\n";
open (VER_SPEC, ">../$package_version/$package_version.spec")
    or die "$prog: can't open \`../$package_version/$package_version.spec' for writing: $!\n";
while (<SPEC>) {
    s/\@VERSION\@/$version/;
    print VER_SPEC;
}
close (VER_SPEC);
close (SPEC);
chmod (0644, "../$package_version/$package_version.spec");

#
# Create a ``version'' specific RPM `spec' file
#
foreach $fn ('configure.ac', 'configure') {
    open (CFG_FILE, $fn)
	or die "$prog: can't open \`$fn' for reading: $!\n";
    open (CFG_VER_FILE, ">../$package_version/$fn")
	or die "$prog: can't open \`../$package_version/$fn' for writing: $!\n";
    while (<CFG_FILE>) {
	s/^VERSION='[^']+'$/VERSION='$version'/;
	print CFG_VER_FILE;
    }
    close (CFG_VER_FILE);
    close (CFG_FILE);
    chmod ((($fn eq "configure") ? 0755 : 0644), "../$package_version/$fn");
}

#
# Add the ``version'' specific RPM `spec' file to the MANIFEST after
# the templace RPM `spec' file
#
open (MANIFEST, "MANIFEST")
    or die "$prog: can't open \`MANIFEST' for reading: $!\n";
open (VER_MANIFEST, ">../$package_version/MANIFEST")
    or die "$prog: can't open \`../$package_version/MANIFEST' for writing: $!\n";
while (<MANIFEST>) {
    print VER_MANIFEST;
    if (/^$package.spec\s/) {
	print VER_MANIFEST "$package_version.spec             RPM `spec' file for $package $version\n";
    }
}
close (VER_MANIFEST);
close (MANIFEST);
chmod (0644, "../$package_version/MANIFEST");

chdir "..";

system 'tar', 'czvf', "$package_version.tar.gz", "$package_version";

system 'rm', '-rf', "$package_version";

#
# The following override the `chmod' call.
#
package ExtUtils::Manifest;

sub cp {
    my ($srcFile, $dstFile) = @_;
    my ($perm,$access,$mod) = (stat $srcFile)[2,8,9];
    copy($srcFile,$dstFile);
    utime $access, $mod, $dstFile;
    # chmod a+rX-w,go-w

    chmod(  0644 | ( $perm & 0111 ? 0111 : 0 ),  $dstFile );
}

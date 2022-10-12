#
# $Id: test-entitymap.pl,v 1.1.1.1 2001/05/24 15:57:40 sano Exp $
#

use Text::EntityMap;

@files = split (/\s/, `echo sdata/*`);
foreach $ii (@files) {
    print "---- $ii ----\n";

    $map = Text::EntityMap->load ($ii);
    open (FILE, $ii)
	|| die "opening \`$ii': $!\n";
    while (<FILE>) {
	chop;
	m/(^[^\t]+)\t(.*)/;
	($key, $value) = ($1, $2);

	if ($map->lookup ($key) ne $value) {
	    warn "$ii:$key: expected \`$value'\n";
	}
    }
}

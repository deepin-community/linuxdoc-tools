# We need to add an extra whitespace after each line, because
# otherwise it will be swallowed on continuation lines.
# When line is ended by a backslash (e.g. <em/kk/) lines would be
# joined at the wrong place. We add a marker with a really unlikely
# string and will try to filter in postASP.
#
# A non breaking whitespace (asc(160), \112, \xA0, &nbsp;) was
# previously used, but this causes problems when playing with utf8.
#
# $lyx_afterslash_sep is defined in LinuxDocTools/Vars.pm. It may be
# changed to something more complex if required.
# -----------------------------------------------------------------

use LinuxDocTools::Vars qw{$lyx_afterslash_sep};

while ( <> ){
  chomp;
  if ( m/\/$/ ){
    print $_ . "$lyx_afterslash_sep\n";
  } else {
    print "$_ \n";
  }
}

#
#  Vars.pm
#
#  Shared variables.
#
#  Copyright (C) 1996, 1997, Cees de Groot
#  Copyright (C)       2020, Agustin Martin
# --------------------------------------------------------

package LinuxDocTools::Vars;

use strict;
use base qw(Exporter);

our @EXPORT = qw(%Formats $global %FmtList $VERSION);
our @EXPORT_OK = qw($lyx_afterslash_sep);

# Import :all to get everything.
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

# To be used in lib/filters/lyx-preNSGMLS.pl and lib/fmt/fmt_lyx.pl
# Hope nothing uses this string value. If so, make it more complex.
our $lyx_afterslash_sep = "LDT_NBSP_4rX5y;;;";

1;

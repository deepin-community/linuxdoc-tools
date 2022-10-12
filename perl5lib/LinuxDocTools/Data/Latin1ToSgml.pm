#
#  Latin1ToSgml.pm
#
#  This is a latin1 only file containing functions having legacy
#  latin1 chars.  Split here to avoid the risk of messing up with
#  charsets in other files.
#
#  Copyright (C) 1995, Cees de Groot
#  Copyright (C) 1995, Farzad Farid
#  Copyright (C) 1995, Greg Hankins
#  Copyright (C) 2020, Agustin Martin
# ---------------------------------------------------------------------------

package LinuxDocTools::Data::Latin1ToSgml;

use strict;
use base qw(Exporter);
our @EXPORT_OK = qw(ldt_latin1tosgml);

# ---------------------------------------------------------------------------
sub ldt_latin1tosgml {
  # -------------------------------------------------------------------------
  # Convert latin1 chars in input filehandle to sgml entities in the
  # returned string (by Farzad Farid, adapted by Greg Hankins)
  # -------------------------------------------------------------------------
  my $FILE     = shift;
  my $sgmlout;

  while (<$FILE>){
    # Outline these commands later on - CdG
    # Upper Case Latin-1 Letters
    s/À/\&Agrave;/g; # &#192;
    s/Á/\&Aacute;/g; # &#193;
    s/Â/\&Acirc;/g;  # &#194;
    s/Ã/\&Atilde;/g; # &#195;
    s/Ä/\&Auml;/g;   # &#196;
    s/Å/\&Aring;/g;  # &#197;
    s/Æ/\&AElig;/g;  # &#198;
    s/Ç/\&Ccedil;/g; # &#199;
    s/È/\&Egrave;/g; # &#200;
    s/É/\&Eacute;/g; # &#201;
    s/Ê/\&Ecirc;/g;  # &#202;
    s/Ë/\&Euml;/g;   # &#203;
    s/Ì/\&Igrave;/g; # &#204;
    s/Í/\&Iacute;/g; # &#205;
    s/Î/\&Icirc;/g;  # &#206;
    s/Ï/\&Iuml;/g;   # &#207;
    s/Ð/&ETH;/g;     # &#208;
    s/Ñ/\&Ntilde;/g; # &#209;
    s/Ò/\&Ograve;/g; # &#210;
    s/Ó/\&Oacute;/g; # &#211;
    s/Ô/\&Ocirc;/g;  # &#212;
    s/Õ/\&Otilde;/g; # &#213;
    s/Ö/\&Ouml;/g;   # &#214;
    # s/×/&times;/g;   # &#215; Moved below to symbols
    s/Ø/\&Oslash;/g; # &#216;
    s/Ù/\&Ugrave;/g; # &#217;
    s/Ú/\&Uacute;/g; # &#218;
    s/Û/\&Ucirc;/g;  # &#219;
    s/Ü/\&Uuml;/g;   # &#220;
    s/Ý/\&Yacute;/g; # &#221;
    s/Þ/\&THORN;/g;  # &#222;
    s/ß/\&szlig;/g;  # &#223;
    # Lower Case Latin-1 Letters
    s/à/\&agrave;/g; # &#224;
    s/á/\&aacute;/g; # &#225;
    s/â/\&acirc;/g;  # &#226;
    s/ã/\&atilde;/g; # &#227;
    s/ä/\&auml;/g;   # &#228;
    s/å/\&aring;/g;  # &#229;
    s/æ/\&aelig;/g;  # &#230;
    s/ç/\&ccedil;/g; # &#231;
    s/è/\&egrave;/g; # &#232;
    s/é/\&eacute;/g; # &#233;
    s/ê/\&ecirc;/g;  # &#234;
    s/ë/\&euml;/g;   # &#235;
    s/ì/\&igrave;/g; # &#236;
    s/í/\&iacute;/g; # &#237;
    s/î/\&icirc;/g;  # &#238;
    s/ï/\&iuml;/g;   # &#239;
    s/ð/\&eth;/g;    # &#240;
    s/ñ/\&ntilde;/g; # &#241;
    s/ò/\&ograve;/g; # &#242;
    s/ó/\&oacute;/g; # &#243;
    s/ô/\&ocirc;/g;  # &#244;
    s/õ/\&otilde;/g; # &#245;
    s/ö/\&ouml;/g;   # &#246; #247 is divide symbol below
    s/ø/\&oslash;/g; # &#248;
    s/ù/\&ugrave;/g; # &#249;
    s/ú/\&uacute;/g; # &#250;
    s/û/\&ucirc;/g;  # &#251;
    s/ü/\&uuml;/g;   # &#252;
    s/ý/\&yacute;/g; # &#253;
    s/þ/\&thorn;/g;  # &#254;
    s/ÿ/\&yuml;/g;   # &#255;
    # Some symbols
    s/¡/&iexcl;/g;   # &#161;
    s/¢/&cent;/g;    # &#162;
    s/£/&pound;/g;   # &#163;
    s/¤/&curren;/g;  # &#164;
    s/¥/&yen;/g;     # &#165;
    s/¦/&brkbar;/g;  # &#166;
    s/§/&sect;/g;    # &#167;
    s/©/&copy;/g;    # &#169;
    s/«/&laquo;/g;   # &#171;
    s/¬/&not;/g;     # &#172;
    s/®/&reg;/g;     # &#174;
    s/°/&deg;/g;     # &#176;
    s/±/&plusmn;/g;  # &#177;
    s/µ/\&mu;/g;     # &#181;
    s/¿/&iquest;/g;  # &#191;
    s/×/&times;/g;   # &#215;
    s/÷/&divide;/g;  # &#247;
    $sgmlout .= $_;
  }
  return $sgmlout;
}

1;

__END__

# Local Variables:
# coding: iso-8859-1
# perl-indent-level: 2
# End:

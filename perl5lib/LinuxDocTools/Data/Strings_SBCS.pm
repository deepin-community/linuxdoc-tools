#
#  Strings_SBCS.pm
#
#  Language support. Single Byte Character Set strings translations.
#
# The module, in its source file, contains a data structure, indexed
# by the English strings, that has all available single byte
# translations.
#
# Be careful, this file mixes different single byte encodings, latin1,
# euc-jp and euc-kr.
#
# For UTF-8 translations of strings look at Data::Strings_UTF8.pm
#
# By the time this grows big, we'll make up something else.
#
#  Copyright (C) 1997, Cees de Groot
#  Copyright (C) 2020, Agustin Martin
# -------------------------------------------------------------------------

package LinuxDocTools::Data::Strings_SBCS;

use strict;

our $translations
  = {
     "Previous"
     => {
	 "nl" => "Terug",
	 "de" => "Zurück",
	 "es" => "Página anterior",
	 "fr" => "Page précédente",
	 "da" => "Forrige",
	 "no" => "Forrige",
	 "se" => "Föregående",
	 "pt" => "Página anterior",
	 "ca" => "Pàgina anterior",
	 "it" => "Indietro",
	 "ro" => "Înapoi",
	 "ja" => "Á°¤Î¥Ú¡¼¥¸",
	 "pl" => "Poprzedni",
	 "ko" => "ÀÌÀü",
	 "fi" => "Edellinen"
	},
     "Next"
     => {
	 "nl" => "Verder",
	 "de" => "Weiter",
	 "es" => "Página siguiente",
	 "fr" => "Page suivante",
	 "da" => "Næste",
	 "no" => "Neste",
	 "se" => "Nästa",
	 "pt" => "Página seguinte",
	 "ca" => "Pàgina següent",
	 "it" => "Avanti",
	 "ro" => "Înainte",
	 "ja" => "¼¡¤Î¥Ú¡¼¥¸",
	 "pl" => "Nastny",
	 "ko" => "´ÙÀ½",
	 "fi" => "Seuraava"
	},
     "Contents"
     => {
	 "nl" => "Inhoud",
	 "de" => "Inhalt",
	 "es" => "Índice general",
	 "fr" => "Table des matières",
	 "da" => "Indhold",
	 "no" => "Innhold",
	 "se" => "Innehållsförteckning",
	 "pt" => "Índice",
	 "ca" => "Índex",
	 "it" => "Indice",
	 "ro" => "Cuprins",
	 "ja" => "ÌÜ¼¡¤Ø",
	 "pl" => "Spis Trei",
	 "ko" => "Â÷·Ê",
	 "fi" => "Sisällys"
	},
     "Table of Contents"
     => {
	 "nl" => "Inhoudsopgave",
	 "de" => "Inhaltsverzeichnis",
	 "es" => "Índice general",
	 "fr" => "Table des matières",
	 "da" => "Indholdsfortegnelse",
	 "no" => "Innholdsfortegnelse",
	 "se" => "Innehållsförteckning",
	 "pt" => "Índice geral",
	 "ca" => "Índex general",
	 "it" => "Indice Generale",
	 "ro" => "Cuprins",
	 "ja" => "ÌÜ¼¡",
	 "pl" => "Spis Trei",
	 "ko" => "Â÷·Ê",
	 "fi" => "Sisällysluettelo"
	}
    };

=back

=head1 AUTHOR

Cees de Groot, C<E<lt>cg@pobox.comE<gt>>

=cut

1;

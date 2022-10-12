#
#  Strings_UTF8.pm
#
#  Language support. UTF-8 strings translations.
#
# The module, in its source file, contains a data structure, indexed
# by the English strings, that has all available UTF-8 translations.
#
# For Single Byte Coding System translations look at
# Data::Strings_SBCS.pm
#
# By the time this grows big, we'll make up something else.
#
#  Copyright (C) 1997, Cees de Groot
#  Copyright (C) 2020, Agustin Martin
# -------------------------------------------------------------------------

package LinuxDocTools::Data::Strings_UTF8;

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
	 "ja" => "前のページ",
	 "pl" => "Poprzedni",
	 "ko" => "이전",
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
	 "ja" =>  "次のページ",
	 "pl" => "Nastny",
	 "ko" => "다음",
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
	 "ja" => "目次へ",
	 "pl" => "Spis Trei",
	 "ko" => "차례",
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
	 "ja" => "目次",
	 "pl" => "Spis Trei",
	 "ko" => "차례",
	 "fi" => "Sisällysluettelo"
	}
};

=back

=head1 AUTHOR

Cees de Groot, C<E<lt>cg@pobox.comE<gt>>

=cut

1;

__END__

# Local Variables:
# coding: utf-8
# perl-indent-level: 2
# End:

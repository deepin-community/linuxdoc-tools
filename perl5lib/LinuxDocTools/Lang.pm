#
#  Lang.pm
#
#  Language support.
#
#  Copyright (C) 1997, Cees de Groot
#  Copyright (C) 2020, Agustin Martin
# -------------------------------------------------------------------------

package LinuxDocTools::Lang;

use 5.006;
use strict;

use LinuxDocTools::Data::Strings_SBCS;
use LinuxDocTools::Data::Strings_UTF8;
use LinuxDocTools::Utils qw(ldt_log);
use LinuxDocTools::Vars;

use base qw(Exporter);

# List all unconditionally exported symbols here.
our @EXPORT = qw(Any2ISO ISO2Native ISO2English Xlat);

# List all conditionally exported symbols here.
# our @EXPORT_OK = qw();

# Import :all to get everything.
# our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# -------------------------------------------------------

=head1 NAME

LinuxDocTools::Lang - language name and translation functions

=head1 SYNOPSIS

  $isoname = Any2ISO ('deutsch');
  $native  = ISO2Native ('de');
  $engname = ISO2English ('nederlands');

  $global->{language} = 'nl';
  $dutch = Xlat ('Table of Contents');

=head1 DESCRIPTION

B<LinuxDocTools::Lang> gives a simple interface to various forms of language
names, and provides a translation service. Languages can be specified in
three different ways: by their native name, by their english name, and
by their 2-letter ISO code. For example, you can specify the German
language as C<deutsch>, as C<german> or as C<de>.

=head1 FUNCTIONS

=over 4

=cut

our @Languages = qw(
  en english english
  de deutsch german
  nl nederlands dutch
  fr français french
  es español spanish
  da dansk danish
  no norsk norwegian
  se svenska swedish
  pt portuges portuguese
  ca català catalan
  it italiano italian
  ro românã romanian
  ja japanese japanese
  pl polski polish
  ko korean korean
  fi suomi finnish
  zh_CN chinese-simplified chinese-simplified
);


=item Any2ISO

Maps any of the three forms of languages to the ISO name. So either of
these invocations:

  Any2ISO ('dutch');
  Any2ISO ('nederlands');
  Any2ISO ('nl');

will return the string C<"nl">.

=cut

sub Any2ISO
{
  my $lang = shift (@_);

  my $i = 0;
  foreach my $l (@Languages)
    {
      ($l eq $lang) && last;
      $i++;
    }
  return $Languages[(int $i / 3) * 3];
}


=item ISO2Native

Maps the ISO code to the native name of the language.

=cut

sub ISO2Native
{
  my $iso = shift (@_);

  my $i = 0;
  foreach my $l (@Languages)
    {
      ($l eq $iso) && last;
      $i++;
    }
  return $Languages[$i + 1];

}


=item ISO2English

Maps the ISO code to the english name of the language.

=cut

sub ISO2English
{
  my $iso = shift (@_);

  my $i = 0;
  foreach my $l (@Languages)
    {
      ($l eq $iso) && last;
      $i++;
    }
  return $Languages[$i + 2];
}

=item Xlat

Translates its (English) argument to the language specified by the
current value of C<$gobal-E<gt>{language}>. The module, in its source
file, contains a data structure, indexed by the English strings, that
has all available translations.

=cut

sub Xlat {
  my ($txt) = @_;
  my $string = $txt;
  my $translations = ( $global->{charset} eq "utf-8" )
    ? $LinuxDocTools::Data::Strings_UTF8::translations
    : $LinuxDocTools::Data::Strings_SBCS::translations;

  if ( defined $global->{language}
       && defined $translations->{$txt}{$global->{language}}
       && $global->{language} ne "en" ){
    $string = $translations->{$txt}{$global->{language}};
  }
  ldt_log "LinuxDocTools::Lang.pm::Xlang: in_string: \"$txt\", language: \"$global->{language}\", charset: \"$global->{charset}\", out_string: \"$string\"";

  return $string;
};

1;

=back

=head1 AUTHOR

Cees de Groot, C<E<lt>cg@pobox.comE<gt>>

=cut

1;

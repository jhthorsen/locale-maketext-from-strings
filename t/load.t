use strict;
use warnings;
use Locale::Maketext::From::Strings;
use Test::More;

plan skip_all => 'Cannot read t/i18n/en.strings' unless -r 't/i18n/en.strings';

Locale::Maketext::From::Strings->load('t/i18n', 'MyApp::I18N');

no warnings 'once';

is $INC{'MyApp/I18N.pm'}, 'GENERATED', 'MyApp/I18N.pm generated';
is $INC{'MyApp/I18N/en.pm'}, 'GENERATED', 'MyApp/I18N/en.pm generated';

isa_ok 'MyApp::I18N', 'Locale::Maketext';
isa_ok 'MyApp::I18N::en', 'MyApp::I18N';

is $MyApp::I18N::Lexicon{_AUTO}, 1, 'MyApp::I18N::Lexicon::_AUTO';

is_deeply(
  \%MyApp::I18N::LANGUAGES,
  { en => 'MyApp::I18N::en' },
  'LANGUAGES defined'
);

is_deeply(
  [sort keys %MyApp::I18N::en::Lexicon],
  [qw( hello_user sprintf visit_count welcome_message )],
  'MyApp::I18N::en::Lexicon',
);

done_testing;

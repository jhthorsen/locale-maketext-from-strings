use strict;
use warnings;
use Locale::Maketext::From::Strings;
use Test::More;

plan skip_all => 'Cannot read t/i18n/en.strings' unless -r 't/i18n/en.strings';

system 'rm -r t/out' if -d 't/out';
Locale::Maketext::From::Strings->generate('t/i18n', 'MyApp::I18N', 't/out');

ok -e 't/out/MyApp/I18N.pm', 'generate t/out/MyApp/I18N.pm';
ok -e 't/out/MyApp/I18N/en.pm', 'generate t/out/MyApp/I18N/en.pm';

unshift @INC, 't/out';
require MyApp::I18N;
require MyApp::I18N::en;

no warnings 'once';

isa_ok 'MyApp::I18N', 'Locale::Maketext';
isa_ok 'MyApp::I18N::en', 'MyApp::I18N';

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

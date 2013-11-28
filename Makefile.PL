use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Locale::Maketext::From::Strings',
  ABSTRACT_FROM => 'lib/Locale/Maketext/From/Strings.pm',
  VERSION_FROM => 'lib/Locale/Maketext/From/Strings.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.90',
  },
  META_MERGE => {
    requires  => {
      perl => '5.010001',
    },
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Locale-Maketext-From-Strings',
      bugtracker => 'https://github.com/jhthorsen/locale-maketext-from-strings/issues',
      repository => 'https://github.com/jhthorsen/locale-maketext-from-strings.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);

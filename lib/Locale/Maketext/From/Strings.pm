package Locale::Maketext::From::Strings;

=head1 NAME

Locale::Maketext::From::Strings - Parse Apple .strings files

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Locale::Maketext::From::Strings;

  # in-memory
  Locale::Maketext::From::Strings->load('./18n' => 'MyApp::18N');

  # to disk
  Locale::Maketext::From::Strings->generate('./18n' => 'MyApp::18N' => './lib');

=head1 DESCRIPTION

This module will parse C<.strings> file used in the Apple world and generate
in memory perl-packages used by the L<Locale::Maketext> module.

This module can parse most of the formatting mentioned here:
L<http://blog.lingohub.com/developers/2013/03/i18n-resource-file-formats-ios-strings-files/>.

=over 4

=item *

Key-value pairs are delimited with the equal character (=), and terminated by
a semicolon (;).

=item *

Keys and values are surrounded by double quotes (").

=item *

Place-holders look can be: %.2f, %d, %1$s:

  qr{\%[\d|\.]*\$*\d*[dsf]\b}

=item *

Comments start at the beginning of the line and span the whole line.

=item *

Multi-line comments are enclosed in /* */.

=item *

Single-line comments start with double slashes (//).

=item *

The specification says it expect UTF-16LE encoding by default, but this
module expected UTF-8 by default.

=back

=cut

use strict;
use warnings;
use File::Spec::Functions qw( catfile splitdir );
use Data::Dumper ();
use constant DEBUG => $ENV{MAKETEXT_FROM_STRINGS_DEBUG} ? 1 : 0;

our $VERSION = '0.01';

=head1 METHODS

=head2 generate

  Locale::Maketext::From::Strings->generate($path => $namespace => $out_dir);

This method will write the I18N packages to disk. Default C<$out_dir> is
"lib" in working directory.

=cut

sub generate {
  my($class, $path, $namespace, $out_dir) = @_;
  my $namespace_dir = $namespace;
  my $code;

  $namespace_dir =~ s!::!/!g;
  $out_dir ||= 'lib';
  _mkdir(catfile $out_dir, $namespace_dir);

  unless(-s "$namespace_dir.pm") {
    _spurt($class->_namespace($namespace), catfile $out_dir, "$namespace_dir.pm");
  }

  opendir(my $DH, $path) or die "opendir $path: $!";

  for my $file (grep { /\.strings$/ } readdir $DH) {
    my $language = $file;
    my($code, $kv);

    $language =~ s/\.strings$//;
    -s catfile($namespace_dir, "$language.pm") and next;
    $code = $class->_package($namespace, $language);
    $kv = $class->parse(catfile $path, $file);

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    $kv = Data::Dumper::Dumper($kv);
    $kv =~ s!^\{!our %Lexicon = (!;
    $kv =~ s!\}$!);!;
    substr $code, -3, -3, $kv;
    _spurt($code, catfile $out_dir, $namespace_dir, "$language.pm");
  }

  return $class;
}

=head2 load 

  Locale::Maketext::From::Strings->load($directory => $namespace);

Will parse C<language.strings> files from C<$path> and generage in-memory
packages in the given C<$namespace>.

=cut

sub load {
  my($class, $path, $namespace) = @_;
  my $namespace_dir = $namespace;

  $namespace_dir =~ s!::!/!g;
  eval $class->_namespace($namespace) or die $@;
  $INC{"$namespace_dir.pm"} = 'GENERATED';
  opendir(my $DH, $path) or die "opendir $path: $!";

  for my $file (grep { /\.strings$/ } readdir $DH) {
    my $language = $file;
    $language =~ s/\.strings$//;

    eval $class->_package($namespace, $language) or die $@;
    $class->parse(catfile($path, $file), eval "\\%$namespace\::$language\::Lexicon");
    $INC{"$namespace_dir/$language.pm"} = 'GENERATED';
  }

  return $class;
}

=head2 parse

  $data = $class->parse($file);

Will parse C<$file> and store the key value pairs in C<$data>.

=cut

sub parse {
  my($class, $file, $data) = @_;
  my $buf = '';

  $data ||= {};
  open my $FH, '<:encoding(UTF-8)', $file or die "read $file: $!";

  while(<$FH>) {
    $buf .= $_;

    if($buf =~ s!"([^"]+)"\s*=\s*"([^"]+)(");!!s) { # key-value
      my($key, $value) = ($1, $2);
      warn "[$file] ($key) => ($value)\n" if DEBUG;
      my $pos = 0;
      $data->{$key} = $value;
      $data->{$key} =~ s/\%(\d*)\$?([\d\.]*[dsf])\b/{ ++$pos; sprintf '[sprintf,%%%s,_%s]', $2, $1 || $pos }/ge;
    }
    elsif($buf =~ s!^//(.*)$!!m) { # comment
      warn "[$file] COMMENT ($1)\n" if DEBUG;
    }
    elsif($buf =~ s!/\*(.*)\*/!!s) { # multi-line comment
      warn "[$file] MULTI-LINE-COMMENT ($1)\n" if DEBUG;
    }
  }

  return $data;
}

sub _mkdir {
  my @path = splitdir shift;
  my @current_path = (shift @path);

  for my $part (@path) {
    push @current_path, $part;
    my $dir = catfile @current_path;
    next if -d $dir;
    mkdir $dir or die "mkdir $dir: $!";
  }
}

sub _namespace {
  my($class, $namespace) = @_;

  if(eval "require $namespace; 1") {
    return $class;
  }

  return <<"  PACKAGE"
package $namespace;
use base 'Locale::Maketext';
our \%Lexicon = ( _AUTO => 1 );
our \%LANGUAGES = (); # key = language name, value = class name
1;
  PACKAGE
}

sub _package {
  my($class, $namespace, $language) = @_;

  return <<"  PACKAGE";
\$${namespace}::LANGUAGES{$language} = "$namespace\::$language";
package $namespace\::$language;
use base '$namespace';
1;
  PACKAGE
}

sub _spurt {
  my($content, $path) = @_;
  die qq{Can't open file "$path": $!} unless open my $FH, '>', $path;
  die qq{Can't write to file "$path": $!} unless defined $FH->syswrite($content);
}

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

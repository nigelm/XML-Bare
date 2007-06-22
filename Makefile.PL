#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
if( $^O ne 'MSWin32' ) {
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C to generate a folded perl hash.',
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '-shared -L/usr/local/lib',
    LICENSE   => 'perl'
  );
}
else {
  use Config;
  my $libpath = Config->{'archlibexp'};
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C to generate a folded perl hash.',
    CCFLAGS   => '/MT /DWIN32 /TP',
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ["$libpath\\core\\perl58.lib"],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '/DLL',
    LICENSE   => 'perl'
  );
}

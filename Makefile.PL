#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
if( $^O ne 'MSWin32' ) {
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C++ to generate a folded perl hash.',
    CC        => 'g++',
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ['-lm -lstdc++'],
    OBJECT    => 'XML-Bare.o XML-Bare_wrap.o',
    LD        => 'g++',
    LDDLFLAGS => '-shared -L/usr/local/lib',
    depend    => { 'XML-Bare.o' => "parser.cc\n" },
    LICENSE   => 'perl'
  );
}
else {
  use Config;
  my $libpath = Config->{'archlibexp'};
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C++ to generate a folded perl hash.',
    CCFLAGS   => '/MT /DWIN32',
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ["$libpath\\core\\perl58.lib"],
    OBJECT    => 'XML-Bare.o XML-Bare_wrap.o',
    LDDLFLAGS => '/DLL',
    depend    => { 'XML-Bare.o' => "parser.cc\n" },
    LICENSE   => 'perl'
  );
}

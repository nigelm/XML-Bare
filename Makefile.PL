#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
WriteMakefile(
  AUTHOR   => 'David Helkowski <test@codechild.com>',
  ABSTRACT => 'A minimal XML parser that uses C++ to generate a folded perl hash.',
  CC        => 'g++',
  NAME      => 'XML::Bare',
  VERSION   => "0.01",
  LIBS      => ['-lm -lstdc++'],
  OBJECT    => 'XML-Bare.o XML-Bare_wrap.o',
  LD        => 'g++',
  LDDLFLAGS => '-shared -L/usr/local/lib',
  depend    => { 'XML-Bare.o' => "parser.cc\n" }
);
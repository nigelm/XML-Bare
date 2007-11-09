#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.005;
if( $^O eq 'MSWin32' && !has_cc() ) {
  gen_msvc(); # special case for msvc
}
else {
  gen_cc(); # all others
}
sub gen_msvc {
  require Config;
  my $libpath = Config->{'archlibexp'};
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C to generate a folded perl hash.',
    CCFLAGS   => "/MT /DWIN32 /TP /DNOSTRING",
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ["$libpath\\core\\perl58.lib"],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '/DLL',
    LICENSE   => 'perl'
  );
}
sub gen_cc {
  WriteMakefile(
    AUTHOR   => 'David Helkowski <cpan@codechild.com>',
    ABSTRACT => 'A minimal XML parser that uses C to generate a folded perl hash.',
    NAME      => 'XML::Bare',
    VERSION_FROM => 'Bare.pm',
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    CCFLAGS   => '-shared',
    LDDLFLAGS => '-L/usr/local/lib',
    LICENSE   => 'perl'
  );
}
sub has_cc {
  my $div = (substr($ENV{'PATH'},0,1) eq '/') ? ':' : ';';
  my @path = split($div,$ENV{'PATH'});
  foreach my $dir ( @path ) {
    return 1 if( -e "$dir/cc" ||
                 -e "$dir/gcc" ||
                 -e "$dir/cc.exe" ||
                 -e "$dir/gcc.exe" ); }
  return 0;
}

#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'A minimal XML parser that uses C to generate a folded perl hash.',
               NAME         => 'XML::Bare',
               VERSION_FROM => 'Bare.pm',
               PREREQ_PM    => { Carp => 0, Exporter => 0, DynaLoader => 0 },
               #OPTIMIZE     => '-O3 -msse2 -march=pentium4 --omit-frame-pointer',
             );
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}

if( $^O eq 'MSWin32' && !has_cc() ) {
  gen_msvc(); # special case for msvc
}
elsif( $^O eq 'darwin' ) {
  gen_darwin(); # darwin
}
else {
  gen_cc(); # all others
}
sub gen_msvc {
  require Config;
  my $libpath = Config->{'archlibexp'};
  my $ver = $]*1000; # correct for possibile division problems
  my ($major,$minor,$sub) = unpack("AA3xA3","$ver");
  $major *= 1; $minor *= 1; $sub *= 1;
  WriteMakefile( @basics,
    CCFLAGS   => "/MT /DWIN32 /TP /DNOSTRING",
    LIBS      => ["$libpath\\core\\perl$major$minor.lib"],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '/DLL',
  );
}
sub gen_cc {
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    LDDLFLAGS => '-shared -L/usr/local/lib',
  );
}
sub gen_darwin {
  if( substr(`which gcc`,0,2) eq 'no' ) {
    print "XCode must be installed.\n";
    exit 1;
  }
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Bare.o parser.o',
    CCFLAGS   => "-dynamiclib -DDARWIN -fno-common",
    LDDLFLAGS => '',
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

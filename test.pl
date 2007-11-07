#!/usr/bin/perl -w
#use Data::Dumper;
use strict;
use Time::HiRes qw(gettimeofday);

#my $file = 'feed2.xml';
my $file = $ARGV[1] || 'test.xml';
my $root;
my $s;
my $s2;
my $s3;
my $usec;
my $usec2;
my $usec3;
my $sa;
my $sb;
my $sc;

my $base1;
my $base2;
my $base3;

print "-Module-              load     parse    total\n";

exit if( !$ARGV[0] );

{
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Bare;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $ob = new XML::Bare( file => $file );
    $root = $ob->parse();
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000); $base1 = $sa;
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000); $base2 = $sb;
    $sc = $s3-$s + (($usec3-$usec)/1000000); $base3 = $sc;
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::Bare             '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '1' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Parser; require XML::Parser::EasyTree;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $p1 = new XML::Parser(Style=>'EasyTree');
    $root = $p1->parsefile($file);
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    
    print 'XML::Parser::EasyTree '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '2' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Handler::Trees; require XML::Parser::PerlSAX;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $p=XML::Parser::PerlSAX->new();
    my $h=XML::Handler::EasyTree->new();
    $root=$p->parse(Handler=>$h,Source=>{SystemId=>$file});
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa = $sa / $base1; $sb /= $base2; $sc /= $base3;
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    
    print 'XML::Handler::Trees   '.$sa." ".$sb." ".$sc."\n";
  }
}


if( $ARGV[0] eq '3' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Twig;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $t = XML::Twig->new->parsefile( $file );
    $root = $t->root->simplify;
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    
    print 'XML::Twig             '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '4' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::LibXML;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file( $file );
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    
    print 'XML::LibXML (no tree) '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '5' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Smart;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $XML = XML::Smart->new($file);
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    
    print 'XML::Smart            '.$sa." ".$sb." ".$sc."\n";
  }
}


if( $ARGV[0] eq '6' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Simple;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $ref = XML::Simple::XMLin($file);
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::Simple           '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '7' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::SAX::Simple;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $ref = XML::SAX::Simple::XMLin($file);
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::SAX::Simple      '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '8' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::Trivial;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $xml = XML::Trivial::parseFile($file);
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::Trivial          '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '9' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::TreePP;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parsefile( $file );
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::TreePP           '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '10' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::XPath::XMLParser;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $parser = XML::XPath::XMLParser->new;
    my $tree = $parser->parsefile( $file );
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::XPath::XMLParser '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '11' ) {
  ($s, $usec) = gettimeofday();
  if( eval( "require XML::DOM::Lite;" ) ) {
    ($s2, $usec2) = gettimeofday();
    my $doc = XML::DOM::Lite::Parser->parseFile( $file );
    ($s3, $usec3) = gettimeofday();
    $sa = $s2-$s + (($usec2-$usec)/1000000);
    $sb = $s3-$s2 + (($usec3-$usec2)/1000000);
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = fixed( $sa ); $sb = fixed( $sb ); $sc = fixed( $sc );
    print 'XML::DOM::Lite        '.$sa." ".$sb." ".$sc."\n";
  }
}

if( $ARGV[0] eq '12' ) {
  ($s, $usec) = gettimeofday();
  if( -e "xmltest.exe" ) {
    `xmltest $file`; # modified exe from tinyxml dist
    ($s3, $usec3) = gettimeofday();
    $sc = $s3-$s + (($usec3-$usec)/1000000);
    $sa /= $base1; $sb /= $base2; $sc /= $base3;
    
    $sa = '        '; $sb = '        '; $sc = fixed( $sc );
    print 'TinyXML               '.$sa." ".$sb." ".$sc."\n";
  }
}

sub fixed {
  my $in = shift;
  $in *= 10000;
  $in = int( $in );
  $in /= 10000;
  my $a = "$in";
  my $len = length( $a );
  if( $len > 8 ) { $a = substr( $a, 8 ); }
  if( $len < 8 ) {
    while( $len < 8 ) {
      $a = "${a} ";
      $len = length( $a );
    }
  }
  return $a;
}



#!/usr/bin/perl
use strict;

my $div    = "\/";
my $maxlen = 26;
my $file   = $ARGV[1] || 'test.xml';
my ( $root, $s, $s2, $s3, $usec, $usec2, $usec3, $sa, $sb, $sc, $base1, $base2, $base3 );

my $onlyone = $ARGV[2] ? 1 : 0;

tabit( "-Module-", 'load    ', 'parse   ', 'total' ) if ( !$onlyone );

exit if ( !$ARGV[0] );

use Time::HiRes qw(gettimeofday);

# For fairness; try to get the file to be read into memory cache
{
    open( FILE, '<', $file ) or die "Couldn't open $!";
    local $/ = undef;
    my $cache = <FILE>;
    close(FILE);
}

if ( $ARGV[0] * 1 >= 0 ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Bare;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ob = new XML::Bare( file => $file );
        $root = $ob->parse();

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Bare');
        timeit( 'XML::Bare', 1 );
    }
}

if ( $ARGV[0] eq '1' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Bare;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ob = new XML::Bare( file => $file );
        my $root = $ob->simple();

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Bare (simple)');
        timeit('XML::Bare (simple)');
    }
}

if ( $ARGV[0] eq '2' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::TreePP;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $tpp  = XML::TreePP->new();
        my $tree = $tpp->parsefile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::TreePP');
        timeit('XML::TreePP');
    }
}

if ( $ARGV[0] eq '3' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Parser; require XML::Parser::EasyTree;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $p1 = new XML::Parser( Style => 'EasyTree' );
        $root = $p1->parsefile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Parser::EasyTree');
        timeit('XML::Parser::EasyTree');
    }
}

if ( $ARGV[0] eq '4' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Handler::Trees; require XML::Parser::PerlSAX;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $p = XML::Parser::PerlSAX->new();
        my $h = XML::Handler::EasyTree->new();
        $root = $p->parse( Handler => $h, Source => { SystemId => $file } );

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Handler::Trees');
        timeit('XML::Handler::Trees');
    }
}

if ( $ARGV[0] eq '5' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Trivial;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $xml = XML::Trivial::parseFile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Trivial');
        timeit('XML::Trivial');
    }
}

if ( $ARGV[0] eq '6' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Smart;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $XML = XML::Smart->new($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Smart');
        timeit('XML::Smart');
    }
}

if ( $ARGV[0] eq '7' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
        my $ref = XML::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Simple (XML::Parser)');
        timeit('XML::Simple (XML::Parser)');
    }
}

if ( $ARGV[0] eq '8' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        $XML::Simple::PREFERRED_PARSER = 'XML::SAX::PurePerl';
        my $ref = XML::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Simple (PurePerl)');
        timeit('XML::Simple (PurePerl)');
    }
}

if ( $ARGV[0] eq '9' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        $XML::Simple::PREFERRED_PARSER = 'XML::LibXML::SAX::Parser';
        my $ref = XML::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Simple (LibXML)');
        timeit('XML::Simple (LibXML)');
    }
}

if ( $ARGV[0] eq '10' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        $XML::Simple::PREFERRED_PARSER = 'XML::Bare::SAX::Parser';
        my $ref = XML::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Simple (XML Bare)');
        timeit('XML::Simple (XML Bare)');
    }
}

if ( $ARGV[0] eq '11' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Bare::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ref = XML::Bare::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Bare::Simple');
        timeit('XML::Bare::Simple');
    }
}

if ( $ARGV[0] eq '12' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::SAX::Simple;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ref = XML::SAX::Simple::XMLin($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::SAX::Simple');
        timeit('XML::SAX::Simple');
    }
}

if ( $ARGV[0] eq '13' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Twig;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $t = XML::Twig->new->parsefile($file);
        $root = $t->root->simplify;

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Twig');
        timeit('XML::Twig');
    }
}

if ( $ARGV[0] eq '14' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Grove::Builder; require XML::Parser::PerlSAX;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $grove_builder = XML::Grove::Builder->new;
        my $parser        = XML::Parser::PerlSAX->new( Handler => $grove_builder );
        my $document      = $parser->parse( Source => { SystemId => $file } );

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Grove::Builder');
        timeit('XML::Grove::Builder');
    }
}

if ( $ARGV[0] eq '15' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::XPath::XMLParser;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $parser = XML::XPath::XMLParser->new;
        my $tree   = $parser->parsefile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::XPath::XMLParser');
        timeit('XML::XPath::XMLParser');
    }
}

if ( $ARGV[0] eq '16' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::DOM::Lite;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $doc = XML::DOM::Lite::Parser->parseFile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::DOM::Lite');
        timeit('XML::DOM::Lite');
    }
}

if ( $ARGV[0] eq '17' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Tiny;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $xmlfile;
        open( $xmlfile, $file );
        my $doc = XML::Tiny::parsefile($xmlfile);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Tiny');
        timeit('XML::Tiny');
    }
}

if ( $ARGV[0] eq '18' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::MyXML;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ob = XML::MyXML::xml_to_object( $file, { file => 1 } );

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::MyXML');
        timeit('XML::MyXML');
    }
}

if ( $ARGV[0] eq '19' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::TinyXML;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $ob = XML::TinyXML->new();
        $ob->loadFile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::TinyXML');
        timeit('XML::TinyXML');
    }
}

sub unload {
    my $module = shift;
    my @parts = split( ' ', $module );
    $module = $parts[0];
    $module =~ s/::/\//g;
    $module .= '.pm';
    delete $INC{$module};
}

sub timeit {
    my $name = shift;
    my $base = shift;
    $sa = $s2 - $s +  ( ( $usec2 - $usec ) / 1000000 );
    $sb = $s3 - $s2 + ( ( $usec3 - $usec2 ) / 1000000 );
    $sc = $s3 - $s +  ( ( $usec3 - $usec ) / 1000000 );
    if ($base) {
        $base1 = $sa;
        $base2 = $sb;
        $base3 = $sc;
    }
    $sa /= $base1;
    $sb /= $base2;
    $sc /= $base3;
    $sa = fixed($sa);
    $sb = fixed($sb);
    $sc = fixed($sc);
    if ( !$base || !$onlyone ) {
        tabit( $name, $sa, $sb, $sc );
    }
}

sub tabit {
    my ( $a, $b, $c, $d ) = @_;
    my $len = length($a);
    print $a;
    for ( 0 .. ( $maxlen - $len ) ) { print ' '; }
    print "$b $c $d
";
}

sub fixed {
    my $in = shift;
    $in *= 10000;
    $in = int($in);
    $in /= 10000;
    my $a   = "$in";
    my $len = length($a);
    if ( $len > 8 ) { $a = substr( $a, 8 ); }
    if ( $len < 8 ) {
        while ( $len < 8 ) {
            $a   = "${a} ";
            $len = length($a);
        }
    }
    return $a;
}

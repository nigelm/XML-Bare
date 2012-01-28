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

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Bare');
        timeit( 'XML::Bare', 1 );
    }
}

if ( $ARGV[0] eq '1' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::LibXML;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $parser = XML::LibXML->new();
        my $doc    = $parser->parse_file($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::LibXML');
        timeit('XML::LibXML');
    }
}

if ( $ARGV[0] eq '2' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Parser;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $parser = new XML::Parser();
        my $doc    = $parser->parsefile($file);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Parser');
        timeit('XML::Parser');
    }
}

if ( $ARGV[0] eq '3' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Parser::Expat;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $parser = new XML::Parser::Expat();
        sub noop { }
        $parser->setHandlers( 'Start' => \&noop, 'End' => \&noop, 'Char' => \&noop );
        open( FOO, $file ) or die "Couldn't open $!";
        $parser->parse(*FOO);
        close(FOO);

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Parser::Expat');
        timeit('XML::Parser::Expat');
    }
}

if ( $ARGV[0] eq '4' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::Descent;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $p = XML::Descent->new( { Input => $file } );
        $p->on(
            item => sub {
                my ( $elem, $attr ) = @_;
                $p->walk;    # recurse
            }
        );
        $p->walk;

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::Descent');
        timeit('XML::Descent');
    }
}

if ( $ARGV[0] eq '5' ) {
    ( $s, $usec ) = gettimeofday();
    if ( eval('require XML::DOM;') ) {
        ( $s2, $usec2 ) = gettimeofday();

        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parsefile($file);    ##

        ( $s3, $usec3 ) = gettimeofday();
        unload('XML::DOM');
        timeit('XML::DOM');
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
    print "$b $c $d\n";
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

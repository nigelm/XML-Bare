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

if ( -e "exe${div}barexml.exe" ) {
    ( $s, $usec ) = gettimeofday();
    `exe${div}barexml $file`;
    ( $s3, $usec3 ) = gettimeofday();
    $sc = $s3 - $s + ( ( $usec3 - $usec ) / 1000000 );
    $base3 = $sc;
    $sc /= $base3;
    if ( !$onlyone ) { tabit( 'Bare XML', '        ', '        ', fixed($sc) ); }
}

if ( $ARGV[0] eq '1' ) {

    if ( -e "exe${div}tinyxml.exe" ) {
        ( $s, $usec ) = gettimeofday();
        `exe${div}tinyxml $file`;
        ( $s3, $usec3 ) = gettimeofday();
        $sc = $s3 - $s + ( ( $usec3 - $usec ) / 1000000 );
        $sc /= $base3;
        tabit( 'Tiny XML', '        ', '        ', fixed($sc) );
    }

}

if ( $ARGV[0] eq '2' ) {

    if ( -e "exe${div}ezxml.exe" ) {
        ( $s, $usec ) = gettimeofday();
        `exe${div}ezxml $file`;
        ( $s3, $usec3 ) = gettimeofday();
        $sc = $s3 - $s + ( ( $usec3 - $usec ) / 1000000 );
        $sc /= $base3;
        tabit( 'EzXML', '        ', '        ', fixed($sc) );
    }

}

if ( $ARGV[0] eq '3' ) {

    if ( -e "exe${div}xmlio.exe" ) {
        ( $s, $usec ) = gettimeofday();
        `exe${div}xmlio $file`;
        ( $s3, $usec3 ) = gettimeofday();
        $sc = $s3 - $s + ( ( $usec3 - $usec ) / 1000000 );
        $sc /= $base3;
        tabit( 'XMLIO', '        ', '        ', fixed($sc) );
    }    ##

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

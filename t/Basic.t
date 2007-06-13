#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'XML::Bare' );

my $xml;
my $root;

$xml = new XML::Bare( text => "<xml><node>val</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{value}, 'val' );

$xml = new XML::Bare( text => "<xml><node/></xml>" );
$root = $xml->parse();
is( ref( $root->{xml}->{node} ), 'HASH' );

$xml = new XML::Bare( text => "<xml><node att=12>val</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{att}->{value}, '12' );

$xml = new XML::Bare( text => "<xml><node att=\"12\">val</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{att}->{value}, '12' );

$xml = new XML::Bare( text => "<xml><node><![CDATA[<cval>]]></node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{value}, '<cval>' );

$xml = new XML::Bare( text => "<xml><node>a</node><node>b</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->[1]->{value}, 'b' );

$xml = new XML::Bare( text => "<xml><multi_node/><node>a</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->[0]->{value}, 'a' );

# test basic mixed - value before
$xml = new XML::Bare( text => "<xml><node>val<a/></node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{value}, 'val' );

# test basic mixed - value after
$xml = new XML::Bare( text => "<xml><node><a/>val</node></xml>" );
$root = $xml->parse();
is( $root->{xml}->{node}->{value}, 'val' );

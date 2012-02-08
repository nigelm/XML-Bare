#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Harness;
use Test::More;
##use Data::Dump qw[dump];    # only needed for diag

use_ok('XML::Bare');

my $data = {
    hash => "#",
    amp  => '&',
    gt   => '>',
    lt   => '<',
    quot => '"',
    apos => "\'",
};
ok( $data, 'Built data hash' );

# build XML string with quoted values
my $xmldata = "<data>\n";
foreach ( keys %{$data} ) {
    $xmldata .= "<$_>";
    $xmldata .= ( $data->{$_} =~ /[\&\<\>\"\']/ ) ? ( '&' . $_ . ';' ) : $data->{$_};
    $xmldata .= "</$_>";
}
$xmldata .= " < /data>\n";

ok( $xmldata, 'Built XML string' );
##diag( dump($xmldata) );

# parse the provided XML into a hash
my $hash = XML::Bare::xmlin($xmldata);
ok( $hash, 'Parsed XML string into hash' );

##diag( dump( { wanted => $data, got => $hash } ) );

is_deeply( $hash, $data, 'Data retreived is correct' );

done_testing;

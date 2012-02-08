#!/usr/bin/perl -w

#
# This code tests for a set of memory leaks that were present in the simple
# decoder.   Its really crude, but should show up major issues...
#
use strict;
use warnings;

use Test::More;

plan skip_all => "This tests is for release candidate testing" unless ( $ENV{AUTHOR_TESTING} );

eval "use Unix::Getrusage";
plan skip_all => "Unix::Getrusage required for testing memory leakiness" if $@;

use_ok('XML::Bare');
use_ok('Unix::Getrusage');

no strict "subs";    # getrusage triggers this...

# Build an XML document, reasonable size, combination of hash and arrays
my $numbers = join( '', ( map {"<number>$_</number>"} 0 .. 100 ) );
my $xmldoc = join( '', '<document>', ( map {"<$_>$numbers</$_>"} 'a' .. 'z' ), '</document>' );

my $obj = XML::Bare->new( text => $xmldoc );
my $hash = $obj->simple;

ok( $hash, 'First conversion XML -> hash' );
undef($hash);        # force release
my $count = 0;

my $final_stats   = Unix::Getrusage::getrusage();    # preusing memory
my $initial_stats = Unix::Getrusage::getrusage();
ok( $initial_stats, 'Got process stats' );

foreach my $codepath ( 'simple', 'parse' ) {

    # now loop over conversion
    while ( $count++ < 500 ) {
        $obj = XML::Bare->new( text => $xmldoc );
        $hash = $obj->$codepath;
        undef($hash);                                # force release
    }

    ok( 1, "Completed test loop for $codepath" );

    $final_stats = Unix::Getrusage::getrusage();
    ok( $final_stats, "Got process stats" );

    my $is_slim = ( ( $initial_stats->{ru_maxrss} * 2 ) > $final_stats->{ru_maxrss} ) ? 1 : 0;
    ok( $is_slim, "Process has not bloated on $codepath codepath" );

    unless ($is_slim) {
        diag( "Initial: " . $initial_stats->{ru_maxrss} );
        diag( "Final:   " . $final_stats->{ru_maxrss} );
    }
}

done_testing;

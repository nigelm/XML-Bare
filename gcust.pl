my $tot = "@ARGV";
if( $tot =~ m/\.cc$/ ) {
  $cmd = "g++ $tot > res";
}
if( $tot =~ m/\.c$/ ) {
  $cmd = "gcc $tot > res";
}
print $cmd."\n";
$res = system( $cmd );
open( DAT, "res" );
$/ = '';
print <DAT>;
close( DAT );
exit $res;
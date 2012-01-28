#!/usr/bin/perl

print <<END;
Parsing without native Perl trees

END
print `perl onenotree.pl 7`;
my $file = $ARGV[0] || 'test.xml';
for my $i ( 0 .. 6 ) {
    print `perl onenotree.pl $i $file 1`;
}

#!/usr/bin/perl

print <<END;
Parsing using various test executables of libraries

END
print `perl oneexe.pl 5`;
my $file = $ARGV[0] || 'test.xml';
for my $i ( 0 .. 4 ) {
    print `perl oneexe.pl $i $file 1`;
}

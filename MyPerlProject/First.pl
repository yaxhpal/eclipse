#!/usr/bin/env perl
use warnings;
use 5.012;

#my @bl = qw(red green blue);
#my @a = qw(green yellow purple blue pink);
#
#my @s = grep{ not $_ ~~ @bl } @a;
#say "@s"; # yellow purple pink

use Business::ISBN;
use Data::Dumper;

my $isbntext = '123';
my $isbnobj = Business::ISBN->new($isbntext);
unless ($isbnobj && $isbnobj->is_valid()) {
	warn "This is null reference \n";
}
print Dumper $isbnobj; 
#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

open( FileDeletedItems, '/home/yashpal/tmp/deleteitems/deleteditems.txt' );
open( Removeditems,     '/home/yashpal/tmp/deleteitems/removed.txt' );

my @fdi = ();
my @rmi = ();

while (<FileDeletedItems>) {
	chomp;

	# 	print "$_\n";
	push( @fdi, $_ );
}

while (<Removeditems>) {
	chomp;

	# 	print "$_\n";
	push( @rmi, $_ );
}

my %rmihash = map{$_=>1} @rmi;
my %fdihash = map{$_=>1} @fdi;
my @diff = ();

for my $key ( keys %fdihash ) {
   push (@diff, $key) if (defined($rmihash{$key}));      
}
    
# my @diff = grep(!defined $hash{$_}, @fdi);

print scalar(@diff);

#print "$_\n" foreach (@diff);


close(FileDeletedItems);
close(Removeditems);

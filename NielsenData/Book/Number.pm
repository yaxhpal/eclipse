#!/usr/bin/perl
# Number.pm, a number as an object

package Number;	# This is the &quot;Class&quot;

sub new		# constructor, this method makes an object
		# that belongs to class Number
{
my $class = shift;		# $_[0] contains the class name
my $number = shift;	# $_[1] contains the value of our number
			# it is given by the user as an argument
my $self = {};		# the internal structure we'll use to represent
			# the data in our class is a hash reference
bless( $self, $class );	# make $self an object of class $class

$self->{num} = $number;	# give $self->{num} the supplied value
			# $self->{num} is our internal number
return $self;		# a constructor always returns an blessed() object
}

sub add		# add a number to our object's number
{
my $self = shift;	# $_[0] now contains the object on which the method
		        # was called (executed on)
my $add = shift;	# number to add to our number

$self->{num} += $add;	# add
return $self->{num};
# by returning our new number after each operation we could see
# its value easily, or we could use the dump() method which could
# show us the number without modifying its value.
}

sub subtract	# subtract from our number
{
my $self = shift;	# our object's internal data structure, as above
my $sub = shift;

$self->{num} -= $sub;
return $self->{num};
}

sub change	# assign new value to our number
{
my $self = shift;
my $newnum = shift;
$self->{num} = $newnum;
return self->{num};
}

sub dump	# return our number
{
my $self = shift;
return $self->{num};
}

1;		# this 1; is neccessary for our class to work
#!/usr/bin/perl 

package Book;


sub new () {
    my $class = shift;
    my $self = {
		'isbn10'          => shift,
		'isbn13'          => shift,
		'vendor_id'       => shift,
		'type'            => shift,
		'title'           => shift,
		'author'          => shift,
		'publisher'       => shift,
		'description'     => shift,
		'date_published'  => shift,
		'copyright_year'  => shift,
		'subject'         => shift,
		'thumbnail_url'   => shift,
		'image_url'       => shift,
		'edition'         => shift,
		'number_of_pages' => shift
    };
    
    # Print all the values just for clarification.
    print "First Name is $self->{_firstName}\n";
    print "Last Name is $self->{_lastName}\n";
    print "SSN is $self->{_ssn}\n";
    bless $self, $class;
    return $self;
}
sub setFirstName {
    my ( $self, $firstName ) = @_;
    $self->{_firstName} = $firstName if defined($firstName);
    return $self->{_firstName};
}

sub getFirstName {
    my( $self ) = @_;
    return $self->{_firstName};
}
1;
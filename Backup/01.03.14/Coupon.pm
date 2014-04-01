package C4::Coupon;

# Copyright 2014 Britsh Council
#
# The United Kingdom's international organisation for cultural relations and
# educational opportunities.
# A registered charity: 209131 (England and Wales) SCO37733 (Scotland)
#
# This module provides functionality to apply promotional coupons to various
# patron transactions such as registration.

use strict;
use warnings;
use Date::Simple ('date', 'today');
use Exporter;
use Data::Dumper;
use C4::SQLHelper qw(SearchInTable InsertInTable UpdateInTable  GetRecordCount);
use vars qw($VERSION @ISA @EXPORT);

BEGIN {
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(addCoupon updateCoupon applyCoupon updateCouponUseCount);
  }

=head1 METHODS

=head2 addCoupon

  addCoupon($couponcode, $type, $startdate, $enddate, $value, $maxlimit, $createdby);
  
=cut

sub addCoupon  {
	my ($couponcode, $type, $startdate, $enddate, $value, $maxlimit, $createdby) = @_;
	return 0 unless (defined($couponcode));
	my %data = ();
	$data{'couponcode'} 	= $couponcode;
	$data{'type'} 			= uc($type) 	if (defined($type));
	$data{'startdate'} 		= $startdate 	if (defined($startdate));
	$data{'enddate'} 		= $enddate 		if (defined($enddate));
	$data{'value'} 			= $value 		if (defined($value));
	$data{'maxlimit'} 		= $maxlimit 	if (defined($maxlimit));
	$data{'createdby'} 		= $createdby 	if (defined($createdby));
	$data{'modifiedby'} 	= $data{'createdby'};
	$data{'used'} 			= '0'; 
	$data{'createddate'} 	= undef; # Initializes this to current timestamp
	$data{'modifieddate'} 	= undef;
	
	return InsertInTable ('coupons',\%data, 1);
}

=head2 updateCoupon

  updateCoupon ($couponcode, $type, $startdate, $enddate, $value, $maxlimit, $modifiedby, $used);

=cut

sub updateCoupon {
	my ($couponcode, $type, $startdate, $enddate, $value, $maxlimit, $modifiedby, $used) = @_;
	return 0 unless (defined($couponcode));
	my %data = ();
	$data{'couponcode'} 	= $couponcode;
	$data{'type'} 			= uc($type)		if (defined($type));
	$data{'startdate'} 		= $startdate 	if (defined($startdate));
	$data{'enddate'} 		= $enddate 		if (defined($enddate));
	$data{'value'} 			= $value 		if (defined($value));
	$data{'maxlimit'} 		= $maxlimit 	if (defined($maxlimit));
	$data{'modifiedby'} 	= $modifiedby 	if (defined($modifiedby));
	$data{'used'} 			= $used 		if (defined($used));
	$data{'modifieddate'} 	= undef;
	
	return UpdateInTable('coupons', \%data);
}

=head2 applyCoupon

  applyCoupon($couponcode, $amount);
  
  $couponcode is code of coupon and $amount is
  the amount on which we are applying this coupon
  
  Returns discounted amount and coupon validity check

=cut

 sub applyCoupon  {
 my ($couponcode, $amount )= @_;
 my ($dbh, $sth, $coupon, $isValid, $discount, $message);
 my ($type, $startdate, $enddate, $value, $maxLimit, $used, $today);
 $dbh   = C4::Context->dbh;
 $sth = $dbh->prepare('SELECT type, startdate, enddate, value, max_used_limit, used FROM coupons WHERE code=?') or
    				   warn("Can't prepare SQL statement: $DBI::errstr\n");
 $sth->execute($couponcode) or warn "Can't execute SQL statement: $DBI::errstr\n";
 $coupon   = $sth->fetchrow_hashref();
 $isValid  = 0;
 $discount = 0;
 if (defined($coupon)) {
 	$type      = $coupon->{'type'};
 	$startdate = Date::Simple->new($coupon->{'startdate'});
 	$enddate   = Date::Simple->new($coupon->{'enddate'});
 	$today     = Date::Simple->today();
	$value     = $coupon->{'value'}; 	
 	$maxLimit  = $coupon->{'max_used_limit'};
 	$used      = $coupon->{'used'};
 	if ($startdate <= $today && $enddate >= $today && ($used < $maxLimit || !defined($maxLimit))) {
 		$isValid  = 1;
 		$discount = 0;
 		$used++;
 		if ($type eq 'P') {
 			$discount =  ($value * $amount)/100;
 		} else {
 			$discount = $value; 
 		}
 		# Coupon is valid
 		$message = 'Coupon successfully applied.'; 
 	} else {
 		# Coupon is invalid
 		$message = 'Invalid coupon.'; 
 	}
 } else {
 	$message = (defined($couponcode) && $couponcode ne '')?'Invalid coupon.':'';
 }
 $sth->finish();
 return ($amount-$discount, $isValid, $message);
}

=head2 updateDiscountCoupon

  updateCouponUseCount($couponcode);

=cut

sub updateCouponUseCount {
	my $couponcode = shift;
	my $result = SearchInTable('coupons', {'couponcode' => $couponcode}, undef, undef, undef, undef, "exact");
	if (defined($result)) {
		my $used = $result->[0]->{'used'} ;
		return updateCoupon($couponcode, undef, undef, undef, undef, undef, undef,($used + 1));
	}
	return 0;
}

END { }    # module clean-up code here (global destructor)

1;

__END__

=head1 AUTHORS

Techletsolutions Team

=cut


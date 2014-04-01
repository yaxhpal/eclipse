# Copyright 2014 Britsh Council
#
# The United Kingdom's international organisation for cultural relations and
# educational opportunities.
# A registered charity: 209131 (England and Wales) SCO37733 (Scotland)
#
# This module provides functionality to fetch data from external data provider
# vendors such as google, nielsen etc. If data if returned for given item, it 
# store them into database
#
use strict;
use warnings;
use LWP::Simple;
use XML::Simple;
use Business::ISBN;
use DBI;
use JSON::XS;
use Data::Dumper;
use Date::Simple ('date', 'today');
  
 my $dbh = DBI->connect("dbi:mysql:dbname=koha","root","", { RaiseError => 1 },) or die $DBI::errstr;
#  my $sth = $dbh->prepare("SELECT type, startdate, enddate, 
# 									  value, max_used_limit, used FROM
# 									  coupons WHERE code=?");
#  my $code = 'PROMO';
#  $sth->execute($code);
#  
#  my @result;
#  while ( my $data = $sth->fetchrow_hashref ) {
#        push @result, $data;
#    }
#  print Dumper @result;
#    
#  $sth->finish();
#  $dbh->disconnect();
  

#  my $endDate = Date::Simple->new('2014-02-25');
#  my $day = today();
#  
#  if ($endDate > $day) {
#  	print 'Hurray!!!'."\n"
#  } else {
#  	print 'Alas :('."\n"
#  }
  
 my ($discounted, $isValid) = &applyCoupon ("PROMO", 2000);
 
 print $discounted,"  ", $isValid, "\n";
  
&updateCouponUseCount("PR");


 sub applyCoupon () {
 my ( $couponcode, $amount )=@_;
 my ($isValid, $discount, $startDate, $endDate, $value, $maxLimit, $used, $type);
# my $dbh   = C4::Context->dbh;
 my $sth = $dbh->prepare('SELECT type, startdate, enddate, value, max_used_limit, used FROM coupons WHERE code=?');
 $sth->execute($couponcode);
 my $data = $sth->fetchrow_hashref();
 $isValid =  0;
 $discount = 0;
 if (defined($data)) {
 	$type = $data->{'type'};
 	$value = $data->{'value'};
 	$startDate =  Date::Simple->new($data->{'startdate'});
 	$endDate = Date::Simple->new($data->{'enddate'});
 	$maxLimit = $data->{'max_used_limit'};
 	$used = $data->{'used'};
 	if ($startDate <= today() && $endDate >= today() && $used < $maxLimit) {
 		$isValid  = 1;
 		$discount = 0;
 		$used++;
 		if ($type eq 'P') {
 			$discount =  ($value * $amount)/100;
 		} else {
 			$discount = $value; 
 		}
 	}
 }
 return ($amount-$discount, $isValid);
}
  
  
sub updateCouponUseCount () {
 my $couponcode = shift;
 if (defined($couponcode) && $couponcode ne '') {
	 my ($used, $sth, $usedhash, $statement);
	 $used = 0;
	 #$dbh   = C4::Context->dbh;
	 $sth = $dbh->prepare('SELECT used FROM coupons WHERE code=?');
	 $sth->execute($couponcode);
	 $usedhash  = $sth->fetchrow_hashref();
	 $statement = "UPDATE coupons SET used = ? WHERE code = ?";
	 $used = $usedhash->{'used'}  if (defined($usedhash));
	 $dbh->do($statement, undef, $used+1, $couponcode);
 }
}

  
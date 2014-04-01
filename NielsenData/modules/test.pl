# Copyright 2014 Britsh Council
#
# The United Kingdom's international organisation for cultural relations and
# educational opportunities.
# A registered charity: 209131 (England and Wales) SCO37733 (Scotland)
#
# This module provides functionality to fetch data from external data provider
# vendors such as google, nielsen etc. If data if returned for given item, it store
# them into database
#
use strict;
use warnings;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use Business::ISBN;

#my $string='<clientId>BcouncildelhiBDWS01</clientId><format>7</format><resultCode>00</resultCode><hits>1</hits><from>0</from><to>1</to><data><?xml version="1.0" encoding="ISO-8859-1"?>';
#
#print($string, "\n");
#$string  =~ s/\<\?xml.*?\?\>//g;
#print($string, "\n");

# 10 digit ISBNs
#my $isbn10 = Business::ISBN->new('1860498825');

# convert
#my $isbn13 = $isbn10->as_isbn13;

#print $isbn13->isbn;

my $reg_id = 'MH234243123';

$reg_id =  ($reg_id =~ /KH/)?substr($reg_id, 2): $reg_id;

print $reg_id;

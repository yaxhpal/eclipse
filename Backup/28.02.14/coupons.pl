#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
#

use strict;
use warnings;
use CGI;
use Data::Dumper;
use C4::Output;
use C4::Auth;
use C4::AuthoritiesMarc;
use C4::Koha;
use C4::NewsChannels;
use C4::Coupon;


my $input = new CGI;
my $dbh = C4::Context->dbh;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
          template_name => "coupons.tmpl",
                  query => $input,
        		   type => "intranet",
        authnotrequired => 0,
          flagsrequired => {
              catalogue => 1,
        },
    }
);


my $id				= $input->param('id');
my $op 				= $input->param('op');
my $code 			= $input->param('code');
my $startdate 		= $input->param('startdate');
my $enddate 		= $input->param('enddate');
my $value 			= $input->param('value');
my $type 			= $input->param('type');
my $max_used_limit 	= $input->param('max_used_limit');


# Carry out the operation

if($op eq 'add') {
	&add_coupon($code,$startdate,$enddate,$value,$max_used_limit,$type);
} else if ($op eq 'edit') {
	&edit_list($id);
} else if ($op eq 'update') {
	&update_list($id,$startdate,$enddate,$value,$max_used_limit,$type);
} else {
	 $error .= "ERROR in _koha_modify_biblio $query" . $dbh->errstr;
     warn $error;
}

my ($count,$results) = get_all_coupons();

my @loop;

	for (my $i=0; $i < $count; $i++){
		my %row = (
				id	=>	$results->[$i]{'id'},
		        code            => $results->[$i]{'code'},
				startdate      => $results->[$i]{'startdate'},
				enddate        => $results->[$i]{'enddate'},
				type        => $results->[$i]{'type'},
				value        => $results->[$i]{'value'},
				max_used_limit        => $results->[$i]{'max_used_limit'},
				);
		push @loop, \%row;
	}

$template->param(
    			loop => \@loop
				);


output_html_with_http_headers $input, $cookie, $template->output;



sub update_list {
	my ($id,$startdate,$enddate,$value,$max_used_limit,$type) = @_;
	my $query = "update coupons set startdate=? , enddate=? , value=? , type=?, max_used_limit=? where id=?";
	my $sth = $dbh->prepare( $query );
	$sth->execute($startdate,$enddate,$value,$type,$max_used_limit,$id);
	$sth->finish;		
}


sub add_coupon {
	my ($code,$startdate,$enddate,$value,$max_used_limit,$type) = @_;
	my $query = "insert into coupons ( code,startdate,enddate,value,max_used_limit,type ) values (?,?,?,?,?,?)";
	my $sth = $dbh->prepare( $query );
	$sth->execute($code,$startdate,$enddate,$value,$max_used_limit,$type);
	$sth->finish;
}

sub edit_list {
	
	my $edit = 1;
	my $id = shift;
	my $data;
	if($id) {
		my $sth=$dbh->prepare("select * from coupons where id=?");
		$sth->execute($id);
		$data=$sth->fetchrow_hashref;
		$sth->finish;
	}
	
	$template->param(
				edit		=>	$edit,
				id	=>	$data->{'id'},
				code            => $data->{'code'},
				startdate      => $data->{'startdate'},
				enddate        => $data->{'enddate'},
				type        => $data->{'type'},
				value        => $data->{'value'},
				max_used_limit        => $data->{'max_used_limit'},
				);
}

sub get_all_coupons {
	
	my @loop;
	
	my $sth=$dbh->prepare("select * from coupons order by id asc");
	$sth->execute();
	
	while (my $data = $sth->fetchrow_hashref) {  # retrieve one row
    	push(@loop,$data);
		}
	$sth->finish;
	
	return scalar (@loop),\@loop;
}
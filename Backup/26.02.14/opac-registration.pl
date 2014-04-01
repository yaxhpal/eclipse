#!/usr/bin/perl

# Copyright 2011 Nucsoft Osslabs (Member Registartion amit.gupta@osslabs.biz)
#
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
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;

use CGI;
use C4::Auth;    # checkauth, getborrowernumber.
use C4::Context;
use C4::Koha;
use C4::Circulation;
use C4::Output;
use C4::Dates qw/format_date/;
use C4::Members;
use C4::Branch;
use C4::Dates qw(format_date_in_iso);
use Date::Calc qw/Date_to_Days Today/;
use C4::SQLHelper qw(InsertInTable UpdateInTable SearchInTable);
use Data::Dumper;
use C4::Dates;
use C4::PaymentGateway;


my $input = new CGI;
my $op = $input->param('op');
my $mship = $input->param("type");
my $dbh = C4::Context->dbh;



my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-registration.tmpl",
        query           => $input,
        type            => "opac", 
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
        debug           => 1,      
    }
);

$template->param( from_ext => 1);
$template->param( mtype => $mship);

my $userinfo = $input->Vars;

my $branchcode 		= $input->param('branchcode');
my $categorycode 	= $input->param('mship');
my $firstname 		= $input->param('firstname');
my $surname 		= $input->param('surname');
my $dd 				= $input->param('dd');
my $mm 				= $input->param('mm');
my $yyyy 			= $input->param('yyyy');
my $title 			= $input->param('title');
my $dateofbirth 	= $dd."-".$mm."-".$yyyy;


$userinfo->{'dateofbirth'} = $dateofbirth;



my $sex 			= $input->param('sex');
my $profession 		= $input->param('profession');
my $address 		= $input->param('address');
my $city 			= $input->param('city');
my $pincode 		= $input->param('pincode');
my $state 			= $input->param('state');
my $country 		= $input->param('country');
my $email 			= $input->param('email');
my $telephone 		= $input->param('telephone');
my $isdt 			= $input->param('isdt');
my $stdt 			= $input->param('stdt');
my $mobile 			= $input->param('mobile');
my $fax 			= $input->param('fax');
my $isdf 			= $input->param('isdf');
my $stdf 			= $input->param('stdf');
my $agentcode 		= $input->param('agentcode');
my $reg_id 			= $input->param('reg_id');
my $result 			= $input->param('result');
my $branch 			= $input->param('branch');

my $branches = GetBranchesonlinereg();

my @branchloop;

for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    my $selected = 1 if $thisbranch eq $branch;
    my %row = (branchcode => $thisbranch,
                selected => $selected,
                branchname => $branches->{$thisbranch}->{'branchname'},
            );
    push @branchloop, \%row;
}

my @categories = C4::Category->seleonlinemem($branch);

my $default_borrowertitle;
my($borrowertitle)=GetTitles();
$template->param( title_cgipopup => 1) if ($borrowertitle);
my $borrotitlepopup = CGI::popup_menu(-name=>'title',
        -id => 'btitle',
        -values=>$borrowertitle,
        -override => 1,
        -default=>$default_borrowertitle
        );   
$template->param(
    branchloop => \@branchloop,
    branchcode => $branch,
    category_loop => \@categories,
    borrotitlepopup => $borrotitlepopup,
    DHTMLcalendar_dateformat =>  C4::Dates->DHTMLcalendar(),
    dateformat    => C4::Context->preference("dateformat"),  
);

if ($op eq 'add_form') {
     my $data;
     if ($reg_id gt 0){
     	
     	# Get the data in a hash from db for that reg_id
		my $sth=$dbh->prepare("SELECT * FROM member_registration WHERE reg_id=?");
		$sth->execute($reg_id);
		$data=$sth->fetchrow_hashref;
		
		# If there is no data corresponding to given registration 
		# then redirect user to start. This is done to prevent users
		# to manually tweaking with registration id
        if (!$data) {
        	print $input->redirect("/prices-and-plans");
        }
	  
   	    my $sth=$dbh->prepare("SELECT branchname FROM branches where branchcode = ?" );
   	    $sth->execute($branchcode);
	    my $data_b = $sth->fetchrow_array();
                
                if  ($branch eq ''){
                      for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
                          my $selected = 1 if $thisbranch eq $data->{'branchcode'} ;
                          my %row =(branchcode => $thisbranch,
                                selected => $selected,
                                branchname => $branches->{$thisbranch}->{'branchname'},
                               );
                         push @branchloop, \%row;
                     }
                   $template->param (branchloop => \@branchloop,
                                     branchcode => $data->{'branchcode'},);
                }
               else {
	             for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
                         my $selected = 1 if $thisbranch eq $branch;
                         my %row =(branchcode => $thisbranch,
                               selected => $selected,
                               branchname => $branches->{$thisbranch}->{'branchname'},
                              );
                         push @branchloop, \%row;
                    }
                    $template->param (branchloop => \@branchloop,
                                      branchcode => $branch,);
                }
                
	my $branch1 	= $userinfo->{'branchcode'};
	my $category 	= $userinfo->{'categorycode'};
	my $data_branch = $sth->fetchrow_array();
	
	
	my $sth=$dbh->prepare("SELECT description FROM categories where categorycode = ?" );
	$sth->execute($category);
	my $data_cat = $sth->fetchrow_array();
    $sth->finish();
        
        if ($branch eq ''){
                	my $sth=$dbh->prepare("SELECT description,categorycode from categories
                                               WHERE categorycode in (select categorycode from feeschargesrules where branchcode = ?) 
                                               AND categorycode in ('GL','GM13','DM13','PL13','OM13')");
                        $sth->execute($data->{'branchcode'});
                        my @row_loop;        
                        while (my $row=$sth->fetchrow_hashref){
                             if ($data->{'categorycode'} eq $row->{'categorycode'} ) {
                             $row->{'selected'} = 1;
                        }
                       push @categories,$row;
                     }
              }
         else {
                  @categories =C4::Category->seleonlinemem($branch);
         }
         my($borrowertitle)=GetTitles();
         $template->param( title_cgipopup => 1) if ($borrowertitle);
         my $borrotitlepopup = CGI::popup_menu(-name=>'title',
                                                -id => 'btitle',
                                                -values=>$borrowertitle,
                                                -override => 1,
                                                -default=>$data->{'title'}
                                       );
                $template->param (
                   					category_loop => \@categories,
                   					borrotitlepopup => $borrotitlepopup,
		   							branchcode_d => $data_b,
		   							categorycode_c => $data_cat,
		   							reg_id => $reg_id,
		   							categorycode => $data->{'categorycode'},
                   					firstname => $data->{'firstname'},
                   					surname => $data->{'surname'},
                   					title => $data->{'title'},
                   					dateofbirth => $dateofbirth,
                   					sex => $data->{'sex'},
                   					profession => $data->{'profession'},
                   					address => $data->{'address'},
                   					city => $data->{'city'},
                   					pincode => $data->{'pincode'},
                   					state => $data->{'state'},
                   					country => $data->{'country'},
                   					email => $data->{'email'},
                   					telephone => $data->{'telephone'},
                   					isdt => $data->{'isdt'},
					                stdt => $data->{'stdt'},
                   					fax => $data->{'fax'},
                   					isdf => $data->{'isdf'},
                   					stdf => $data->{'stdf'},
                   					agentcode => $data->{'agentcode'},
                   					mobile => $data->{'mobile'},
                   					cat_type	=> $mship,
                   					dd	=> $dd,
                   					mm	=> $mm,
                   					yyyy	=> $yyyy,
                   					mtype => $data->{'categorycode'},         
                   );
      }
 }
if ($op eq 'add_validate') {
$template->param(add_form => 1);
if ($input->param('reg_id')){
		my $dd 				= $input->param('dd');
		my $mm 				= $input->param('mm');
		my $yyyy 			= $input->param('yyyy');
		my $dateofbirth 	= $yyyy."-".$mm."-".$dd;
		my $sth=$dbh->prepare("SELECT * FROM member_registration WHERE reg_id=?");
        $sth->execute($reg_id);
		
		my $sth=$dbh->prepare("UPDATE member_registration SET branchcode =?, categorycode =?, firstname=?, surname =?,
        title =?, dateofbirth=?, sex =?, profession =?, address=?, city=?, pincode=?, state=?, country=?,
        email=?, telephone=?, isdt=?, stdt=?, mobile=?, fax=?, isdf=?, stdf=?, agentcode=?  WHERE reg_id = ?");
        
        $sth->execute($branchcode, $categorycode, $firstname, $surname, $title, $dateofbirth, $sex, $profession,$address, $city, $pincode, $state, $country,
        $email, $telephone, $isdt, $stdt, $mobile, $fax, $isdf, $stdf, $agentcode, $input->param('reg_id'));
         
		my $branch 		= $userinfo->{'branchcode'};
		my $category 	= $userinfo->{'categorycode'};  
		
		my $sth=$dbh->prepare("SELECT enrolmentfee FROM feeschargesrules WHERE branchcode = ? and categorycode = ?");
		
        $sth->execute($branchcode, $categorycode);	
		my $data = $sth->fetchrow_array();
	
		my $sth=$dbh->prepare("SELECT branchname FROM branches WHERE branchcode = ?" );
		$sth->execute($branch);
		my $data_branch = $sth->fetchrow_array();
		
		my $sth=$dbh->prepare("SELECT description FROM categories WHERE categorycode = ?" );
		$sth->execute($categorycode);
		my $data_cat = $sth->fetchrow_array();
		$sth->finish();
		
		$template->param(
						reg_id => $reg_id,
			 			branchcode_d => $data_branch,
			 			categorycode_c => $data_cat,
			 			branchcode => $branchcode,
			 			categorycode => $categorycode,
                        firstname => $firstname,
                        surname => $surname,
                        title => $title,
			 			dateofbirth => C4::Dates::format_date( $dateofbirth),
                         sex => $sex,
                         profession =>$profession, 
                         address => $address,
                         city => $city,
                         pincode => $pincode,
                         state => $state,
                         country => $country,
                         email => $email,
                         telephone => $telephone,
                         isdt => $isdt,
                         stdt => $stdt,
                         mobile => $mobile,
                         fax => $fax,
                         isdf => $isdf,
                         stdf => $stdf, 
                         agentcode => $agentcode,         
                         enrolmentfee => sprintf( "%.2f", $data),      
                         cat_type	=> $mship,
                        dd	=> $dd,
                   		mm	=> $mm,
                   		yyyy	=> $yyyy,
                                              
	    );
}
else {
	
my $branch = $branchcode;
my $category = $categorycode;


my $reg_id;


	$reg_id = NewReg($userinfo);



my $sth=$dbh->prepare("SELECT enrolmentfee FROM feeschargesrules WHERE branchcode = ? and categorycode = ?");
$sth->execute($branch, $category);
my $data = $sth->fetchrow_array();
my $sth=$dbh->prepare("SELECT branchname FROM branches WHERE branchcode = ?" );
$sth->execute($branch);
my $data_branch = $sth->fetchrow_array();
my $sth=$dbh->prepare("SELECT description FROM categories WHERE categorycode = ?" );
$sth->execute($category);
my $data_cat = $sth->fetchrow_array();
$sth->finish();
$template->param ( reg_id => $reg_id,
		   		   branchcode => $branchcode,
                   categorycode => $categorycode,
		   		   branchcode_d => $data_branch,
                   categorycode_c => $data_cat,
                   firstname => $userinfo->{'firstname'},
                   surname => $userinfo->{'surname'},
                   title => $userinfo->{'title'},
                   dateofbirth => C4::Dates::format_date ( $userinfo->{'dateofbirth'}),
                   dd	=> $dd,
                   mm	=> $mm,
                   yyyy	=> $yyyy,
                   sex => $userinfo->{'sex'},
                   address => $userinfo->{'address'},
                   city => $userinfo->{'city'},
                   pincode => $userinfo->{'pincode'},
                   state => $userinfo->{'state'},
                   country => $userinfo->{'country'},
                   email => $userinfo->{'email'},
                   telephone => $userinfo->{'telephone'},
                   isdt => $userinfo->{'isdt'},
                   stdt => $userinfo->{'stdt'},
                   mobile => $userinfo->{'mobile'},         
                   enrolmentfee => sprintf( "%.2f", $data),
                   cat_type	=> $mship,
                   );
}
}
if ($op eq 'payment'){
my $branchcode = $input->param('branchcode');
my $categorycode = $input->param('categorycode');
my $reg_id = $input->param('reg_id');
my $sth=$dbh->prepare("SELECT enrolmentfee FROM feeschargesrules WHERE branchcode = ? and categorycode = ?");
$sth->execute($branchcode, $categorycode);	
my $data = $sth->fetchrow_array();
my $sth=$dbh->prepare("SELECT description FROM categories where categorycode = ?" );
$sth->execute($categorycode);
my $data_cat = $sth->fetchrow_array();
my $sth_status=$dbh->prepare("UPDATE member_registration SET status = 'PENDING',amount = $data where reg_id = ?");
$sth_status->execute($reg_id);
$sth->finish();
#my $desc = "New Membership"." ". $data_cat;
my %args;
if ($branchcode eq 'CB' or $branchcode eq 'KD'){
  
}
else {    
      %args = (
                 'vpc_Amount' => 1*100, #//Final price should be multifly by 100
                 'vpc_AccessCode' => "6A6B74ED", #//Put your access code here
                 'vpc_Command' => "pay",
                 'vpc_Locale' => "en",
                 'vpc_MerchTxnRef' => "$reg_id", #//This should be something unique number, i have used the session id for this
                 'vpc_Merchant' => "245056072880", #//Add your merchant number here
                 'vpc_OrderInfo' => "$reg_id", #//this also better to be a unique number
                 'vpc_ReturnURL' => "http://opac.newlibrary.com/cgi-bin/koha/opac-payments.pl",#//Add the return url here so you have to code here to capture whether the payment done successfully or not
                 'vpc_Version' => "1",
              );

   Getpayment( %args);          
 }
}
output_html_with_http_headers $input, $cookie, $template->output;




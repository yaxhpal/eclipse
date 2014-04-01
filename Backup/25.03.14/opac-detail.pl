#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
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
use C4::Auth;
use C4::Branch;
use C4::Koha;
use C4::Serials;    #uses getsubscriptionfrom biblionumber
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Circulation;
use C4::Tags qw(get_tags);
use C4::Dates qw/format_date/;
use C4::XISBN qw(get_xisbns get_biblionumber_from_isbn);
use C4::External::Amazon;
use C4::External::Syndetics qw(get_syndetics_index get_syndetics_summary get_syndetics_toc get_syndetics_excerpt get_syndetics_reviews get_syndetics_anotes );
use C4::Review;
use C4::Members;
use C4::VirtualShelves;
use C4::XSLT;
use C4::NewsChannels;
use Data::Dumper;
use C4::Search;
use Authen::Captcha;
use C4::Nielsen qw(getItemDetails updateMarcRecord getNielsenMarc21);
BEGIN {
	if (C4::Context->preference('BakerTaylorEnabled')) {
		require C4::External::BakerTaylor;
		import C4::External::BakerTaylor qw(&image_url &link_url);
	}
}
my $build_grouped_results = C4::Context->preference('OPACGroupResults');
my $query = new CGI;
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-detail.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
    }
);
$template->param( from_ext => 1);
my $biblionumber = $query->param('biblionumber') || $query->param('bib');

my $rvw = $query->param("sreview");
my $mdhash = $query->param("mdhash");

# Get the Number of reviews and ratings.
# Only the approved one to be taken in context
my ($rvw_no,$rating,$rating_percenatage) = &get_rating($biblionumber);

$template->param( rvw => $rating );
$template->param( numberofreviews => $rvw_no );
$template->param( rating_percenatage => $rating_percenatage );

# END Get the Number of reviews and ratings.

# Code for Captcha
my $code;
my $md5sum;
my $number_of_characters = C4::Context->get_custom_config("captcha_characters");
my $results;


# Making a new object of Authen Captcha


my $data_folder = C4::Context->get_custom_config("data_folder");
my $output_folder = C4::Context->get_custom_config("output_folder");
my $captcha_location = C4::Context->get_custom_config("captcha_location");

my $captcha = Authen::Captcha->new(
  	data_folder 	=> $data_folder,
  	output_folder 	=> $output_folder,
  	width =>  45, # optional. default 25
	height => 55, # optional. default 35
  );
 
# create a captcha. Image filename is "$md5sum.png"
$md5sum = $captcha->generate_code($number_of_characters);

# Send captcha image to screen.
$template->param( captcha_image => $captcha_location.$md5sum );
$template->param(mdhash	=> $md5sum,);
my $status;

if ($rvw == 1) {
	my $name = $query->param("name");
	my $location = $query->param("location");
	my $content = $query->param("content");
	my $rating = $query->param("star2");
	$code = $query->param("code");
	
	$results = $captcha->check_code($code,$mdhash);
	
	if($results eq 1) {
		$status = &savereview($biblionumber, $borrowernumber, $content , $name , $rating, $location);	
	} elsif($results eq "-3") {
			$template->param(error_in_captcha	=> 1,);
	} elsif($results eq "-2") {
		
	} else {
		# Nothing to say
	}
}

my $n_o_r = &numberofreviews($biblionumber);

$template->param(results	=> $results, submitted => $status);
if ($n_o_r > 0) {
	$template->param( review_present => $n_o_r );
}

# Code for getting the Author of the month
my @author_of_month;
my ($count,$results)= &get_author_of_the_month();
	for (my $i=0; $i < $count; $i++){
		
		
		my %row = (
		        authorname            => $results->[$i]{'authorname'},
				dateofbirth             => format_date( $results->[$i]{'dateofbirth'} ),
				placeofbirth         => $results->[$i]{'placeofbirth'},
				description         => $results->[$i]{'description'}
				);
		push @author_of_month, \%row;
	}

$template->param(author_of_month => \@author_of_month);

# Get OPAC URL
if (C4::Context->preference('OPACBaseURL')){
     $template->param( OpacUrl => C4::Context->preference('OPACBaseURL') );
}


my ( $borr ) = GetMemberDetails( $borrowernumber );
my $categorytype = $borr->{'category_type'};
$template->param( categorytype => $categorytype );

$template->param( 'AllowOnShelfHolds' => C4::Context->preference('AllowOnShelfHolds') );
$template->param( 'ItemsIssued' => CountItemsIssued( $biblionumber ) );

####################################### Nielsen Starts ###################################################
#my $myisbn = GetISBNFromBiblionumber($biblionumber);
#my $marcupdatestatus = updateMarcRecord($myisbn);
#if ($marcupdatestatus) {
#	warn("Updated marc record successfully for ISBN: ".$myisbn."\n");
#}
####################################### Nielsen Ends ######################################################

my $record       = GetMarcBiblio($biblionumber);
if ( ! $record ) {
    print $query->redirect("/cgi-bin/koha/errors/404.pl");
    exit;
}
$template->param( biblionumber => $biblionumber );
# XSLT processing of some stuff
if (C4::Context->preference("OPACXSLTDetailsDisplay") ) {
    $template->param( 'XSLTBloc' => XSLTParse4Display($biblionumber, $record, 'Detail', 'opac') );
}

$template->param('OPACShowCheckoutName' => C4::Context->preference("OPACShowCheckoutName") ); 
# change back when ive fixed request.pl
my @all_items = &GetItemsInfo( $biblionumber, 'opac' );
my @items;
@items = @all_items unless C4::Context->preference('hidelostitems');

if (C4::Context->preference('hidelostitems')) {
    # Hide host items
    for my $itm (@all_items) {
        push @items, $itm unless $itm->{itemlost};
    }
}

my @new_list;

#$template->param( qry => C4::Context->preference('item-level_itypes') );

my @res_for_city = &GetCityWiseItemDetail($biblionumber);

my $t_avl;
my $t_total;

for my $itm (@res_for_city) {
		
		$t_avl = $t_avl + $itm->{available};
		$t_total = $t_total + $itm->{total};
        
    }


$template->param( available_items => $t_avl,
					total_items	=> $t_total );


my $dat = &GetBiblioData($biblionumber);

my $itemtypes = GetItemTypes();
# imageurl:
my $itemtype = $dat->{'itemtype'};
if ( $itemtype ) {
    $dat->{'imageurl'}    = getitemtypeimagelocation( 'opac', $itemtypes->{$itemtype}->{'imageurl'} );
    $dat->{'description'} = $itemtypes->{$itemtype}->{'description'};
}
my $shelflocations =GetKohaAuthorisedValues('items.location',$dat->{'frameworkcode'}, 'opac');
my $collections =  GetKohaAuthorisedValues('items.ccode',$dat->{'frameworkcode'}, 'opac');

#coping with subscriptions
my $subscriptionsnumber = CountSubscriptionFromBiblionumber($biblionumber);
my @subscriptions       = GetSubscriptions( $dat->{title}, $dat->{issn}, $biblionumber );

my @subs;
$dat->{'serial'}=1 if $subscriptionsnumber;
foreach my $subscription (@subscriptions) {
    my $serials_to_display;
    my %cell;
    $cell{subscriptionid}    = $subscription->{subscriptionid};
    $cell{subscriptionnotes} = $subscription->{notes};
    $cell{missinglist}       = $subscription->{missinglist};
    $cell{opacnote}          = $subscription->{opacnote};
    $cell{histstartdate}     = format_date($subscription->{histstartdate});
    $cell{histenddate}       = format_date($subscription->{histenddate});
    $cell{branchcode}        = $subscription->{branchcode};
    $cell{branchname}        = GetBranchName($subscription->{branchcode});
    $cell{hasalert}          = $subscription->{hasalert};
    #get the three latest serials.
    $serials_to_display = $subscription->{opacdisplaycount};
    $serials_to_display = C4::Context->preference('OPACSerialIssueDisplayCount') unless $serials_to_display;
	$cell{opacdisplaycount} = $serials_to_display;
    $cell{latestserials} =
      GetLatestSerials( $subscription->{subscriptionid}, $serials_to_display );
    push @subs, \%cell;
}

$dat->{'count'} = scalar(@items);

# If there is a lot of items, and the user has not decided
# to view them all yet, we first warn him
# TODO: The limit of 50 could be a syspref
my $viewallitems = $query->param('viewallitems');
if ($dat->{'count'} >= 50 && !$viewallitems) {
    $template->param('lotsofitems' => 1);
}

my $biblio_authorised_value_images = C4::Items::get_authorised_value_images( C4::Biblio::get_biblio_authorised_values( $biblionumber, $record ) );

my $norequests = 1;
my $branches = GetBranches();
my %itemfields;
for my $itm (@items) {
    $norequests = 0
       if ( (not $itm->{'wthdrawn'} )
         && (not $itm->{'itemlost'} )
         && ($itm->{'itemnotforloan'} < 0 || $itm->{'itemnotforloan'} eq '3' || not $itm->{'itemnotforloan'} )
		 && (not $itemtypes->{$itm->{'itype'}}->{notforloan} )
         && ($itm->{'itemnumber'} ));
	if ($itm->{'notforloan'} eq "3") {  
	      $template->param( ondisplay => 1);
	}
    if ( defined $itm->{'publictype'} ) {
        # I can't actually find any case in which this is defined. --amoore 2008-12-09
        $itm->{ $itm->{'publictype'} } = 1;
    }
    $itm->{datedue}      = format_date($itm->{datedue});
    $itm->{datelastseen} = format_date($itm->{datelastseen});

    # get collection code description, too
    if ( my $ccode = $itm->{'ccode'} ) {
        $itm->{'ccode'} = $collections->{$ccode} if ( defined($collections) && exists( $collections->{$ccode} ) );
    }
    if ( defined $itm->{'location'} ) {
        $itm->{'location_description'} = $shelflocations->{ $itm->{'location'} };
    }
    if (exists $itm->{itype} && defined($itm->{itype}) && exists $itemtypes->{ $itm->{itype} }) {
        $itm->{'imageurl'}    = getitemtypeimagelocation( 'opac', $itemtypes->{ $itm->{itype} }->{'imageurl'} );
        $itm->{'description'} = $itemtypes->{ $itm->{itype} }->{'description'};
    }
    foreach (qw(ccode enumchron copynumber itemnotes uri)) {
        $itemfields{$_} = 1 if ($itm->{$_});
    }

     # walk through the item-level authorised values and populate some images
     my $item_authorised_value_images = C4::Items::get_authorised_value_images( C4::Items::get_item_authorised_values( $itm->{'itemnumber'} ) );
     # warn( Data::Dumper->Dump( [ $item_authorised_value_images ], [ 'item_authorised_value_images' ] ) );

     if ( $itm->{'itemlost'} ) {
         my $lostimageinfo = List::Util::first { $_->{'category'} eq 'LOST' } @$item_authorised_value_images;
         $itm->{'lostimageurl'}   = $lostimageinfo->{ 'imageurl' };
         $itm->{'lostimagelabel'} = $lostimageinfo->{ 'label' };
     }

     if( $itm->{'count_reserves'}){
          if( $itm->{'count_reserves'} eq "Waiting"){ $itm->{'waiting'} = 1; }
          if( $itm->{'count_reserves'} eq "Reserved"){ $itm->{'onhold'} = 1; }
     }
    
     my ( $transfertwhen, $transfertfrom, $transfertto ) = GetTransfers($itm->{itemnumber});
     if ( defined( $transfertwhen ) && $transfertwhen ne '' ) {
        $itm->{transfertwhen} = format_date($transfertwhen);
        $itm->{transfertfrom} = $branches->{$transfertfrom}{branchname};
        $itm->{transfertto}   = $branches->{$transfertto}{branchname};
     }
}

## get notes and subjects from MARC record
my $dbh              = C4::Context->dbh;
my $marcflavour      = C4::Context->preference("marcflavour");
my $marcnotesarray   = GetMarcNotes   ($record,$marcflavour);
my $marcisbnsarray   = GetMarcISBN    ($record,$marcflavour);
my $marcauthorsarray = GetMarcAuthors ($record,$marcflavour);
my $marcsubjctsarray = GetMarcSubjects($record,$marcflavour);
my $marcseriesarray  = GetMarcSeries  ($record,$marcflavour);
my $marcurlsarray    = GetMarcUrls    ($record,$marcflavour);
my $subtitle         = GetRecordValue('subtitle', $record, GetFrameworkCode($biblionumber));
my $stmtres          = $record -> subfield('245','c');



    $template->param(
                     MARCNOTES               => $marcnotesarray,
                     MARCSUBJCTS             => $marcsubjctsarray,
                     MARCAUTHORS             => $marcauthorsarray,
                     MARCSERIES              => $marcseriesarray,
                     MARCURLS                => $marcurlsarray,
                     MARCISBNS               => $marcisbnsarray,
                     norequests              => $norequests,
                     RequestOnOpac           => C4::Context->preference("RequestOnOpac"),
                     itemdata_ccode          => $itemfields{ccode},
                     itemdata_enumchron      => $itemfields{enumchron},
                     itemdata_uri            => $itemfields{uri},
                     itemdata_copynumber     => $itemfields{copynumber},
                     itemdata_itemnotes          => $itemfields{itemnotes},
                     authorised_value_images => $biblio_authorised_value_images,
                     subtitle                => $subtitle,
		     stmtres                 => $stmtres,		      
    );

foreach ( keys %{$dat} ) {
    $template->param( "$_" => defined $dat->{$_} ? $dat->{$_} : '' );
}


### Get the values of Subjects and Authors of Books
my @sub_array = @$marcsubjctsarray;
my @sbjcts;
my $c = 0;

foreach(@sub_array) {
	push @sbjcts , $sub_array[$c]->{MARCSUBJECT_SUBFIELDS_LOOP}[0]->{link_loop}[0]->{link};
	$c++;
} 


my @athrs;
my $n = 0;
my $auth_array = $marcauthorsarray;



foreach($auth_array) {
	push @athrs , $auth_array->[$n]->{MARCAUTHOR_SUBFIELDS_LOOP}[0]->{value};
	$n++;
}


### End Gettig the values of Authors and Books



my @auth_results;
my @sub_results;
my $tmp;
my @recc;
my @by_auth;
my $i;



## Perform Search only if There exists more than 0 authors and Subjects for that book
#if(scalar @athrs > 1) {
#	
#	@auth_results = &get_search_vals(\@athrs,'au');	
#	
#	
#	my @biblionumbers_for_auth;
#my $i=0;
#foreach (@auth_results) {
#		    $biblionumbers_for_auth[$i] = $_->{'biblionumber'};
#		    $i++;
#		}
#		
#		
#		
#		##### by Auth
#
#
#
#	for (my $i=0; $i < 5; $i++){
#		
#		my $record = GetMarcBiblio($biblionumbers_for_auth[$i]);
#		my $marcisbnsarray_rec   = GetMarcISBN   ($record,$marcflavour);
#		my $subtitle         = GetRecordValue('subtitle', $record, GetFrameworkCode($biblionumbers_for_auth[$i]));
##		
#
#		my ($nu,$bib_data) = &GetBiblio($biblionumbers_for_auth[$i]);
#
#		my $isbn = $marcisbnsarray_rec->[0]->{marcisbn};
##		
##		
#		my $niel_img = &get_image_from_isbn($isbn); # For By Author
#		my $b =	&GetBiblionumberFromISBN($isbn);
#		
#		my %row = (
#		        isbn            => $isbn,
#				image_path	=> $niel_img,
#				subtitle	=> $bib_data->{title},
#				biblionumber	=> $biblionumbers_for_auth[$i]
#				);
#		push @by_auth, \%row;
#		
#	}
#
#$template->param(by_auth => \@by_auth);
#
##$template->param(show_by_auth => 1);



#######
		
	
#}

my @dummy;

push @dummy , $sbjcts[0];

@sub_results = &get_items_for_isbn(\@dummy,'su',$sbjcts[0]);
	
	
	
	my @biblionumbers_for_sub;
$i =0;
foreach (@sub_results) {
		    $biblionumbers_for_sub[$i] = $_->{'biblionumber'};
		    $i++;
		}		
		



if(scalar @biblionumbers_for_sub > 0) {

	for (my $i=0; $i < scalar @biblionumbers_for_sub; $i++){
		
		if($i < 5 ) {
		
		my $record = GetMarcBiblio($biblionumbers_for_sub[$i]);
		#my $marcisbnsarray_rec   = GetMarcISBN   ($record,$marcflavour);
		my $subtitle         = GetRecordValue('subtitle', $record, GetFrameworkCode($biblionumbers_for_sub[$i]));
#		
		#my $isbn = $marcisbnsarray_rec->[0]->{marcisbn};
		my $isbn = GetISBNFromBiblionumber($biblionumbers_for_sub[$i]);
		my ($nu,$bib_data) = &GetBiblio($biblionumbers_for_sub[$i]);
#		
		my $niel_img;
		my $b =	&GetBiblionumberFromISBN($isbn); # By Subject
		
		my $marcurlsarray    = GetMarcUrls    ($record,$marcflavour);
		my $val = $marcurlsarray->[0]->{linktext};
		my $image_for_recc;
		
		if($val eq "") {
			$image_for_recc = &get_image_from_isbn($isbn);
			}
		else {
			$image_for_recc = &get_image_from_ebrary($biblionumbers_for_sub[$i]);
		}
		
		
		
		
		my %row = (
		        isbn            => $isbn,
				image_path	=> $image_for_recc,
				subtitle	=> substr ($bib_data->{title},0,30) ,
				biblionumber	=> $biblionumbers_for_sub[$i]
				);
		push @recc, \%row;
		
	}
	}

$template->param(recc => \@recc);

$template->param(show_by_sub => "1");

}		
		



# START Code for getting related items by isbn numbers


#my $record1 = GetMarcBiblio($biblionumber);
#my $marcisbnsarray_isbn   = GetMarcISBN   ($record1,$marcflavour);
#my $isbn_no = $marcisbnsarray_isbn->[0]->{marcisbn};
my @test_array;

push @test_array , $athrs[0];

my @related_items_by_isbn = &get_items_for_isbn(\@test_array,'au',$athrs[0]);

my @bib_for_isbn;

$i = 0;
foreach (@related_items_by_isbn) {
		    $bib_for_isbn[$i] = $_->{'biblionumber'};
		    $i++;
			}
		    


my @author_related;

if(scalar @bib_for_isbn > 0) {

	for (my $i=0; $i < scalar @bib_for_isbn; $i++){
		
		if($i < 5 ) {
		
		my $record = GetMarcBiblio($bib_for_isbn[$i]);
		#my $marcisbnsarray_rec   = GetMarcISBN   ($record,$marcflavour);
		my $subtitle         = GetRecordValue('subtitle', $record, GetFrameworkCode($bib_for_isbn[$i]));
#		
		#my $isbn = $marcisbnsarray_rec->[0]->{marcisbn};
		my $isbn = GetISBNFromBiblionumber($bib_for_isbn[$i]);
		
		my ($nu,$bib_data) = &GetBiblio($bib_for_isbn[$i]);
#		
		my $niel_img;
		my $b =	&GetBiblionumberFromISBN($isbn); # By Subject
		
		my $marcurlsarray    = GetMarcUrls    ($record,$marcflavour);
		my $val = $marcurlsarray->[0]->{linktext};
		my $image_for_recc;
		
		if($val eq "") {
			$image_for_recc = &get_image_from_isbn($isbn);
			}
		else {
			$image_for_recc = &get_image_from_ebrary($bib_for_isbn[$i]);
		}
		
		
		
		
		my %row = (
		        isbn            => $isbn,
				image_path	=> $image_for_recc,
				subtitle	=> substr ($bib_data->{title},0,30) ,
				biblionumber	=> $bib_for_isbn[$i]
				);
		push @author_related, \%row;
		
	}
	}


$template->param(by_auth => \@author_related);

$template->param(show_by_auth => 1);


}












my @all_items1;

foreach (@bib_for_isbn) {
	push @all_items1 , &GetCityWiseItemDetail( $_ );
}



my @fin_items;
for my $itm (@all_items1) {
		if ($itm->{biblionumber} ne $biblionumber) {
			push @fin_items, $itm ;
		}
        
    }



my $length = scalar @fin_items;



# some useful variables for enhanced content;
# in each case, we're grabbing the first value we find in
# the record and normalizing it
my $upc = GetNormalizedUPC($record,$marcflavour);
my $ean = GetNormalizedEAN($record,$marcflavour);
my $oclc = GetNormalizedOCLCNumber($record,$marcflavour);
#my $isbn = GetNormalizedISBN(undef,$record,$marcflavour);

my $isbn = GetISBNFromBiblionumber($biblionumber);

# Techlet Solutions
if ($isbn) {
	my $n_data = getItemDetails($isbn);
	if ($n_data) {
		my @authorarray = split(/,/, $n_data->{'author'});
		my @AUTHARRAY;
		my $author;
		foreach (@authorarray) {
			$author = {"author" => $_};
			push(@AUTHARRAY, $author);
	 	}
		if ($n_data->{'title'}) {
			$template->param(
						'enableNielsen'					=> '1',
						'nielsen-image_url' 			=> $n_data->{'image_url'},
						'nielsen-title' 				=> $n_data->{'title'},
						'nielsen-authors'				=> \@AUTHARRAY,
						'nielsen-edition' 				=> $n_data->{'edition'},
						'nielsen-publisher' 			=> $n_data->{'publisher'},
						'nielsen-pulishing-place' 		=> $n_data->{'publishing_place'},
						'nielsen-publishing-year' 		=> $n_data->{'date_published'} =~ /(\d+)/,
						'nielsen-pages' 				=> $n_data->{'number_of_pages'},
						'nielsen-physical-condition' 	=> $n_data->{'physical_condition'},
						'nielsen-isbn13' 				=> $n_data->{'isbn13'},
						'nielsen-isbn10' 				=> $n_data->{'isbn10'},
						'nielsen-issn' 					=> $n_data->{'issn'},
						'nielsen-subject' 				=> $n_data->{'subject'},
						'nielsen-description' 			=> $n_data->{'description'},
						'nielsen-copyrightdate'			=> $n_data->{'copyright_year'},
						'nielsen-series'				=> $n_data->{'series'},);
		}
	}
}

my $ms1234 = &check_if_image_already_present($isbn);  #DEBUG CODE

# my $f_isbn = $marcisbnsarray->[0]->{marcisbn}; DEBUG CODE
my $niel_img = &get_image_from_isbn($isbn);



my $content_identifier_exists = 1 if ($isbn or $ean or $oclc or $upc);
$template->param(
	normalized_upc => $upc,
	normalized_ean => $ean,
	normalized_oclc => $oclc,
	normalized_isbn => $isbn,
	ms1234		=> $ms1234, # for DEBUG CODE
	
	content_identifier_exists =>  $content_identifier_exists,
);

# COinS format FIXME: for books Only
$template->param(
    ocoins => GetCOinSBiblio($biblionumber),
);



my $val = $marcurlsarray->[0]->{linktext};

if($val eq "") {
	$template->param(
    	image_path => $niel_img
	);
}
else {
	my $e_img = &get_image_from_ebrary($biblionumber);
	$template->param(
    	image_path => $e_img
);
}


my $item_type_for_dvd = &get_marc_biblio_itemtype($biblionumber);



$template->param(
    	test_ms => Dumper $item_type_for_dvd
);


if ($item_type_for_dvd =~ /DVD/) {
	
	my $dvd_img = &get_image_from_biblio($biblionumber);
	
	$template->param(
    	image_path => $dvd_img
);
}

my $fl;

if($val=~/britishcouncilonline/) {
	$fl = 1;
}


$template->param(
    	show_hold_or_ebrary => $fl,
	);

my $det = &get_desc_from_isbn($isbn);

# For meta description tag on detail pages
my $meta_description = substr $det,0,160;


$template->param(
    meta_description => $meta_description
);


# Description from Nielsen API
$template->param(
    details => $det
);




my $sb = &get_subject_from_isbn($isbn);


# Subject from Nielsen API
$template->param(
    subject => $sb
);


my $reviews = getreviews( $biblionumber, 1 );
my $loggedincommenter;
foreach ( @$reviews ) {
    my $borrowerData   = GetMember('borrowernumber' => $_->{borrowernumber});
    # setting some borrower info into this hash
    $_->{title}     = $borrowerData->{'title'};
    $_->{surname}   = $borrowerData->{'surname'};
    $_->{firstname} = $borrowerData->{'firstname'};
    $_->{userid}    = $borrowerData->{'userid'};
    $_->{cardnumber}    = $borrowerData->{'cardnumber'};
    $_->{datereviewed} = format_date($_->{datereviewed});
    
    
    if ($borrowerData->{'borrowernumber'} eq $borrowernumber) {
		$_->{your_comment} = 1;
		$loggedincommenter = 1;
	}
}

my $flag_ebk = &get_status_for_ebrary($borrowernumber,"EBRARY",$borr->{'dateexpiry'},$borr->{'categorycode'});


$template->param(view_or_login => $flag_ebk);

# We have made a check that a borrower would only be allowed to do 1 review per book.

my $check_if = &check_if_reviewed($biblionumber,$borrowernumber);

$template->param(check_if_reviewed => $check_if);

# END We have made a check that a borrower would only be allowed to do 1 review per book.


# getting rating percentages 
foreach ( @$reviews ) {
	my $r = $_->{rating}; 
	$r = ($_->{rating}*100)/5; 
	$_->{rating} = $r;
}


if(C4::Context->preference("ISBD")) {
	$template->param(ISBD => 1);
}

$template->param(
    ITEM_RESULTS        => \@items,
    subscriptionsnumber => $subscriptionsnumber,
    biblionumber        => $biblionumber,
    subscriptions       => \@subs,
    subscriptionsnumber => $subscriptionsnumber,
    reviews             => $reviews,
    loggedincommenter   => $loggedincommenter
);

# Lists

if (C4::Context->preference("virtualshelves") ) {
   $template->param( 'GetShelves' => GetBibliosShelves( $biblionumber ) );
}


# XISBN Stuff
if (C4::Context->preference("OPACFRBRizeEditions")==1) {
    eval {
        $template->param(
            XISBNS => get_xisbns($isbn)
        );
    };
    if ($@) { warn "XISBN Failed $@"; }
}

# Serial Collection
my @sc_fields = $record->field(955);
my @serialcollections = ();

foreach my $sc_field (@sc_fields) {
    my %row_data;

    $row_data{text}    = $sc_field->subfield('r');
    $row_data{branch}  = $sc_field->subfield('9');

    if ($row_data{text} && $row_data{branch}) { 
	push (@serialcollections, \%row_data);
    }
}

if (scalar(@serialcollections) > 0) {
    $template->param(
	serialcollection  => 1,
	serialcollections => \@serialcollections);
}

# Amazon.com Stuff
if ( C4::Context->preference("OPACAmazonEnabled") ) {
    $template->param( AmazonTld => get_amazon_tld() );
    my $amazon_reviews  = C4::Context->preference("OPACAmazonReviews");
    my $amazon_similars = C4::Context->preference("OPACAmazonSimilarItems");
    my @services;
    if ( $amazon_reviews ) {
        push( @services, 'EditorialReview', 'Reviews' );
    }
    if ( $amazon_similars ) {
        push( @services, 'Similarities' );
    }
    my $amazon_details = &get_amazon_details( $isbn, $record, $marcflavour, \@services );
    my $similar_products_exist;
    if ( $amazon_reviews ) {
        my $item = $amazon_details->{Items}->{Item}->[0];
        my $customer_reviews = \@{ $item->{CustomerReviews}->{Review} };
        for my $one_review ( @$customer_reviews ) {
            $one_review->{Date} = format_date($one_review->{Date});
        }
        my $editorial_reviews = \@{ $item->{EditorialReviews}->{EditorialReview} };
        my $average_rating = $item->{CustomerReviews}->{AverageRating} || 0;
        $template->param( amazon_average_rating    => $average_rating * 20);
        $template->param( AMAZON_CUSTOMER_REVIEWS  => $customer_reviews );
        $template->param( AMAZON_EDITORIAL_REVIEWS => $editorial_reviews );
    }
    if ( $amazon_similars ) {
        my $item = $amazon_details->{Items}->{Item}->[0];
        my @similar_products;
        for my $similar_product (@{ $item->{SimilarProducts}->{SimilarProduct} }) {
            # do we have any of these isbns in our collection?
            my $similar_biblionumbers = get_biblionumber_from_isbn($similar_product->{ASIN});
            # verify that there is at least one similar item
            if (scalar(@$similar_biblionumbers)){
                $similar_products_exist++ if ($similar_biblionumbers && $similar_biblionumbers->[0]);
                push @similar_products, +{ similar_biblionumbers => $similar_biblionumbers, title => $similar_product->{Title}, ASIN => $similar_product->{ASIN}  };
            }
        }
        $template->param( OPACAmazonSimilarItems => $similar_products_exist );
        $template->param( AMAZON_SIMILAR_PRODUCTS => \@similar_products );
    }
}

my $syndetics_elements;

if ( C4::Context->preference("SyndeticsEnabled") ) {
    $template->param("SyndeticsEnabled" => 1);
    $template->param("SyndeticsClientCode" => C4::Context->preference("SyndeticsClientCode"));
	eval {
	    $syndetics_elements = &get_syndetics_index($isbn,$upc,$oclc);
	    for my $element (values %$syndetics_elements) {
		$template->param("Syndetics$element"."Exists" => 1 );
		#warn "Exists: "."Syndetics$element"."Exists";
	}
    };
    warn $@ if $@;
}

if ( C4::Context->preference("SyndeticsEnabled")
        && C4::Context->preference("SyndeticsSummary")
        && ( exists($syndetics_elements->{'SUMMARY'}) || exists($syndetics_elements->{'AVSUMMARY'}) ) ) {
	eval {
	    my $syndetics_summary = &get_syndetics_summary($isbn,$upc,$oclc, $syndetics_elements);
	    $template->param( SYNDETICS_SUMMARY => $syndetics_summary );
	};
	warn $@ if $@;

}

if ( C4::Context->preference("SyndeticsEnabled")
        && C4::Context->preference("SyndeticsTOC")
        && exists($syndetics_elements->{'TOC'}) ) {
	eval {
    my $syndetics_toc = &get_syndetics_toc($isbn,$upc,$oclc);
    $template->param( SYNDETICS_TOC => $syndetics_toc );
	};
	warn $@ if $@;
}

if ( C4::Context->preference("SyndeticsEnabled")
    && C4::Context->preference("SyndeticsExcerpt")
    && exists($syndetics_elements->{'DBCHAPTER'}) ) {
    eval {
    my $syndetics_excerpt = &get_syndetics_excerpt($isbn,$upc,$oclc);
    $template->param( SYNDETICS_EXCERPT => $syndetics_excerpt );
    };
	warn $@ if $@;
}

if ( C4::Context->preference("SyndeticsEnabled")
    && C4::Context->preference("SyndeticsReviews")) {
    eval {
    my $syndetics_reviews = &get_syndetics_reviews($isbn,$upc,$oclc,$syndetics_elements);
    $template->param( SYNDETICS_REVIEWS => $syndetics_reviews );
    };
	warn $@ if $@;
}

if ( C4::Context->preference("SyndeticsEnabled")
    && C4::Context->preference("SyndeticsAuthorNotes")
	&& exists($syndetics_elements->{'ANOTES'}) ) {
    eval {
    my $syndetics_anotes = &get_syndetics_anotes($isbn,$upc,$oclc);
    $template->param( SYNDETICS_ANOTES => $syndetics_anotes );
    };
    warn $@ if $@;
}

# LibraryThingForLibraries ID Code and Tabbed View Option
if( C4::Context->preference('LibraryThingForLibrariesEnabled') ) 
{ 
$template->param(LibraryThingForLibrariesID =>
C4::Context->preference('LibraryThingForLibrariesID') ); 
$template->param(LibraryThingForLibrariesTabbedView =>
C4::Context->preference('LibraryThingForLibrariesTabbedView') );
} 


# Babelthèque
if ( C4::Context->preference("Babeltheque") ) {
    $template->param( 
        Babeltheque => 1,
    );
}

# Shelf Browser Stuff
if (C4::Context->preference("OPACShelfBrowser")) {
    # pick the first itemnumber unless one was selected by the user
    my $starting_itemnumber = $query->param('shelfbrowse_itemnumber'); # || $items[0]->{itemnumber};
    $template->param( OpenOPACShelfBrowser => 1) if $starting_itemnumber;
    # find the right cn_sort value for this item
    my ($starting_cn_sort, $starting_homebranch, $starting_location);
    my $sth_get_cn_sort = $dbh->prepare("SELECT cn_sort,homebranch,location from items where itemnumber=?");
    $sth_get_cn_sort->execute($starting_itemnumber);
    while (my $result = $sth_get_cn_sort->fetchrow_hashref()) {
        $starting_cn_sort = $result->{'cn_sort'};
        $starting_homebranch->{code} = $result->{'homebranch'};
        $starting_homebranch->{description} = $branches->{$result->{'homebranch'}}{branchname};
        $starting_location->{code} = $result->{'location'};
        $starting_location->{description} = GetAuthorisedValueDesc('','',   $result->{'location'} ,'','','LOC', 'opac');
    
    }
    
    ## List of Previous Items
    # order by cn_sort, which should include everything we need for ordering purposes (though not
    # for limits, those need to be handled separately
    my $sth_shelfbrowse_previous;
    if (defined $starting_location->{code}) {
      $sth_shelfbrowse_previous = $dbh->prepare("
        SELECT *
        FROM items
        WHERE
            ((cn_sort = ? AND itemnumber < ?) OR cn_sort < ?) AND
            homebranch = ? AND location = ?
        ORDER BY cn_sort DESC, itemnumber LIMIT 3
        ");
      $sth_shelfbrowse_previous->execute($starting_cn_sort, $starting_itemnumber, $starting_cn_sort, $starting_homebranch->{code}, $starting_location->{code});
    } else {
      $sth_shelfbrowse_previous = $dbh->prepare("
        SELECT *
        FROM items
        WHERE
            ((cn_sort = ? AND itemnumber < ?) OR cn_sort < ?) AND
            homebranch = ?
        ORDER BY cn_sort DESC, itemnumber LIMIT 3
        ");
      $sth_shelfbrowse_previous->execute($starting_cn_sort, $starting_itemnumber, $starting_cn_sort, $starting_homebranch->{code});
    }
    my @previous_items;
    while (my $this_item = $sth_shelfbrowse_previous->fetchrow_hashref()) {
        my $sth_get_biblio = $dbh->prepare("SELECT biblio.*,biblioitems.isbn AS isbn FROM biblio LEFT JOIN biblioitems ON biblio.biblionumber=biblioitems.biblionumber WHERE biblio.biblionumber=?");
        $sth_get_biblio->execute($this_item->{biblionumber});
        while (my $this_biblio = $sth_get_biblio->fetchrow_hashref()) {
			$this_item->{'title'} = $this_biblio->{'title'};
			my $this_record = GetMarcBiblio($this_biblio->{'biblionumber'});
			$this_item->{'browser_normalized_upc'} = GetNormalizedUPC($this_record,$marcflavour);
			$this_item->{'browser_normalized_oclc'} = GetNormalizedOCLCNumber($this_record,$marcflavour);
			$this_item->{'browser_normalized_isbn'} = GetNormalizedISBN(undef,$this_record,$marcflavour);
			my $t1 = GetMarcUrls    ($this_record,$marcflavour);
			my $val = $t1->[0]->{linktext};
			if($val eq "") {
				$this_item->{'image_path'} = &get_image_from_isbn($this_biblio->{'isbn'});
				}
			else {
				$this_item->{'image_path'} = &get_image_from_ebrary($this_biblio->{'biblionumber'});
				
				}
			
        }
        unshift @previous_items, $this_item;
    }
    
    ## List of Next Items; this also intentionally catches the current item
    my $sth_shelfbrowse_next;
    if (defined $starting_location->{code}) {
      $sth_shelfbrowse_next = $dbh->prepare("
        SELECT *
        FROM items
        WHERE
            ((cn_sort = ? AND itemnumber >= ?) OR cn_sort > ?) AND
            homebranch = ? AND location = ?
        ORDER BY cn_sort, itemnumber LIMIT 3
        ");
      $sth_shelfbrowse_next->execute($starting_cn_sort, $starting_itemnumber, $starting_cn_sort, $starting_homebranch->{code}, $starting_location->{code});
    } else {
      $sth_shelfbrowse_next = $dbh->prepare("
        SELECT *
        FROM items
        WHERE
            ((cn_sort = ? AND itemnumber >= ?) OR cn_sort > ?) AND
            homebranch = ?
        ORDER BY cn_sort, itemnumber LIMIT 3
        ");
      $sth_shelfbrowse_next->execute($starting_cn_sort, $starting_itemnumber, $starting_cn_sort, $starting_homebranch->{code});
    }
    my @next_items;
    while (my $this_item = $sth_shelfbrowse_next->fetchrow_hashref()) {
        my $sth_get_biblio = $dbh->prepare("SELECT biblio.*,biblioitems.isbn AS isbn FROM biblio LEFT JOIN biblioitems ON biblio.biblionumber=biblioitems.biblionumber WHERE biblio.biblionumber=?");
        $sth_get_biblio->execute($this_item->{biblionumber});
        while (my $this_biblio = $sth_get_biblio->fetchrow_hashref()) {
            $this_item->{'title'} = $this_biblio->{'title'};
			my $this_record = GetMarcBiblio($this_biblio->{'biblionumber'});
            $this_item->{'browser_normalized_upc'} = GetNormalizedUPC($this_record,$marcflavour);
            $this_item->{'browser_normalized_oclc'} = GetNormalizedOCLCNumber($this_record,$marcflavour);
            $this_item->{'browser_normalized_isbn'} = GetNormalizedISBN(undef,$this_record,$marcflavour);
            my $t1 = GetMarcUrls    ($this_record,$marcflavour);
			my $val = $t1->[0]->{linktext};
			if($val eq "") {
				$this_item->{'image_path'} = &get_image_from_isbn($this_biblio->{'isbn'});
				}
			else {
				$this_item->{'image_path'} = &get_image_from_ebrary($this_biblio->{'biblionumber'});
				
				}
        }
        push @next_items, $this_item;
    }
    
    # alas, these won't auto-vivify, see http://www.perlmonks.org/?node_id=508481
    my $shelfbrowser_next_itemnumber = $next_items[-1]->{itemnumber} if @next_items;
    my $shelfbrowser_next_biblionumber = $next_items[-1]->{biblionumber} if @next_items;
    
    $template->param(
        starting_homebranch => $starting_homebranch->{description},
        starting_location => $starting_location->{description},
        starting_itemnumber => $starting_itemnumber,
        shelfbrowser_prev_itemnumber => (@previous_items ? $previous_items[0]->{itemnumber} : 0),
        shelfbrowser_next_itemnumber => $shelfbrowser_next_itemnumber,
        shelfbrowser_prev_biblionumber => (@previous_items ? $previous_items[0]->{biblionumber} : 0),
        shelfbrowser_next_biblionumber => $shelfbrowser_next_biblionumber,
        PREVIOUS_SHELF_BROWSE => \@previous_items,
        NEXT_SHELF_BROWSE => \@next_items,
    );
}

if (C4::Context->preference("BakerTaylorEnabled")) {
	$template->param(
		BakerTaylorEnabled  => 1,
		BakerTaylorImageURL => &image_url(),
		BakerTaylorLinkURL  => &link_url(),
		BakerTaylorBookstoreURL => C4::Context->preference('BakerTaylorBookstoreURL'),
	);
	my ($bt_user, $bt_pass);
	if ($isbn and
		$bt_user = C4::Context->preference('BakerTaylorUsername') and
		$bt_pass = C4::Context->preference('BakerTaylorPassword')    )
	{
		$template->param(
		BakerTaylorContentURL   =>
		sprintf("http://contentcafe2.btol.com/ContentCafeClient/ContentCafe.aspx?UserID=%s&Password=%s&ItemKey=%s&Options=Y",
				$bt_user,$bt_pass,$isbn)
		);
	}
}

my $tag_quantity;
if (C4::Context->preference('TagsEnabled') and $tag_quantity = C4::Context->preference('TagsShowOnDetail')) {
	$template->param(
		TagsEnabled => 1,
		TagsShowOnDetail => $tag_quantity,
		TagsInputOnDetail => C4::Context->preference('TagsInputOnDetail')
	);
	$template->param(TagLoop => get_tags({biblionumber=>$biblionumber, approved=>1,
								'sort'=>'-weight', limit=>$tag_quantity}));
}

#Search for title in links
if (my $search_for_title = C4::Context->preference('OPACSearchForTitleIn')){
    $dat->{author} ? $search_for_title =~ s/{AUTHOR}/$dat->{author}/g : $search_for_title =~ s/{AUTHOR}//g;
    $dat->{title} =~ s/\/+$//; # remove trailing slash
    $dat->{title} =~ s/\s+$//; # remove trailing space
    $dat->{title} ? $search_for_title =~ s/{TITLE}/$dat->{title}/g : $search_for_title =~ s/{TITLE}//g;
    $isbn ? $search_for_title =~ s/{ISBN}/$isbn/g : $search_for_title =~ s/{ISBN}//g;
 $template->param('OPACSearchForTitleIn' => $search_for_title);
}

# We try to select the best default tab to show, according to what
# the user wants, and what's available for display
my $opac_serial_default = C4::Context->preference('opacSerialDefaultTab');
my $defaulttab = 
    $opac_serial_default eq 'subscriptions' && $subscriptionsnumber
        ? 'subscriptions' :
    $opac_serial_default eq 'serialcollection' && @serialcollections > 0
        ? 'serialcollection' :
    $opac_serial_default eq 'holdings' && $dat->{'count'} > 0
        ? 'holdings' :
    $subscriptionsnumber
        ? 'subscriptions' :
    @serialcollections > 0 
        ? 'serialcollection' : 'subscription';
$template->param('defaulttab' => $defaulttab);



my $show_visit_banner;
if($t_avl > 0) {
	$show_visit_banner =1;
}

$template->param( available_items => $t_avl,
					total_items	=> $t_total,
					show_visit_banner	=> $show_visit_banner );







output_html_with_http_headers $query, $cookie, $template->output;




sub get_search_vals {
	
	
my ($quan,$opp) = @_; 	
my @operators;
my @operands;


@operands = split("\0", @$quan); #	q parameter
my @indexes;
@indexes = split("\0",$opp); #idx parameter
my @limits;
@limits = split("\0",'branch:DL'); #limit parameter
my @sort_by;
$sort_by[0] = "popularity_dsc";
my $lang;


my $lang = C4::Output::getlanguagecookie($query);
my ( $error,$query1,$simple_query,$query_cgi,$query_desc,$limit,$limit_cgi,$limit_desc,$stopwords_removed,$query_type) = buildQuery(\@operators,\@operands,\@indexes,\@limits,\@sort_by, 0, $lang);


sub _input_cgi_parse ($) { 
    my @elements;
    for my $this_cgi ( split('&',shift) ) {
        next unless $this_cgi;
        $this_cgi =~ /(.*?)=(.*)/;
        push @elements, { input_name => $1, input_value => $2 };
    }
    return @elements;
}

## parse the query_cgi string and put it into a form suitable for <input>s
my @query_inputs = _input_cgi_parse($query_cgi);
$template->param ( QUERY_INPUTS => \@query_inputs );

## parse the limit_cgi string and put it into a form suitable for <input>s
my @limit_inputs = $limit_cgi ? _input_cgi_parse($limit_cgi) : ();

my $total = 0; # the total results for the whole set
my $facets; # this object stores the faceted results that display on the left-hand of the results page
my @results_array;
my $results_hashref;
my @coins;


# Use the servers defined, or just search our local catalog(default)
my @servers;

unless (@servers) {
    #FIXME: this should be handled using Context.pm
    @servers = ("biblioserver");
    # @servers = C4::Context->config("biblioserver");
}
my $results_per_page = C4::Context->preference('OPACnumSearchResults');

my $offset = 0;
my $page = $query->param('page') || 1;
$offset = ($page-1)*$results_per_page if $page>1;
my $hits;
my $expanded_facet = '';
my $scan = '';
my $flag;
#TODO working here
if (C4::Context->preference('NoZebra')) { 
	$flag = 1;
    eval {
        ($error, $results_hashref, $facets) = NZgetRecords($query1,$simple_query);
    };
} elsif ($build_grouped_results) { $flag = 2;
    eval {
        ($error, $results_hashref, $facets) = C4::Search::pazGetRecords($query1,$simple_query);
    };
} else { $flag = 3;
    eval {
        ($error, $results_hashref, $facets) = getRecords($query1,$simple_query,\@sort_by,\@servers,$results_per_page,$offset,$expanded_facet,$branches,$query_type,$scan);
    };
}

#Scanning the results from search server TODO search result scanning
my $server = $servers[0];
my @newresults;
    if ($results_hashref) { # this is the local bibliographic server
    
        $hits = $results_hashref->{$server}->{"hits"};
        my @records1 = $results_hashref->{$server}->{"RECORDS"}; 
      
      
        @newresults = searchResults('opac', $query_desc, $hits, $results_per_page, $offset, $scan,
                                        @{$results_hashref->{$server}->{"RECORDS"}}, C4::Context->preference('hidelostitems'));
	   
    }
	
	return @newresults;
}



# For getting related items by isbns

sub get_items_for_isbn {
	
my ($quan,$opp,$ib) = @_; 	
my @operators;
my @operands;


@operands = split("\0", @$quan); #	q parameter
my @indexes;
@indexes = split("\0",$opp); #idx parameter
my @limits;
@limits = split("\0",''); #limit parameter
my @sort_by;
$sort_by[0] = "popularity_dsc";
my $lang;


my $lang = C4::Output::getlanguagecookie($query);
my ( $error,$query1,$simple_query,$query_cgi,$query_desc,$limit,$limit_cgi,$limit_desc,$stopwords_removed,$query_type) = buildQuery(\@operators,\@operands,\@indexes,\@limits,\@sort_by, 0, $lang);


$query1 = "(rk=(Title-cover,ext,r1=\"$ib\" or ti,ext,r2=\"$ib\" or ti,phr,r3=\"$ib\" or wrdl,fuzzy,r8=\"$ib\" or wrdl,right-Truncation,r9=\"$ib\" or wrdl,r9=\"$ib\"))";

sub _input_cgi_parse ($) { 
    my @elements;
    for my $this_cgi ( split('&',shift) ) {
        next unless $this_cgi;
        $this_cgi =~ /(.*?)=(.*)/;
        push @elements, { input_name => $1, input_value => $2 };
    }
    return @elements;
}

## parse the query_cgi string and put it into a form suitable for <input>s
my @query_inputs = _input_cgi_parse($query_cgi);
$template->param ( QUERY_INPUTS => \@query_inputs );

## parse the limit_cgi string and put it into a form suitable for <input>s
my @limit_inputs = $limit_cgi ? _input_cgi_parse($limit_cgi) : ();

my $total = 0; # the total results for the whole set
my $facets; # this object stores the faceted results that display on the left-hand of the results page
my @results_array;
my $results_hashref;
my @coins;


# Use the servers defined, or just search our local catalog(default)
my @servers;

unless (@servers) {
    #FIXME: this should be handled using Context.pm
    @servers = ("biblioserver");
    # @servers = C4::Context->config("biblioserver");
}
my $results_per_page = C4::Context->preference('OPACnumSearchResults');

my $offset = 0;
my $page = $query->param('page') || 1;
$offset = ($page-1)*$results_per_page if $page>1;
my $hits;
my $expanded_facet = '';
my $scan = '';
my $flag;
#TODO working here
if (C4::Context->preference('NoZebra')) { 
	$flag = 1;
    eval {
        ($error, $results_hashref, $facets) = NZgetRecords($query1,$simple_query);
    };
} elsif ($build_grouped_results) { $flag = 2;
    eval {
        ($error, $results_hashref, $facets) = C4::Search::pazGetRecords($query1,$simple_query);
    };
} else { $flag = 3;
    eval {
        ($error, $results_hashref, $facets) = getRecords($query1,$simple_query,\@sort_by,\@servers,$results_per_page,$offset,$expanded_facet,$branches,$query_type,$scan);
    };
}

#Scanning the results from search server TODO search result scanning
my $server = $servers[0];
my @newresults;
    if ($results_hashref) { # this is the local bibliographic server
    
        $hits = $results_hashref->{$server}->{"hits"};
        my @records1 = $results_hashref->{$server}->{"RECORDS"}; 
      
      
        @newresults = searchResults('opac', $query_desc, $hits, $results_per_page, $offset, $scan,
                                        @{$results_hashref->{$server}->{"RECORDS"}},, C4::Context->preference('hidelostitems'));
	   
    }
	
	return @newresults;
	
	
}



# Method for checking if a user has permission to view ebrary book 
# or not, same as get_status_for_addon in opac-user.pl
# TODO We'll move it to Members.pm , so that the code is not repeated
# in both the scripts

sub get_status_for_ebrary {


my $borrowernumber=shift;
my $type=shift;
my $dateexpiry1 = shift;
my $category=shift;
my $t1;

if($type eq 'EBRARY') {
	$t1 = "EBRA";
}


my $sth = C4::Context->dbh->prepare("select maxissueqty from issuingrules where categorycode = '$category' and itemtype='$t1' and maxissueqty > 0");
$sth->execute();                                                                                                                                     
my $test = $sth->fetchrow();  


my $sth1 = C4::Context->dbh->prepare("select count(*) from addons where borrowernumber=? and type='$type' ");
$sth1->execute($borrowernumber);                                                                                                                                     
my $test2 = $sth1->fetchrow(); 

my $sth2 = C4::Context->dbh->prepare("select dateexpiry from addons where borrowernumber=? and type=? ");
$sth2->execute($borrowernumber,$type);
my $subexpiry = $sth2->fetchrow();

my $mem_sub_exp=0;
my $sub_exp=0;
my $proceed = 0;
my $mem_exp=0;
my $today = C4::Dates->new()->output("iso");

my $dateexpiry = join("-" => reverse split(m[/], $dateexpiry1)); # Conversion, because all dates should be in same format yyyy-mm-dd

#if((($dateexpiry ge $today) and ($subexpiry ge $today)) or ($test > 0)) {
#	$proceed = 1
#} 


my $flag;

if(($subexpiry le $today) and ($dateexpiry le $today) and (defined $subexpiry)) # if sub is defined and both dates are expiry
{
	$flag ="Mem and Sub both exp";
}
else
{
	if(($subexpiry le $today) and (defined $subexpiry)) # If sub is defined and expired
		{
			$flag ="Sub exp";
		}
	elsif($dateexpiry le $today) # If membership has expired
		{
			$flag ="Mem exp";
		}
	else
		{
			if($test > 0 or $test2 > 0) { # Check for validity of addon and membership
			$proceed=1;
			}
			else {
				$flag = "both test invalid";
			}
		}
}

return $proceed;
	
}


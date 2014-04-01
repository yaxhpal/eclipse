package C4::Nielsen;

# Copyright 2014 Britsh Council
#
# The United Kingdom's international organisation for cultural relations and
# educational opportunities.
#
# A registered charity: 209131 (England and Wales) SCO37733 (Scotland)
#
# This module provides functionality to apply promotional coupons to various
# patron transactions such as registration etc.

use strict;
use warnings;
use C4::Context;
use C4::Charset;
use Data::Dumper;
use MIME::Base64;
use MARC::File::USMARC;
use MARC::File::XML;
use MARC::Record;
use Business::ISBN;
use LWP::UserAgent ();
use XML::Simple ('XMLin');
use Date::Simple ('date', 'today');

use C4::SQLHelper qw(SearchInTable InsertInTable UpdateInTable  GetRecordCount);

use vars qw(%book $IMAGE_ROOT $STATIC_URL $IMAGE_EXT $NO_IMAGE_NAME $VERSION @ISA @EXPORT);

BEGIN {
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(getItemDetails);
  }
open(LOG_FILE, ">>/home/yashpal/nielsen.log") or die $!; 
$IMAGE_EXT 		= '.jpeg';
$NO_IMAGE_NAME 	= 'noimage.jpg';
$STATIC_URL 	= C4::Context->get_custom_config("static_url");
$IMAGE_ROOT		= C4::Context->get_custom_config("image_save_location");
%book    = ('id'			  => undef,
			'isbn10'          => undef,
			'isbn13'          => undef,
			'vendor_id'       => undef,
			'type'            => undef,
			'title'           => undef,
			'author'          => undef,
			'publisher'       => undef,
			'description'     => undef,
			'date_published'  => undef,
			'copyright_year'  => undef,
			'subject'		  => undef,
			'product_format'  => undef,
			'thumbnail_url'   => undef,
			'image_url'       => undef,
			'edition'         => undef,
			'number_of_pages' => undef,
			'imageflag'		  => undef,
			'timestamp'		  => undef,
			);
			
# Test Code Starts ###############################################
&testIt();
##
##
sub testIt (){
##	getItemDetails('9780194422703');
##	$book{'thumbnail_url'}	= undef;
##	$book{'image_url'} 		= undef;
##	getItemDetails('9781860498824');
##	getItemDetails('9780194422703');
##	getItemDetails('9781860498824');
##	getItemDetails('9780297852735');
#	getItemDetails('0750644710')
# open (MYFILE, '/home/yashpal/projects/nielsen/samplemarcs/sample.mrc');
# my $marcblob;
# while (<MYFILE>) {
# 	chomp;
# 	$marcblob.=$_;
# }
# print Dumper $marcblob;
# my ($marc_record, $charset_guessed, $char_errors) = MarcToUTF8Record($marcblob, C4::Context->preference("marcflavour"));
# print(Dumper($marc_record->as_xml()));
# close (MYFILE);          
 getNielsenMarc21('9780194422703');

}
# Test Code Ends #################################################

sub getItemDetails {
	my ($isbn) = shift;
	print(LOG_FILE $isbn."\n");
	croak($isbn." is not a valid ISBN.\n") unless (Business::ISBN->new($isbn)->is_valid());
	my $mybook = checkNielsenCache($isbn);
	if ($mybook) {
		return $mybook if ($mybook->{'title'});
#		print(LOG_FILE Dumper($mybook));
		my $lastFetchDate = Date::Simple->new(substr($mybook->{'timestamp'}, 0, 10));
		my $today     	  = Date::Simple->today();
		if ($lastFetchDate < $today) {
			$mybook = fetchDataFromNielsen($isbn, $mybook->{'id'});
		}
	} else {
		$mybook = fetchDataFromNielsen($isbn, undef);
	}
	return $mybook;	
}

sub checkNielsenCache($) {
	my ($isbn13, $result);
	$isbn13  = Business::ISBN->new(shift)->as_isbn13();
	$result =  SearchInTable('externaldata', {'isbn13' => $isbn13->isbn(), 'vendor_id'=>'NIELSEN'}, undef, undef, undef, undef, "exact")->[0];
	return $result unless ($result);
	if ($result->{'imageflag'} eq '1') {
		$result->{'thumbnail_url'}	= $STATIC_URL.$isbn13->isbn().$IMAGE_EXT;
		$result->{'image_url'} 		= $STATIC_URL.$isbn13->isbn().$IMAGE_EXT;
	} elsif ($result->{'imageflag'} eq '2') {
		$result->{'thumbnail_url'}	= $STATIC_URL.$NO_IMAGE_NAME;
		$result->{'image_url'} 		= $STATIC_URL.$NO_IMAGE_NAME;	
	}
	return $result;
}

sub cacheNielsenData {
	return InsertInTable ('externaldata',\%book, undef);
}

sub fetchDataFromNielsen() {
	my ($isbntext, $cacheId) = @_;
	my ($isbnobj, $isbn10, $isbn13, $resourceUrl, $bookinfo, $imageflag);
	my ($image, $image_file_name, $outfile, $flag);
	$isbnobj = Business::ISBN->new($isbntext); 
	getNielsenInfo($isbnobj->isbn());
	
	$image_file_name  = $isbnobj->as_isbn13()->isbn().$IMAGE_EXT;
	unless (-e $IMAGE_ROOT.$image_file_name) {
		$image = getNielsenImage($isbnobj->isbn()) if($book{'imageflag'} eq '1');
		if ($image) {
			open($outfile, '>', $IMAGE_ROOT.$image_file_name) or croak $!;
			binmode ($outfile);
			print {$outfile} decode_base64($image);
			close $outfile;
			$book{'imageflag'} 	= '1';
		} else {
			$image_file_name  = $NO_IMAGE_NAME;
			$book{'imageflag'} 	= '2';
		}
	}
	if ($cacheId) {
		$book{'id'} = $cacheId;
		UpdateInTable('externaldata', \%book);
	} else {
		InsertInTable ('externaldata',\%book, undef);
	}
	$book{'thumbnail_url'}	= $STATIC_URL.$image_file_name;
	$book{'image_url'} 		= $STATIC_URL.$image_file_name;
	return \%book;
}

sub getNielsenInfo {
	my ($isbnText) = shift;
	my ($resourceUrl, $bookinfo, @authors, $authorscnt);
	my $isbn 	 = Business::ISBN->new($isbnText);
	$resourceUrl = getNielsenAPIUrl($isbn->isbn(), 'info');
	$bookinfo    = parseNielsenXML(get($resourceUrl), 'info');
	print(LOG_FILE Dumper($bookinfo));
	$book{'isbn10'} 			= $isbn->as_isbn10()->isbn();
	$book{'isbn13'} 			= $isbn->as_isbn13()->isbn();
	$book{'vendor_id'} 			= 'NIELSEN';
	$book{'type'} 				= 'BOOK';
	$book{'title'} 				= $bookinfo->{'TL'};
	$book{'publisher'} 			= $bookinfo->{'IMPN'};
	$book{'date_published'}		= getPublicationDate($bookinfo->{'PUBPD'});
	$book{'subject'} 			= $bookinfo->{'BIC2ST1'};
	$book{'number_of_pages'} 	= $bookinfo->{'PAGNUM'};
	$book{'imageflag'} 			= ($bookinfo->{'IMAGFLAG'} eq 'Y')? '1':'2';
	$book{'edition'} 			= $bookinfo->{'EDSL'};
	$authorscnt = 1;
	while ($bookinfo->{'CNF'."$authorscnt"}) {
		push(@authors, $bookinfo->{'CNF'."$authorscnt"});
		$authorscnt++;
	}
	$book{'author'} 			= join(', ', @authors);

	if (defined($bookinfo->{'NBDSD'}) && $bookinfo->{'NBDSD'} ne '') {
		unless($book{'description'} = $bookinfo->{'NBDSD'}) {
			$book{'description'} = 'No Description Available!';
		}
	} else {
		unless($book{'description'} = $bookinfo->{'CIS'}) {
			$book{'description'} = 'No Description Available!';
		}
	}
}


sub getNielsenMarc21 {
#	print "Into getNielsenMarc21 \n";
	my ($isbnText) = shift;
	my ($resourceUrl, $nielsenresponse, $base64marc, $bookmarc, @authors, $authorscnt, $marcBlob);
	my $isbn 	 = Business::ISBN->new($isbnText);
	$resourceUrl = getNielsenAPIUrl($isbn->isbn(), 'marc21');
	$nielsenresponse = get($resourceUrl);
	if ($nielsenresponse =~ /\<resultCode\>00\<\/resultCode\>/) {
		$base64marc = parseNielsenXML($nielsenresponse, 'marc21');
		if ($base64marc) {
			$marcBlob = decode_base64($base64marc);
			my ($marc_record, $charset_guessed, $char_errors) = MarcToUTF8Record($marcBlob, 'MARC21');
#			print(Dumper($marc_record->as_xml()));
		}
	} else {
		return undef;
	}
#	print(Dumper($base64marc));
}

sub getNielsenImage {
	my ($isbnText) = shift;
	my ($resourceUrl, $image);
	my $isbn 	 = Business::ISBN->new($isbnText);
	$resourceUrl = getNielsenAPIUrl($isbn->isbn(), 'image');
	$image	     = parseNielsenXML(get($resourceUrl), 'image');
	return $image;
}

sub getNielsenAPIUrl {
	my ($isbn, $dataType)  = @_;
	my ($host, $path, %queryParams, $queryString);
	$host ='http://ws.nielsenbookdataonline.com';
	$path ='/BDOLRest/RESTwebServices/BDOLrequest'; 
	%queryParams	 = (
					    'clientId'   => 'BcouncildelhiBDWS01',
						'password'   => 'kcl510dk4873',
						'format'     => '7',
						'from'       => '0',
						'to'         => '1',
						'resultView' => '2',
						'value0'     => $isbn,
						'logic0'     => '0',
						'sortField0' => '0',
						'field0'	 => '0',
						'indexType'  => '0',
						
	);
	if (uc($dataType) eq 'INFO') {
		$queryParams{'indexType'} = '0';
	} elsif (uc($dataType) eq 'MARC21') {
		$queryParams{'format'} = '5';
		$queryParams{'indexType'} = '0';
	} elsif (uc($dataType) eq 'IMAGE') {
		$queryParams{'field0'} = '1';
		$queryParams{'indexType'} = '2';
	} else {
		warn("Requested URL can not be obtained. 
		      Argument should be either INFO or 
		      IMAGE to this routine");
		      return undef;	
	}
	foreach my $key ( keys %queryParams ) {
		$queryString .= $key.'='.$queryParams{$key}.'&';
	}
	return $host . $path . '?' . $queryString; 
}

sub parseNielsenXML {
	my ($xml, $dataType) = @_;
	my $bookxml;
	$xml = '<data></data>' unless(defined($xml));
	$xml  =~ s/\<\?xml.*?\?\>//g; # Remove XML declaration if there is one
	if (uc($dataType) eq 'INFO') {
		$bookxml = XMLin($xml)->{'data'}->{'data'}->{'record'};
	} elsif (uc($dataType) eq 'IMAGE') {
		$bookxml = XMLin($xml)->{'data'};
	} elsif (uc($dataType) eq 'MARC21') {
		$bookxml = XMLin($xml)->{'data'};
	} else {
		warn("Requested URL can not be obtained. 
		      Argument should be either INFO or 
		      IMAGE to this routine");
		      return undef;	
	}
	if ($bookxml && (ref($bookxml) eq 'ARRAY')) {
			$bookxml = $bookxml->[0];
	}
	return $bookxml;
}

sub get ($) {
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
 	my $response = $ua->get(shift);
    return $response->decoded_content if $response->is_success;
    return undef;
}
 
sub getPublicationDate {
	my  $pubDate = shift;
	if ($pubDate) {
		my $year  = substr($pubDate, 0, 4);
		my $month = substr($pubDate, 4, 2);
		my $day   = substr($pubDate, 6, 2);
		$pubDate =  $year.'-'.$month.'-'.(($day eq '00')?'01':$day);
	}
	return $pubDate;
} 
 
END { 
	
	close(LOG_FILE);
}    # module clean-up code here (global destructor)

1;

__END__

=head1 AUTHORS

Techletsolutions Team

=cut
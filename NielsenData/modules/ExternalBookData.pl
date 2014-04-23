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
use LWP::Simple ('get');
use XML::Simple ('XMLin');
use Business::ISBN;
use DBI;
use JSON::XS;
use Data::Dumper;

my $dbh = DBI->connect("dbi:mysql:dbname=test","root","", { RaiseError => 1 },) or die $DBI::errstr;

my %book = ('isbn10'          => '',
			'isbn13'          => '',
			'vendor_id'       => '',
			'type'            => '',
			'title'           => '',
			'author'          => '',
			'publisher'       => '',
			'description'     => '',
			'date_published'  => '',
			'copyright_year'  => '',
			'subject'         => '',
			'thumbnail_url'   => '',
			'image_url'       => '',
			'edition'         => '',
			'number_of_pages' => '',
			'imageflag'		  => '');
	
#&fetchDataFromGoogle('9781860498824');

#  my $ary_ref = $dbh->selectcol_arrayref("SELECT column_name FROM information_schema.columns WHERE table_name = 'externaldata'");
#  my @columns = @{$ary_ref}; 
#  print(Dumper(@columns));
#  my %bookHash = %{&fetchDataFromNielsen('9781860498824')};
#  my $query = "INSERT INTO externaldata SET ";
#  my @bind  = ();
#  foreach (@columns){
#     $query .= "$_ = ?,";
#     push(@bind, $bookHash{$_});
#  }
#  $query =~ s/\,$//;
#  my $sth = $dbh->prepare($query);
#  $sth->execute(@bind);
#  $sth->finish();
#  $dbh->disconnect();

 #$sth->finish();
 #&fetchData('1860498825');
 #&fetchData('9780194422703');
 #&fetchData('9781860498824');

print Dumper &fetchDataFromNielsen('9789812751348');

sub fetchDataFromNielsen() {
	my $isbn = Business::ISBN->new(shift); 
	my ($isbn10, $isbn13, $resourceUrl, $bookinfo);
	unless ($isbn->is_valid()) {
	  croak($isbn." is not a valid ISBN.");
	  return;	
	}
	getNielsenInfo($isbn->isbn());
	
	if ($book{'imageflag'} eq 'Y') {
	 	print Dumper getNielsenImage($isbn->isbn());	
	}
	return \%book;
}

sub getNielsenAPIUrl {
	my ($isbn, $dataType)  = @_;
	my ($host, $path, %queryParams, $queryString);
	$host ='http://ws.nielsenbookdataonline.com';
	$path ='/BDOLRest/RESTwebServices/BDOLrequest'; 
	%queryParams = (
					    'clientId'   => 'BcouncildelhiBDWS01',
						'password'   => 'kcl510dk4873',
						'format'     => '7',
						'from'       => '0',
						'to'         => '10',
						'resultView' => '2',
						'field0'     => '0',
						'value0'     => $isbn,
						'logic0'     => '0',
						'sortField0' => '0'
	);
	if (uc($dataType) eq 'INFO') {
		$queryParams{'indexType'} = '0';
	}  elsif (uc($dataType) eq 'IMAGE') {
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
	# Remove XML declaration if there is one
	$xml  =~ s/\<\?xml.*?\?\>//g;
	if (uc($dataType) eq 'INFO') {
		$bookxml = XMLin($xml)->{'data'}->{'data'}->{'record'};
	}  elsif (uc($dataType) eq 'IMAGE') {
		$bookxml = XMLin($xml)->{'data'};
	} else {
		warn("Requested URL can not be obtained. 
		      Argument should be either INFO or 
		      IMAGE to this routine");
		      return undef;	
	}
	return $bookxml;
}

sub getNielsenInfo {
	my ($isbnText) = shift;
	my ($resourceUrl, $bookinfo);
	my $isbn 	 = Business::ISBN->new($isbnText);
	$resourceUrl = getNielsenAPIUrl($isbn->isbn(), 'info');
	$bookinfo    = parseNielsenXML(get($resourceUrl), 'info');
	$book{'isbn10'} 			= $isbn->as_isbn10()->isbn();
	$book{'isbn13'} 			= $isbn->as_isbn13()->isbn();
	$book{'vendor_id'} 			= 'NIELSEN';
	$book{'type'} 				= 'BOOK';
	$book{'title'} 				= $bookinfo->{TL};
	$book{'author'} 			= $bookinfo->{CNF1};
	$book{'publisher'} 			= $bookinfo->{IMPN};
	$book{'date_published'} 	= $bookinfo->{PUBPD};
	$book{'subject'} 			= $bookinfo->{BIC2ST1};
	$book{'number_of_pages'} 	= $bookinfo->{PAGNUM};
	$book{'imageflag'} 			= $bookinfo->{IMAGFLAG};
	$book{'edition'} 			= '';
	if (defined($bookinfo->{NBDSD}) && $bookinfo->{NBDSD} ne "") {
		$book{'description'} = $bookinfo->{NBDSD};
	} else {
		$book{'description'} = $bookinfo->{CIS};
	}
}

sub getNielsenImage {
	my ($isbnText) = shift;
	my ($resourceUrl, $image);
	my $isbn 	 = Business::ISBN->new($isbnText);
	$resourceUrl = getNielsenAPIUrl($isbn->isbn(), 'image');
	$image	     = parseNielsenXML(get($resourceUrl), 'image');
	return $image;
}


sub fetchDataFromGoogle() {
	my ($isbn, $isbn10, $isbn13, $host, $path, %queryParams, 
		$queryString, $resourceUrl, $bookinfo);

	$isbn = Business::ISBN->new(shift);
	unless ($isbn->is_valid()) {
	  croak($isbn." is not a valid ISBN.");
	  return;	
	}
	$host ='https://www.googleapis.com';
	$path ='/books/v1/volumes';
	$queryString = 'q=isbn:'.$isbn->isbn().'&projection=full&orderBy=relevance';
	$resourceUrl = $host . $path . '?' . $queryString;
	print $resourceUrl;
	my $response = LWP::Simple::get($resourceUrl);
	my $myjson = JSON::XS->new();
	my $dataHash = $myjson->utf8->decode ($response);
	my $infoLink = $dataHash->{'items'}[0]->{'selfLink'};
	$response = LWP::Simple::get($infoLink);
	# print(Dumper($response));
	$bookinfo = $myjson->utf8->decode($response)->{'volumeInfo'};
	print(Dumper($bookinfo));
	# $dataHash->{'items'}[0]->{'volumeInfo'};
	
	$book{'isbn10'} = $isbn->as_isbn10()->isbn();
	$book{'isbn13'} = $isbn->as_isbn13()->isbn();
	$book{'vendor_id'} = 'GOOGLE';
	$book{'type'} = $bookinfo->{printType};
	$book{'title'} = $bookinfo->{title};
	#$book{'author'} = join(",", $bookinfo->{authors});
	$book{'publisher'} = $bookinfo->{publisher};
	$book{'description'} = $bookinfo->{description};
	$book{'date_published'} = $bookinfo->{publishedDate};
	$book{'subject'} = $bookinfo->{BIC2ST1};
	$book{'thumbnail_url'} = $bookinfo->{imageLinks}->{thumbnail};
	$book{'image_url'} = '';
	$book{'edition'} = '';
	$book{'number_of_pages'} =$bookinfo->{pageCount};
	
	print Dumper %book;
	
}
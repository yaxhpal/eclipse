#!/usr/bin/perl

use strict;
use warnings;
use REST::Client;
use JSON::Parse 'parse_json';
use Data::Dumper;

 #The basic use case
 my $client = REST::Client->new();
 $client->setTimeout(10);
 $client->GET('https://www.googleapis.com/books/v1/volumes?q=isbn:1860498825');
 my $json = $client->responseContent();
 my $perl = parse_json ($json);
 print Dumper($perl);
 
  
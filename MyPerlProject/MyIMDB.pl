use IMDB::Film;
use Data::Dumper;

# Title
# Director
# Year
# Length
# Language
# Url
# Category
# Description
# Rating
# Cast or Actors
# Video Format
my $imdbObj = new IMDB::Film( crit => 'Troy' );
if ( $imdbObj->status ) {

	#	print( Dumper($imdbObj) );
	my @arr = $imdbObj->matched();

	#	print "Key: $_ and Value: $hash{$_}\n" foreach (keys%hash);
	print join( ", ", @arr ) . "\n";
	print Dumper(@arr);
	print @arr;
	
	foreach my $h (@arr) {
		foreach my $t (@{$h}) {
			print Dumper($t), "\n";
		}
	}

   #	print "title: " . $imdbObj->title() . "\n";
   #	print "kind: " . $imdbObj->kind() . "\n";
   #	print "year: " . $imdbObj->year() . "\n";
   #	print "episodes: " . $imdbObj->episodes() . "\n";
   #	print "episodeof: " . $imdbObj->episodeof() . "\n";
   #	print "summary: " . $imdbObj->summary() . "\n";
   #	print "cast: " .join(", ",@{$imdbObj->cast()}) . "\n";
   #	print "directors: " . join(", ",@{$imdbObj->directors()}) . "\n";
   #	print "writers: " . $imdbObj->writers() . "\n";
   #	print "cover: " . $imdbObj->cover() . "\n";
   #	print "language: " . $imdbObj->language() . "\n";
   #	print "country: " . $imdbObj->country() . "\n";
   #	print "top_info: " . $imdbObj->top_info() . "\n";
   #	print "rating: " . $imdbObj->rating() . "\n";
   #	print "genres: " . $imdbObj->genres() . "\n";
   #	print "tagline: " . $imdbObj->tagline() . "\n";
   #	print "plot: " . $imdbObj->plot() . "\n";
   #	print "also_known_as: " . $imdbObj->also_known_as() . "\n";
   #	print "certifications: " . $imdbObj->certifications() . "\n";
   #	print "duration: " . $imdbObj->duration() . "\n";
   #	print "full_plot: " . $imdbObj->full_plot() . "\n";
   #	print "trivia: " . $imdbObj->trivia() . "\n";
   #	print "goofs: " . $imdbObj->goofs() . "\n";
   #	print "awards: " . $imdbObj->awards() . "\n";
   #	print "official_sites: " . $imdbObj->official_sites() . "\n";
   #	print "release_dates: " . $imdbObj->release_dates() . "\n";
   #	print "aspect_ratio: " . $imdbObj->aspect_ratio() . "\n";
   #	print "mpaa_info: " . $imdbObj->mpaa_info() . "\n";
   #	print "company: " . $imdbObj->company() . "\n";
   #	print "connections: " . $imdbObj->connections() . "\n";
   #	print "full_companies: " . $imdbObj->full_companies() . "\n";
   #	print "recommendation_movies: " . $imdbObj->recommendation_movies() . "\n";
   #	print "plot_keywords: " . $imdbObj->plot_keywords() . "\n";
   #	#print "big_cover_url: " . $imdbObj->big_cover_url() . "\n";
   #	#print "big_cover_page: " . $imdbObj->big_cover_page() . "\n";
   #	print "storyline: " . $imdbObj->storyline() . "\n";
   #	print "full_plot_url: " . $imdbObj->full_plot_url() . "\n";
} else {
	print "Something wrong: " . $imdbObj->error;
}

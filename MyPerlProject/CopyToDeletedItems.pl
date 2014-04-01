use DBI;
$dbh = DBI->connect( 'dbi:mysql:koha', 'kohaadmin', 'pkoha' ) or die "Connection Error: $DBI::errstr\n";


$sql = "select * from items limit 10";
$sth = $dbh->prepare($sql);
$sth->execute();
my $data = $sth->fetchrow_hashref();
my $query = "INSERT INTO deleteditems SET ";
my @bind  = ();
foreach my $key ( keys %$data ) {
	if (undef($data->{$key})) {
		$query .= "$key = NULL,";
	} else {
		$query .= "$key = $data->{$key},";
	}
}
print $query;

#$sth->execute or die "SQL Error: $DBI::errstr\n";
#while ( @row = $sth->fetchrow_array ) {
#	print "@row\n";
#}

 # Functional style
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);


my $digest = Digest::SHA1->new()->sha1_base64('10234');

print($digest);

print($digest->sha1_transform());


  use Crypt::Blowfish;
  my $cipher = new Crypt::Blowfish 'BritishCouncil'; 
  
   
  my $ciphertext = $cipher->encrypt('01023456');
  
#  print $ciphertext, "\n";
  
  my $plaintext  = $cipher->decrypt($ciphertext);

#  print $plaintext, "\n";
#  my $s = '4353';
#  my $pad_string = '#' x (8 - length $s);
#  print $pad_string.$s;
  
  
  my $crypted = &myciper('2433');
  print "Crypted: ", $crypted, "\n";
  my $plain   = &mydecipher($crypted);
  print "Simple: ", $plain, "\n";
  
sub myciper() {
	my $registrationNumber = shift;
	if (length($registrationNumber) < 8 ) {
	 return($cipher->encrypt(('X' x (8 - length($registrationNumber))).$registrationNumber));
	}
	return($cipher->encrypt());
}

sub mydecipher() {
	my $ciphertext = shift;
	my $plaintext = $cipher->decrypt($ciphertext);
	$plaintext =~ s/X?//g;
	return($plaintext);
}
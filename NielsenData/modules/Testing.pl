use Crypt::Tea;
my $string = '10653';
my $key = 'D8531C50-9F1F-11E3-ACA5-80573B4B24D';
 
# Print Original String
#print $string."\n";
 
# Encrypt the string using my key
#$user = encrypt($string,$key);
 
# Print Encrypted String
#print $user."\n";
 
# Decrypt the string
#$user = decrypt('kZnGtdbHToM',$key);
# print $user."\n";
#$user = decrypt('1Wajm9ob0ns',$key);
# print $user."\n";
#$user = decrypt('r9EivGoUxVU',$key);
# print $user."\n";
#$user = decrypt('hvenXCZ6bPs',$key);
# 
# 
## Print back Original String
#print $user."\n";


my $str = '<Result><clientId>BcouncildelhiBDWS01</clientId><format>5</format><resultCode>00</resultCode><hits>1</hits><from>0</from><to>1</to><data>';

if ($str =~ /\<resultCode\>00\<\/resultCode\>/) {
	print 'Hurray'."\n";
} else {
	print 'Alas'."\n";
}

# kZnGtdbHToM     1Wajm9ob0ns      r9EivGoUxVU   hvenXCZ6bPs
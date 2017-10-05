use LWP::UserAgent;
use HTTP::Cookies;

use JSON;

use constant {
  GET=>'GET',
  POST=>'POST',
  DELETE=>'DELETE',
};

open(my $systems, '<', 'rp-systems.config') or die "Could not open rp-systems.config\n";

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0; 

while (<$systems>) {
  $line = $_;
  if($line =~ /^#.*/) {
                                                                ;
  } else {
	# do stuff;
	$line =~ /(.*),(.*),(.*)\s*#*/;
	my $host = $1;
	my $user = $2;
	my $pass = $3;
	
													  
	my $ua = LWP::UserAgent->new( ssl_opts => {SSL_verify_mode => 'SSL_VERIFY_NONE'}, cookie_jar => {} );
	my $json = JSON->new->allow_nonref();
	my $req = HTTP::Request->new;
	
	$req->uri('https://'.$host.'/fapi/rest/4_4/groups');
	$req->method('GET');
	$req->header('content-type' =>'application/json');
	$req->header('accept' =>'application/json');
																													
	$req->authorization_basic($user,$pass);
					
	my $response = $ua->request($req);
	if($response->is_success) {
	  $message = $response->decoded_content;
	  $groups = $json->decode($message);
	  $i = 0;
	  
	  while($groups->{'innerSet'}->[$i]->{'id'}) {
		$id = $groups->{'innerSet'}->[$i]->{'id'};
		my $req = HTTP::Request->new;
		$req->uri('https://'.$host.'/fapi/rest/4_4/groups/'.$id.'/policy');
		$req->method('GET');
		$req->header('content-type' =>'application/json');
		$req->header('accept' =>'application/json');
		$req->authorization_basic($user,$pass);
		my $response = $ua->request($req);
		if($response->is_success) {
			$message = $response->decoded_content;
			$grouppolicy = $json->decode($message);
			$groupname = $grouppolicy->{'groupName'};
			#print "Found group $name\n";
			$j=0;
			while($grouppolicy->{'copiesPolicies'}->[$j]) { # loop through copies
				$copyname = $grouppolicy->{'copiesPolicies'}->[$j]->{'copyName'};
				$reqwindow = $grouppolicy->{'copiesPolicies'}->[$j]->{'copyPolicy'}->{'requiredProtectionWindowInMicroSeconds'};
				$clusteruid = $grouppolicy->{'copiesPolicies'}->[$j]->{'copyUID'}->{'globalCopyUID'}->{'clusterUID'}->{'id'};
				$copyuid = $grouppolicy->{'copiesPolicies'}->[$j]->{'copyUID'}->{'globalCopyUID'}->{'copyUID'};
				$groupuid = $grouppolicy->{'copiesPolicies'}->[$j]->{'copyUID'}->{'groupUID'}->{'id'};
				#print "CG $name has copy $copyname with required window $reqwindow\n";
				#print "That copy has groupUID $groupuid clusteruid $clusteruid copyuid $copyuid\n";
				
				$mycopyuid = $clusteruid . $copyuid . $groupuid;
				#print "Generated copy uid is $mycopyuid\n";
				$groupData->{$host}->{$mycopyuid}->{'copyName'} = $copyname;
				$groupData->{$host}->{$mycopyuid}->{'reqWindow'} = $reqwindow;
				$groupData->{$host}->{$mycopyuid}->{'cluster'} = $host;
				$groupData->{$host}->{$mycopyuid}->{'groupName'} = $groupname;
				$j++;
			} # end while we have a copy with policies
		} else {
			print "HTTP error message" . $response->message() . "\n";
		} 
		$i++;
	  }
	  
	my $req = HTTP::Request->new;
	
	$req->uri('https://'.$host.'/fapi/rest/4_4/group_copies/protection_windows');
	$req->method('GET');
	$req->header('content-type' =>'application/json');
	$req->header('accept' =>'application/json');
																													
	$req->authorization_basic($user,$pass);
	my $response = $ua->request($req);
	if($response->is_success) {                                                                                                                                           
		$message = $response->decoded_content;
		$windows = $json->decode($message);
		$i = 0;
		while($windows->{'innerSet'}->[$i]) {
			$groupuid = $windows->{'innerSet'}->[$i]->{'groupCopyUID'}->{'groupUID'}->{'id'};
			$clusteruid = $windows->{'innerSet'}->[$i]->{'groupCopyUID'}->{'globalCopyUID'}->{'clusterUID'}->{'id'};
			$copyuid = $windows->{'innerSet'}->[$i]->{'groupCopyUID'}->{'globalCopyUID'}->{'copyUID'};
			$mycopyuid = $clusteruid . $copyuid . $groupuid;
			$currentprotwindow = $windows->{'innerSet'}->[$i]->{'protectionWindows'}->{'currentProtectionWindow'}->{'protectionWindowInMicroSeconds'};
			$predictedwindow = $windows->{'innerSet'}->[$i]->{'protectionWindows'}->{'predictedProtectionWindow'}->{'protectionWindowInMicroSeconds'};
			$groupData->{$host}->{$mycopyuid}->{'currentProtWindow'} = $currentprotwindow;
			$groupData->{$host}->{$mycopyuid}->{'predictedProtWindow'} = $predictedwindow;
			#print "Found copy with $currentprotwindow and $predictedwindow\n";
			$i++
		} # done looping through protection windows
	} else {
	  print "HTTP error message" . $response->message() . "\n";
	} # end block dealing with protection windows
  } # end block dealing with original request
} # end if line is real, not a comment
} # end while looping through clusters

close($systems);

# now we have a var called groupData
# it has the following vars
#$groupData->{$host}->{$mycopyuid}->{'currentProtWindow'} = $currentprotwindow;
#$groupData->{$host}->{$mycopyuid}->{'predictedProtWindow'} = $predictedwindow;
#$groupData->{$host}->{$mycopyuid}->{'copyName'} = $copyname;
#$groupData->{$host}->{$mycopyuid}->{'reqWindow'} = $reqwindow;
#$groupData->{$host}->{$mycopyuid}->{'cluster'} = $host;
#$groupData->{$host}->{$mycopyuid}->{'groupName'} = $groupname;
foreach my $host (keys %$groupData) { 
	foreach my $mycopyuid (keys %{$groupData->{$host}}) {
		print $host;
		print ',';
		print $groupData->{$host}->{$mycopyuid}->{'groupName'};
		print ',';
		print $groupData->{$host}->{$mycopyuid}->{'copyName'};
		print ',';
		print $groupData->{$host}->{$mycopyuid}->{'reqWindow'};
		print ',';
		print $groupData->{$host}->{$mycopyuid}->{'currentProtWindow'};
		print ',';
		print $groupData->{$host}->{$mycopyuid}->{'predictedProtWindow'};
		print "\n";
	}
}

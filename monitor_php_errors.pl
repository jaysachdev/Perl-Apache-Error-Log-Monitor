#!/usr/bin/perl

use File::Tail;
use LWP;
use URI::Escape ('uri_escape');
use strict;

##################################################
#
# Set the following:
#   $file_path      : path of log to tail
#   $email          : email to receive errors
#   $http_error_url : URL to post to
#
##################################################

my $file_path = '';
my $email = '';
my $http_error_url = '';



# prompt for file path if not set
if ( ! $file_path) {
	print "\nPlease enter your error log path: ";
	$file_path = <>;
}


# open the file
my $file = File::Tail->new( name        => $file_path,
														debug       => 0,
														interval    => 1,
														maxinterval => 60,
														adjustafter => 20,
														errmode=>"return") or die "Could not open $file_path: $!";

# print some info, always nice to see the start time
print "\n" . `date`;
print "-- Monitoring File\n   $file_path\n\n";

# main loop
while (my $line = $file->read) {
	if ($line =~ /php .* error/i) {
		print "\n--- ERROR ---\n$line\n--- /ERROR ---\n\n";
		sendError($line);
		smsError($line);
	}
}

# done, print closing info, nice to see when script ended
print "\n" . `date`;
exit 0;



# ------------- Begin Subroutines ------------- 



#
# Open a pipe to sendmail, email the error message to $email
# Will use sendBackupError as a fallback if sendmail cannot
# be opened.
#
sub sendError() {
  my $error = shift;
  
  if ( ! $email) {
	  open(MAIL, '|/usr/sbin/sendmail "' . $email . '"') || (print "\n\nEMAIL NOT SENT!!!\n\n"; return 0);
	  print MAIL 'To: <' . $email . '>' . "\n";
	  print MAIL 'From: <' . $email . '>' . "\n";
	  print MAIL "Subject: PHP Error\n\n" . $error;
	  close(MAIL);
  }
  else {
  	print "No email specified.\n";
  }
  return 1;
}


#
# Submit error to HTTP script.  
# Appends message to $http_error_url
#
sub sendHttpError() {
  my $error = shift;
  
  if ( ! $http_error_url) {
  	print "No HTTP URL specified.\n";
  	return 1;
  }
  
	# escape & append error
	my $get_url = $http_error_url . uri_escape($error); 

  # send using LWP
  my $ua = LWP::UserAgent->new;
  my $res = $ua->request(HTTP::Request->new(GET => $get_url));
  
  ##
  ## Uncomment if you want to see the content of this GET request
  ##
#  print "\n------- smsError HTTP Response -------\n";
#	if ($res->is_success) {
#		print $res->content . "\n";
#	}
#	else {
#		print $res->status_line, "\n";
#	}
#  print "\n------- /smsError HTTP Response -------\n";
	
	return $res->is_success;
}

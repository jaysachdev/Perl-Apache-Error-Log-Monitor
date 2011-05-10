#!/usr/bin/perl

use File::Tail;
use LWP;
use URI::Escape ('uri_escape');
use strict;

################################################################################
#
# Copyright (c) 2010, Jay Sachdev <jay@mosioproject.com>
# (See bottom of file for license)
#
# Usage:
#
# Set the following:
#   $file_path      : path of log to tail
#   $email          : email to receive errors
#   $http_error_url : URL to post to, message is escaped and appended to end.
#
################################################################################

my $file_path = '';
my $email = '';
my $http_error_url = '';

my $sendmail = '/usr/sbin/sendmail';


# prompt for file path if not set
if ( ! $file_path) {
	print "\nPlease enter your error log path: ";
	$file_path = <>;
	chomp $file_path;
}

# prompt for email if not set
if ( ! $email) {
	print "\nPlease enter the email address to send errors to: ";
	$email = <>;
	chomp $email;
}


# open the file
my $file = File::Tail->new( name        => $file_path,
														debug       => 0,
														interval    => 1,
														maxinterval => 5,
														adjustafter => 10,
														errmode     => "die");

# print some info, always nice to see the start time
print "\n" . `date`;
print "-- Monitoring File\n   $file_path\n\n";

# main loop
my $line;
while (defined($line = $file->read)) {
	if ($line =~ /php.*error/i) {
		print "\n--- ERROR ---\n$line\n--- /ERROR ---\n\n";
		sendError($line);
		sendHttpError($line);
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

  if ( ! -e $sendmail) {
  	print "Cannot find sendmail.\n";
  	return 0;
  }

  if ($email) {
	  open(MAIL, '| ' . $sendmail . ' "' . $email . '"') || (print "\n\nEMAIL NOT SENT!!!\n\n" && return 0);
	  print MAIL 'To: <' . $email . '>' . "\n";
	  print MAIL 'From: <' . $email . '>' . "\n";
	  print MAIL "Subject: PHP Error\n\n" . $error;
	  close(MAIL);
	  print "Email sent to: $email\n";
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
#  print "\n------- sendHttpError HTTP Response -------\n";
#	if ($res->is_success) {
#		print $res->content . "\n";
#	}
#	else {
#		print $res->status_line, "\n";
#	}
#  print "\n------- /sendHttpError HTTP Response -------\n";

	return $res->is_success;
}



=pod


Copyright (C) 2010 by Jay Sachdev <jay@mosioproject.com>

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



=cut
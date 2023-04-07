#!/usr/bin/perl
use warnings;
use strict;
use LoxBerry::System;
#use LoxBerry::Log;
use CGI;
use JSON;
#use Data::Dumper;

my $error;
my $response;
my $cgi = CGI->new;
my $q = $cgi->Vars;

#print STDERR Dumper $q;

#my $log = LoxBerry::Log->new (
#    name => 'AJAX',
#	stderr => 1,
#	loglevel => 7
#);

#LOGSTART "Request $q->{action}";

if( $q->{action} eq "servicerestart" ) {
	my $exitcode = execute ("sudo systemctl restart debmatic");
	sleep(3);
	if ($exitcode eq "0") {
		$response = encode_json( { status => "0" } );
	} else {
		$response = encode_json( { status => "1" } );
	}
}

if( $q->{action} eq "servicestop" ) {
	my $exitcode = execute ("sudo systemctl stop debmatic");
	sleep(3);
	if ($exitcode eq "0") {
		$response = encode_json( { status => "0" } );
	} else {
		$response = encode_json( { status => "1" } );
	}
}

if( $q->{action} eq "servicestatus" ) {
	my %pids;
	my %response;
	my $output;
	($pids{'rfd'}, $output) = execute ("pgrep -f rfd");
	($pids{'hmserver'}, $output) = execute ("pgrep -f HMIPServer.jar");
	($pids{'lighttpd'}, $output) = execute ("pgrep -f /etc/debmatic/lighttpd");
	($pids{'multimacd'}, $output) = execute ("pgrep -f /bin/multimacd");
	($pids{'cuxd'}, $output) = execute ("pgrep -f /usr/local/addons/cuxd/cux");
	($pids{'regahss'}, $output) = execute ("pgrep -f /bin/ReGaHss");
	$response{'status'} = \%pids;
	$response = encode_json( \%response );
}

if( $q->{action} eq "debmaticinfo" ) {
	my ($exitcode, $output) = execute ("sudo /usr/sbin/debmatic-info");
	if ($exitcode eq "0") {
		$response = encode_json( { output => "$output" } );
	} else {
		$response = encode_json( { output => "No data" } );
	}
}

if( $q->{action} eq "getconfig" ) {
	my %response;
	my $hmport = qx ( cat /etc/debmatic/webui.conf | grep -e "^var.debmatic_webui_http_port.*" | cut -d "=" -f2 | xargs );
	chomp $hmport;
	my $nrport = qx ( cat /mnt/dietpi_userdata/node-red/settings.js | grep -e "^\\s*uiPort:.*" | sed 's/[^0-9]*//g' );
	chomp $nrport;
	$response{'hmport'} = "$hmport";
	$response{'nrport'} = "$nrport";
	$response = encode_json( \%response );
}

if( $q->{action} eq "saveconfig" ) {
	my $hmport = $q->{"hmport"};
	my $nrport = $q->{"nrport"};
	$hmport = "8081" if !$hmport;
	$nrport = "1880" if !$nrport;
	execute ("sudo $lbpbindir/saveconfig.sh $hmport $nrport");
	my %response;
	$response{'hmport'} = "$hmport";
	$response{'nrport'} = "$nrport";
	$response = encode_json( \%response );
}

if( defined $response and !defined $error ) {
	print "Status: 200 OK\r\n";
	print "Content-type: application/json; charset=utf-8\r\n\r\n";
	print $response;
	#LOGOK "Parameters ok - responding with HTTP 200";
}
elsif ( defined $error and $error ne "" ) {
	print "Status: 500 Internal Server Error\r\n";
	print "Content-type: application/json; charset=utf-8\r\n\r\n";
	print to_json( { error => $error } );
	#LOGCRIT "$error - responding with HTTP 500";
}
else {
	print "Status: 501 Not implemented\r\n";
	print "Content-type: application/json; charset=utf-8\r\n\r\n";
	$error = "Action ".$q->{action}." unknown";
	#LOGCRIT "Method not implemented - responding with HTTP 501";
	print to_json( { error => $error } );
}

END {
	#LOGEND if($log);
}

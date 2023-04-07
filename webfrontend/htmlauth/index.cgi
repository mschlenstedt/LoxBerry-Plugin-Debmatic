#!/usr/bin/perl

# Copyright 2019 Michael Schlenstedt, michael@loxberry.de
#                Christian Fenzl, christian@loxberry.de
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################################################################
# Modules
##########################################################################

# use Config::Simple '-strict';
# use CGI::Carp qw(fatalsToBrowser);
use CGI;
use LoxBerry::System;
#use LoxBerry::Web;
use LoxBerry::JSON; # Available with LoxBerry 2.0
#require "$lbpbindir/libs/LoxBerry/JSON.pm";
use LoxBerry::Log;
#use Time::HiRes qw ( sleep );
use warnings;
use strict;
#use Data::Dumper;

##########################################################################
# Variables
##########################################################################

my $log;

# Read Form
my $cgi = CGI->new;
my $q = $cgi->Vars;

my $version = LoxBerry::System::pluginversion();
my $template;
my $templateout;

# Language Phrases
my %L;

##########################################################################
# AJAX
##########################################################################

if( $q->{ajax} ) {
	
	## Handle all ajax requests 
	require JSON;
	# require Time::HiRes;
	my %response;
	ajax_header();

	exit;

##########################################################################
# Normal request (not AJAX)
##########################################################################

} else {
	
	require LoxBerry::Web;
	
	if ( ! -e "$lbplogdir/hmserver.log" ) {
		my $exitcode = execute ( "ln -s /var/log/hmserver.log $lbplogdir/hmserver.log");
	}

	# Default is debmatic form
	$q->{form} = "debmatic" if !$q->{form};

	if ($q->{form} eq "debmatic") {
		my $templatefile = "$lbptemplatedir/debmatic_settings.html";
		$template = LoxBerry::System::read_file($templatefile);
		&form_debmatic();
	}
	else {
		my $templatefile = "$lbptemplatedir/general_settings.html";
		$template = LoxBerry::System::read_file($templatefile);
		&form_settings();
	}
	
}

# Print the form out
&printtemplate();

exit;

##########################################################################
# Form: Debmatic
##########################################################################

sub form_debmatic
{

	# Prepare template
	&preparetemplate();

	# Homematic WebUI
	my $host = "$ENV{SERVER_NAME}";
	my $hmport = qx ( cat /etc/debmatic/webui.conf | grep -e "^var.debmatic_webui_http_port.*" | cut -d "=" -f2 | xargs );
	chomp $hmport;
	my $nrport = qx ( cat /mnt/dietpi_userdata/node-red/settings.js | grep -e "^\\s*uiPort:.*" | sed 's/[^0-9]*//g' );
	chomp $nrport;
	$templateout->param("HMWEBUILINK", "http://$host:$hmport");
	$templateout->param("NRWEBUILINK", "http://$host:$nrport");

	return();
}


##########################################################################
# Form: Settings
##########################################################################

sub form_settings
{
	# Prepare template
	&preparetemplate();

	return();
}


##########################################################################
# Print Form
##########################################################################

sub preparetemplate
{

	# Add JS Scripts
	my $templatefile = "$lbptemplatedir/javascript.js";
	$template .= LoxBerry::System::read_file($templatefile);

	$templateout = HTML::Template->new_scalar_ref(
		\$template,
		global_vars => 1,
		loop_context_vars => 1,
		die_on_bad_params => 0,
	);

	# Language File
	%L = LoxBerry::System::readlanguage($templateout, "language.ini");
	
	# Navbar
	our %navbar;

	$navbar{10}{Name} = "$L{'COMMON.LABEL_DEBMATIC'}";
	$navbar{10}{URL} = 'index.cgi?form=debmatic';
	$navbar{10}{active} = 1 if $q->{form} eq "debmatic";

	$navbar{20}{Name} = "$L{'COMMON.LABEL_SETTINGS'}";
	$navbar{20}{URL} = 'index.cgi?form=settings';
	$navbar{20}{active} = 1 if $q->{form} eq "settings";
	
	$navbar{98}{Name} = "$L{'COMMON.LABEL_LOGS'}";
	$navbar{98}{URL} = "/admin/system/tools/logfile.cgi?logfile=$lbplogdir/hmserver.log&header=html&format=template";
	$navbar{98}{target} = "_blank";
	$navbar{98}{active} = 1 if $q->{form} eq "logs";

	return();
}

sub printtemplate
{

	# Print out Template
	LoxBerry::Web::lbheader($L{'COMMON.LABEL_PLUGINTITLE'} . " V$version", "https://loxwiki.atlassian.net/wiki/spaces/LOXBERRY/pages/1254687237/LoxPoolManager", "");
	# Print your plugins notifications with name daemon.
	print LoxBerry::Log::get_notifications_html($lbpplugindir, 'DebMatic');
	print $templateout->output();
	LoxBerry::Web::lbfooter();
	
	return();

}

######################################################################
# AJAX functions
######################################################################

sub ajax_header
{
	print $cgi->header(
			-type => 'application/json',
			-charset => 'utf-8',
			-status => '200 OK',
	);	
}	

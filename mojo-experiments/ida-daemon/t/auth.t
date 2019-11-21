#!/usr/bin/env perl              # -*- perl -*-

use Mojo::Base -strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use Test::Mojo;

use Mojo::Server::Daemon;

use v5.20;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp;

# Test mutual SSL authentication and allowed clients

# Most of the testing of the daemon (in other test scripts) won't use
# SSL mutual authentication since we can achieve security by telling
# the daemon to listen on a private unix domain socket instead.
#
# However, I still need to test that mutual SSL authentication is
# actually working correctly, so all tests related to that are stored
# here.
#
# I also test connecting to the 

# The following test certs should be installed in certs/test:
#
# ca_cert.pem      A self-signed CA cert
# ca_key.pem       CA private key (signs all other certs)
# server_cert.pem  Server cert, signed by our CA ('authserver.lan')
# server_key.pem   Server private key
# client_cert.pem  Client cert ('localhost.lan', authorised to log in)
# client_key.pem   Client private key
# other_cert.pem   Sample cert that we haven't authorised to log in
# other_key.pem    Private key for same
#
# If these are missing or have expired, use the tools in certs/build
# to create new ones. Instructions are included in test_certs.md

my $ca =     "$Bin/../certs/test/ca_cert.pem";
my $s_cert = "$Bin/../certs/test/server_cert.pem";
my $s_key  = "$Bin/../certs/test/server_key.pem";
my $c_cert = "$Bin/../certs/test/client_cert.pem";
my $c_key  = "$Bin/../certs/test/client_key.pem";
my $o_cert = "$Bin/../certs/test/other_cert.pem";
my $o_key  = "$Bin/../certs/test/other_key.pem";

# Code to set up a server.
# break out conversion of server listen opts to string
sub listen_string ($hash) {
    my @keys = keys %$hash;
    die "missing required {listen}->{rendez} option"
        unless my $rendez = $hash->{rendez};
    my $listen_string = "$rendez?" . join '&', map {
        $_ eq 'rendez' ? () : ("$_=$hash->{$_}")
    } @keys;
    $listen_string;
}
sub build_server ($sopts, $appname, $opts) {
    my $listen = $sopts->{listen};
    my $server;
    if (ref $listen eq 'HASH') {
        my %splice_opts = (     # don't clobber original sopts
             %$sopts,
             # only handles a single listen string
             listen => [ listen_string($listen) ],
        );
        $server = Mojo::Server::Daemon->new(%splice_opts);
    } else {
        # don't attempt conversion otherwise
        $server = Mojo::Server::Daemon->new($sopts);
    };

    # make a config structure
    my @args = ();
    @args = ( config => { config_override => 1, %$opts } ) 
        if ref $opts eq 'HASH';
    $server->build_app($appname, @args);
    $server->start;
    return $server;
}

# Testing matrix:
#
# protocols: http/ws | https/wss
# authentication mode: mutual | server
# listen modes: external port | unix domain socket
#
# Mutual authentication only makes sense for https/wss options. Also,
# apparently https+unix is not a supported option, so we have these
# combinations:
#
# * http/ws with no authentication
# -> listening on external port
# -> listening on unix socket
# * https/wss with no mutual authentication
# -> listening on external port
# * https/wss with mutual authentication
# -> listening on external port

# General configuration options
#
# I could add an option here to tell the server to use a particular
# directory to find files, but I don't have that config option yet.
# I'll just remember to set a sane default value for when we're testing


for my $proto ("http/ws", "https/wss") {
    for my $listen_mode ("port", "unix") {
	for my $auth_mode ("mutual", "server") {

	    next if $proto eq "http/ws" and $auth_mode eq "mutual";
	    next if $proto eq "https/wss" and $listen_mode ne "port";

	    my ($t,$ua,$ioloop);

	    # Server options
	    my ($server,$port,$rendez,$prefix,@keyargs,$verify);
	    $ioloop  = Mojo::IOLoop->singleton;
	    $verify = 0;

	    if ($proto eq "http/ws") {
		$prefix = "http";
	    } else {
		$prefix = "https";
		@keyargs = (
		    ca     => $ca,
		    key    => $s_key,
		    cert   => $s_cert,
		);
		$verify = 1 if ($auth_mode eq "mutual");
	    }

	    if ($listen_mode eq "port") {
		$port    = Mojo::IOLoop::Server->generate_port;
		$rendez  = "$prefix://authserver.lan:$port",
	    } else {
		umask 077;	# make socket only accessible to us
		unlink "/tmp/ida_daemon.sock" if -f "/tmp/ida_daemon.sock";
		$rendez = "$prefix+unix://%2Ftmp%2Fida_daemon.sock";
	    }

	    my $app_options = {
		proto => $prefix,
		auth_mode => $auth_mode,
		auth_cns  => {	# ignored if not doing mutual auth
		    "localhost.lan" => "yes"
		},
	    };

	    # Build server with generated options
	    $server = build_server(
		{
		    listen => {
			rendez => $rendez,
			verify => $verify,
			@keyargs,
			
		    },
		    ioloop => $ioloop,
		},
		'IDA::Daemon', $app_options);
		
	    ok(ref($server), "Server opts $proto, $listen_mode, $auth_mode?");
	}
    }
}


done_testing();

unlink "/tmp/ida_daemon.sock" if -f "/tmp/ida_daemon.sock";

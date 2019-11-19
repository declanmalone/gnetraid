#!/usr/bin/env perl

package Mojolicious::Command::sendfile;
use Mojo::Base 'Mojolicious::Command';

# Short description
has description => 'My first Mojo command';

# Usage message from SYNOPSIS
has usage => sub { shift->extract_usage };

use v5.20;
use Mojo::UserAgent;
use Mojo::Promise;

# We have to jump through hoops to read a single message from the
# websocket...
sub get_response {
    my $tx = shift;
    my $promise = Mojo::Promise->new;
    $tx->once(message => sub {
	my ($tx,$msg) = @_;
	$promise->resolve($msg);
	      });
    return $promise;
}

sub run {
    my ($self, $host, $port, $file, @junk) = @_;

    if ($host ne "localhost") {
	die "We only support connecting to localhost for now\n";
    }

    my $ua = Mojo::UserAgent->new;
    $ua->websocket("ws://$host:$port/sha" => sub {
	my ($ua, $tx) = @_;
	say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
	$tx->on(finish => sub {
	    my ($tx, $code, $reason) = @_;
	    say "WebSocket closed with status $code.";
		});

	# Use get_response above to wait for a single response message
	$tx->send("RECEIVE $file");
	my $send_port;
	get_response($tx)->then(sub {
	    my $msg = shift;
	    if ($msg =~ /port (\d+)/i) {
		$send_port = $1;
		warn "Will send to port $send_port\n";
	    } else {
		die "Message from server '$msg' didn't list port number\n";
	    }
	    $tx->on(message => sub {
		my ($tx,$msg) = @_;
		warn "$msg\n";
		    });
	    $tx->send("SEND $send_port $file");
				});

		   });

    Mojo::IOLoop->start;
    
}

=head1 SYNOPSIS

Usage: APPLICATION sendfile localhost port ./filename

=head1 DESCRIPTION

Exercises the sender and receiver sides of the demo:

=over

=item 1. Makes a WebSocket connection to a running instance of this app on localhost:port

=item 2. Sends a RECEIVE command with the file name and gets back a port number

=item 3. Sends a SEND command with the file name and the same port number

=item 4. Sender and receiver transfer the file

=item 5. Receiver calculates SHA1 hash and reports it back to us

=back

=head1 NOTES

The sender side of the demo is restricted to only sending files in the
same directory as the script itself. This is just a very basic
security feature to prevent exfiltration of sensitive files
from the system.

=cut

    
1;

package main;

use Mojolicious::Lite;
use Digest::SHA;

use FindBin qw($Bin);

use Mojo::IOLoop::Server;

app->{transactions}={};

# Index page includes a simple JavaScript WebSocket client
get '/' => 'index';

# WebSocket service 
websocket '/sha' => sub {
    my $c = shift;

    # Opened
    $c->app->log->debug('WebSocket opened');

    # Increase inactivity timeout for connection a bit
    $c->inactivity_timeout(300);

    # Incoming message
    $c->on(message => sub {
	my ($c, $msg) = @_;
	$c->app->log->debug("Got message $msg\n");

	# Receiver side
	if ($msg =~ /^RECEIVE (.*)$/) {
	    $msg = $1;
	
	    if (exists(app->{transactions}->{$msg})) {
		my $port = app->{transactions}->{$msg}->{port};
		$c->send("$msg: already running on port $port");
		return;
	    }

	    my $server = Mojo::IOLoop::Server->new;
	    $server->on(accept => sub {
		my ($server,$handle) = @_;
		$c->app->log->debug("accepted connection");
		$server->stop;	# only accept one connection
		my $sum = Digest::SHA->new("sha1");
		my $stream = Mojo::IOLoop::Stream->new($handle);
		$stream->on(read => sub {
		    my ($stream,$data) = @_;
		    my $size = length($data);
		    $c->app->log->debug("read $size bytes");
		    $sum->add($data);
			    });
		$stream->on(close => sub {
		    $c->app->log->debug("closing connection");
		    my $hex = $sum->hexdigest;
		    $c->send("$msg: $hex");
		    delete app->{transactions}->{$msg};
			    });
		app->{transactions}->{$msg}->{stream}=$stream;
		$stream->start;
			});
	    $server->listen(port => 0);
	    my $port = $server->port;
	    app->{transactions}->{$msg}->{port}=$port;
	    app->{transactions}->{$msg}->{server}=$server;
	    $server->start;
	    
	    $c->send("Port $port ready to receive $msg");

        # Sender side
	} elsif ($msg =~ /^SEND (\d+) (.*)$/) {

	    my ($port, $file) = ($1,$2);
	    # Only allow sending of file in current directory
	    if ($file =~ m|^\./[^/]+$|) {
		if (!open my $fh, "<", "$Bin/$file") {
		    $c->send("No such file '$file'");
		} else {
		    # IOLoop::Stream can read from a file, but not
		    # write to one!
		    my $client = Mojo::IOLoop::Client->new;
		    $client->on(connect => sub {
			my ($client, $handle) = @_;
			$c->app->log->debug("Sender connected to receiver");
			my $istream = Mojo::IOLoop::Stream->new($fh);
			my $ostream = Mojo::IOLoop::Stream->new($handle);
			$ostream->start;
			$istream->on(read => sub {
			    my ($istream,$data) = @_;
			    my $size = length($data);
			    $c->app->log->debug("sent $size bytes");
			    $ostream->write($data);
				     });
			$istream->start;
				});
		    $client->on(error => sub {
			my ($client, $err) = @_;
			$c->send("Sender: Error connecting: $err");
				});
		    $client->connect(address => 'localhost',
				     port => $port);
		    $client->reactor->start unless $client->reactor->is_running;
		}
	    } else {
		$c->send("Invalid filename '$file'");
	    }

	} else {
	    $c->send("Invalid command!");
	}	    
           });

    # Closed
    $c->on(finish => sub {
	my ($c, $code, $reason) = @_;
	$c->app->log->debug("WebSocket closed with status $code");
           });
};

app->start;

1;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Mojolicious WebSocket Example</h1>

<p>This page connects to the server using a WebSocket and tells it to set
up a server on a random port. You can then upload a file to that port
and we get back the SHA1 of that file over the WebSocket.</p>

<p>The steps are:

<ol>
<li> Enter some unique string to identify the file and submit </li>
<li> The server listens on a random port and tells us the port number. </li>
<li> Manually upload a file to the port (eg, <code>netcat -q0 localhost <i>port</i> &lt; input_file</code>)
<li> The server reads the file and reports back the SHA1 sum </li>
</ol>

<!-- <input id="form"> <input id="submit" type="submit"> -->
<form id="form">
    <label for="sub-topic">Filename: </label>
    <input type="text" id="formvalue" class="form-control" />
    <button class="btn btn-primary">Send</button>
</form>

<h3>Transcript</h3>

<pre id="preblock">
</pre>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body>
  <%= content %>

  <!-- if I put the script first, getElementById fails -->
  <script>
    var pre = document.getElementById("preblock");
    var ws  = new WebSocket('<%= url_for('sha')->to_abs %>');
    // var form = document.getElementById("form");

    document.forms["form"].onsubmit 
      = function(e) { 
        e.preventDefault();
        // is there no better way of doing this based on ID?
        var val = document.forms["form"].elements.item(0).value;
        ws.send("RECEIVE " + val);
      };

    // Incoming messages
    ws.onmessage = function (event) {
	pre.innerHTML += event.data + "\n";
	// document.body.innerHTML += event.data + '<br/>';
    };

    // Outgoing messages
    // ws.onopen = function (event) {
    //   window.setInterval(function () {
    // 	ws.send('Hello Mojo!')
    //   }, 1000);
    // };

    // Handle closure
    ws.onclose = function(event) {
      pre.innerHTML += "WebSocket closed with code " + event.code + "\n";
      pre.innerHTML += "Reload the page to re-connect\n";
    }

  </script>
  </body>
</html>

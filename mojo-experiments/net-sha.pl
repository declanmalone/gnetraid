#!/usr/bin/env perl
use Mojolicious::Lite;
use Digest::SHA;

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

	if (exists(app->{transactions}->{$msg})) {
	    my $port = app->{transactions}->{$msg}->{port};
	    $c->send("$msg: already running on port $port");
	    return;
	}

	my $server = Mojo::IOLoop::Server->new;
	$server->on(accept => sub {
	    my ($server,$handle) = @_;
	    $c->app->log->debug("accepted connection\n");
	    $server->stop;	# only accept one connection
	    my $sum = Digest::SHA->new("sha1");
	    my $stream = Mojo::IOLoop::Stream->new($handle);
	    $stream->on(read => sub {
		my ($stream,$data) = @_;
		$sum->add($data);
			});
	    $stream->on(close => sub {
		$c->app->log->debug("closing connection\n");
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
           });

    # Closed
    $c->on(finish => sub {
	my ($c, $code, $reason) = @_;
	$c->app->log->debug("WebSocket closed with status $code");
           });
};

app->start;
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
        ws.send(val);
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

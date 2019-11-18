#!/usr/bin/env perl
use Mojolicious::Lite;
use Digest::SHA;

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
	$c->send("echo: $msg");
	$c->app->log->debug("Got message $msg\n");
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

Enter a filename below to open a new port to receive that file on. You
can use netcat to send the file to that port and we will receive a
message back here that reports on the SHA1 hash.

<!-- <input id="form"> <input id="submit" type="submit"> -->
<form id="form">
  <div id="sub-topic-field" class="form-group">
    <label for="sub-topic">Filename: </label>
    <div class="input-group">
      <input type="text" id="formvalue" class="form-control" />
      <span class="input-group-btn">
         <button class="btn btn-primary">Send</button>
      </span>
    </div>
  </div>
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

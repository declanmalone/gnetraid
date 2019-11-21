package IDA::Daemon;
use Mojo::Base 'Mojolicious';

use Mojo::IOLoop::Server;
use IO::Socket::SSL;

# This method will run once at server start
sub startup {
  my $self = shift;
  my $app = $self->app;

  # Find our commands
  push @{$self->commands->namespaces}, 'IDA::Command';

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config' => { 
      file => "ida-daemon.conf"} );

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Callback to debug SSL verify
  IO::Socket::SSL::set_defaults(
      callback => sub {
	  # say "Disposition: $_[0]";
	  # say "Cert store (C):<<$_[1]>>";
	  # say "Issuer/Owner:<<$_[2]>>";
	  say "Errors?: $_[3]";
	  say $_[0] ? "Accepting cert" : "Not accepting cert";
	  return  $_[0];
      });

  # SSL Mutual Authentication (requires a whitelist of auth'd cn's)
  $config->{auth_cns} = {} unless exists $config->{auth_cns};
  $r->add_condition(ssl_auth => sub {
      my ($route, $c, $captures, $num) = @_;

      my $id     = $c->tx->connection;
      my $handle = Mojo::IOLoop->stream($id)->handle;
      my $authorised_cns = $app->config->{auth_cns};

      if (ref $handle ne 'IO::Socket::SSL') {
          # Not SSL connection
          # if we get here, chances are that server hasn't
          # defined its web identity (cert, key).

          my $type = ref $handle;
          $c->render(text => "ref = $type (not IO::Socket::SSL)");
      } else {
          my $cn = $handle->peer_certificate('commonName');
          unless (defined $cn) {
              $c->render(status => 403, text => 'No client cert received');
          } elsif (exists $authorised_cns->{$cn}) {
              $c->stash(authorised => $cn);
              return 1;
              $c->render(text => 'Welcome! commonName matched!');
          } else {
              $c->render(status => 403, text => "You're not on the list, $cn!");
          }
      }
      return undef;
  });

  # Normal route to controller
  #  $r->get('/')->to('example#welcome');

  $app->{transactions}={};

  # Index page includes a simple JavaScript WebSocket client
  $r->get('/')->to(template => 'index')->over('ssl_auth');

  # WebSocket service 
  $r->websocket('/sha' => sub {
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
	      
	      if (exists($app->{transactions}->{$msg})) {
		  my $port = $app->{transactions}->{$msg}->{port};
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
		      delete $app->{transactions}->{$msg};
			      });
		  $app->{transactions}->{$msg}->{stream}=$stream;
		  $stream->start;
			  });
	      $server->listen(port => 0);
	      my $port = $server->port;
	      $app->{transactions}->{$msg}->{port}=$port;
	      $app->{transactions}->{$msg}->{server}=$server;
	      $server->start;
	      
	      $c->send("Port $port ready to receive $msg");

	      # Sender side
	  } elsif ($msg =~ /^SEND (\d+) (.*)$/) {

	      my ($port, $file) = ($1,$2);
	      # Only allow sending of file in current directory
	      if ($file =~ m|^\./[^/]+$|) {
		  if (!open my $fh, "<", "$file") {
		      $c->send("No such file '$file'");
		  } else {
		      # IOLoop::Stream can read from a file, but not
		      # write to one!
		      my $client = Mojo::IOLoop::Client->new;
		      $app->{transactions}->{$file}->{client} = $client;
		      $client->on(connect => sub {
			  my ($client, $handle) = @_;
			  $c->app->log->debug("Sender connected to receiver");
			  my $istream = Mojo::IOLoop::Stream->new($fh);
			  my $ostream = Mojo::IOLoop::Stream->new($handle);
			  $app->{transactions}->{$file}->{istream} = $istream;
			  $app->{transactions}->{$file}->{ostream} = $ostream;
			  $ostream->start;
			  $istream->on(read => sub {
			      my ($istream,$data) = @_;
			      my $size = length($data);
			      $c->app->log->debug("sent $size bytes");
			      $ostream->write($data);
				       });
			  $istream->on(close => sub {
			      $ostream->close_gracefully;
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
		      $c->send("Sender finished");
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
		})->over('ssl_auth');

}

1;

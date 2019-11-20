package IDA::Daemon;
use Mojo::Base 'Mojolicious';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Mojo::IOLoop::Server;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Find our commands
  push @{$self->commands->namespaces}, 'IDA::Command';

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config' => { 
      file => "ida-daemon.conf"} );

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  #  $r->get('/')->to('example#welcome');

  $self->app->{transactions}={};

  # Index page includes a simple JavaScript WebSocket client
  $r->get('/' => 'index');

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
	      
	      if (exists($self->app->{transactions}->{$msg})) {
		  my $port = $self->app->{transactions}->{$msg}->{port};
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
		      delete $self->app->{transactions}->{$msg};
			      });
		  $self->app->{transactions}->{$msg}->{stream}=$stream;
		  $stream->start;
			  });
	      $server->listen(port => 0);
	      my $port = $server->port;
	      $self->app->{transactions}->{$msg}->{port}=$port;
	      $self->app->{transactions}->{$msg}->{server}=$server;
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
		      $self->app->{transactions}->{$file}->{client} = $client;
		      $client->on(connect => sub {
			  my ($client, $handle) = @_;
			  $c->app->log->debug("Sender connected to receiver");
			  my $istream = Mojo::IOLoop::Stream->new($fh);
			  my $ostream = Mojo::IOLoop::Stream->new($handle);
			  $self->app->{transactions}->{$file}->{istream} = $istream;
			  $self->app->{transactions}->{$file}->{ostream} = $ostream;
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
		});

}

1;

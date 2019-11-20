package IDA::Command::sendfile;
use Mojo::Base 'Mojolicious::Command';

use strict;
use warnings;

# Short description
has description => 'Instruct a running server to hash a local file';

# Usage message from embedded POD
has usage => sub { shift->extract_usage };

use v5.20;
use Mojo::UserAgent;
use Mojo::Promise;

# We have to jump through hoops to read a single message from a
# websocket... promises/async code tend to infect everything they come
# in contact with.
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

	# Use get_response to wait for a single response message
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

Usage: ./net-sha-demo.pl sendfile localhost port ./filename

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

This man page may not make much sense unless you've already tried out
the web interface. Fire it up with:

 net-sha-demo.pl daemon -l "http://localhost:3000"

Then point your JavaScript-enabled browser at C<http://localhost:3000>.

The web part of the demo can only demonstrate setting up a server to
I<receive> a file since we use regular sockets for the transfer and
JavaScript is not allowed to use them. Neither can it access arbitrary
files on the system. That's why the send/receive demo here is
implemented as a Mojolicious Command which simply instructs the
running web app to do all the socket/file operations.

Note also that the sender side of the demo is restricted to sending
files in the same directory as the script itself.  This is just a very
basic security feature to prevent exfiltration of sensitive files from
the system. It's also hard-wired to only send files to localhost.

=head1 EXAMPLE

Change into the directory where this script is stored and type:

 $ ./net-sha-demo.pl sendfile localhost 3001 ./net-sha-demo.pl

You should see something like:

 Will send to port 33049
 Sender finished
 ./net-sha-demo.pl: 2ac7dd75efba18f6c9b1f206b37c5abd79d2021e
 WebSocket closed with status 1006.

The SHA1 sum will be different, but you can compare with the command
below:

 $ sha1sum ./net-sha-demo.pl
 2ac7dd75efba18f6c9b1f206b37c5abd79d2021e  ./net-sha-demo.pl


=cut

    
1;


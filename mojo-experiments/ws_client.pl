#!/usr/bin/env perl


use strict;
use warnings;

# This talks to an active Mercury broker on localhost

my $push_broker = "ws://localhost:3000/push/bender";
my $pull_broker = "ws://localhost:3000/pull/bender";

use v5.20;
use Mojo::UserAgent;
#use Mercury::Pattern::PushPull;

my ($host,$port) = @ARGV;

die "Usage: $0 host port\n" unless defined $port;

my $ua = Mojo::UserAgent->new;

my $pull_tx = $ua->websocket(
    $pull_broker
    # => ['v1.proto']
    # => {DNT => 1} => ['v1.proto']
    => sub {
	my ($ua, $tx) = @_;
	say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
	$tx->on(message => sub {
	    my ($tx, $msg) = @_;
	    say "/pull/bender: $msg";
	    #$tx->finish;
		});
	$tx->on(finish => sub { 
	    my ($tx,$code,$reason) = (shift,shift,shift // "");
	    say "Finish /pull/bender: $code $reason" });
    });


#my $pattern = Mercury::Pattern::PushPull->new;
my $tx = $ua->websocket(
    $push_broker
    # => ['v1.proto']
    # => {DNT => 1} => ['v1.proto']
    => sub {
	my ($ua, $tx) = @_;
	say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
	$tx->on(message => sub {
	    my ($tx, $msg) = @_;
	    say "WebSocket message: $msg";
	    $tx->finish;
		});
	$tx->on(finish => sub {
	    my ($tx,$code,$reason) = (shift,shift,shift // "");
	    say "Finish /pull/bender: $code $reason" });
	#$pattern->add_pusher( $tx );
	for (4 .. 22) {
	    say "Sending $_ (with small sleep)";
	    $tx->send("Hello $_ (with small sleep)");

	    #$pattern->send_message("Hello (message) $_");

	    # Don't sleep too long here!
	    sleep 0.01;
	}
    });

#my $pattern = Mercury::Pattern::PushPull->new;
#$pattern->add_pusher( $tx );
#$tx = $ua->websocket('ws://localhost:3000/push/bender');

#$tx->send("foobar");

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;


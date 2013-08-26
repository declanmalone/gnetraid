#!/usr/bin/perl

use strict;
use warnings;

# Coder/Decoder test. Uses actual data.

use lib '../lib';
use Net::OnlineCode::Encoder;
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;

# export xor helper function names into our namespace
use Net::OnlineCode ':xor';

print "Testing: ENCODER AND DECODER\n";

# test string is 41 characters (a prime, so it needs padding unless
# blocksize is 1 or 41)
my $test = "The quick brown fox jumps over a lazy dog";

print "Test string: $test\n";

my $blksiz = shift @ARGV || 4;

print "Block size: $blksiz\n";

# Common Setup

my $istring  = $test;
my $msg_size = length($test);
my $ostring  = "";

# pad input string up to a multiple of blksiz in length
$istring .= "x" x ($blksiz - (length($istring) % $blksiz));

my $mblocks = length($istring) / $blksiz;

print "Message blocks: $mblocks\n";

# Set up encoder, decoder
my $erng = Net::OnlineCode::RNG->new_random;
my $drng = Net::OnlineCode::RNG->new;
$drng->seed($erng->get_seed);

die "initial seed mismatch\n" unless $erng->get_seed eq $drng->get_seed;
die "initial rng mismatch\n"  unless $erng->as_hex eq $drng->as_hex;

my $enc = Net::OnlineCode::Encoder
  ->new(mblocks => $mblocks, initial_rng => $erng, expand_aux => 1);

die "Failed to create encoder. Quitting\n" unless ref($enc);

# extract parameters from encoder
my $e = $enc->get_e;
my $q = $enc->get_q;

print "Setting up decoder with e=$e, q=$q, mblocks=$mblocks\n";

# set up decoder with same parameters
my $dec = Net::OnlineCode::Decoder
  ->new(mblocks => $mblocks, initial_rng => $drng,
	e => $e, q=> $q, expand_aux => 1);
die "Failed to create decoder. Quitting\n" unless ref($dec);

# substr won't allow us to write to portions outside the string, so
# zero it out
$ostring = "x" x (1 * length($istring));

print "Entering main loop\n";

# main loop
my @check_blocks = ();
my $done = 0;
until ($done) {

  my $block_id     = $erng->seed_random;

  die "encoder random seed != block_id\n" unless $block_id eq $erng->get_seed;

  print "\nENCODE Block " . $erng->as_hex . "\n";

  my $enc_xor_list = $enc->create_check_block($erng);

  print "check block contents: " . (join ", ", @$enc_xor_list) . "\n";
  # xor check block
  my $contents = substr($istring,  $blksiz * shift @$enc_xor_list, $blksiz);
  foreach (@$enc_xor_list) {
    xor_strings(\$contents,
		substr($istring,  $blksiz * $_, $blksiz));
  }

  # synchronise decoder rng with same seed as encoder
  $drng->seed($block_id);
  print "\nDECODE Block " . $drng->as_hex . "\n";

  # save contents of checkblock
  push @check_blocks, $contents;

  my @decoded;
  ($done,@decoded)  = $dec->accept_check_block($drng);

  # right now I don't have a way to check that the check block was
  # composed the same was as in the decoder. That information is
  # stored in the decoder's graph object, though.

  print "This checkblock solves " . scalar(@decoded) . " message block(s)\n";
  print "This solves the entire message\n" if $done;

  foreach my $decoded_block (@decoded) {

    my @dec_xor_list = $dec->xor_list($decoded_block);

    print "Decoded message block $decoded_block is composed of: ",
      (join ", ", @dec_xor_list) . "\n";

    my $block = $check_blocks[shift @dec_xor_list];
    foreach my $xor_block (@dec_xor_list) {
      xor_strings(\$block, $check_blocks[$xor_block]);
    }
    print "Decoded message block: '$block'\n";

    substr($ostring, $decoded_block * $blksiz, $blksiz) = $block;
  }
}


print "Decoded text: '$ostring'\n";


#!/usr/bin/perl

use strict;
use warnings;

# Program to trace through decoder execution for a given seed and
# output what's happening at a high level.  This is meant to
# complement using DEBUG flag in the individual libraries, but isn't a
# replacement for it if you want to know the nitty-gritty of how the
# graph is being solved.

# Based on codec.pl, but doesn't use an encoder or do any data
# manipulation

use lib '../lib';
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;

# get args
my ($seed, $mblocks) = @ARGV;

die "Usage: dump seed [mblocks]\n" unless defined $seed;

my $mblocks = 2 unless defined $mblocks;

# Set up RNG
die "supplied seed must be a hex number (40 characters for SHA1 RNG\n"
  unless length($seed) == 40 and ($seed =~ m/^[0-9a-f]+$/i);

$rng = Net::OnlineCode::RNG->new(pack "H*", $seed);

# open a file to store results
open DUMP, ">${seed}.txt" or die "Failed to create output file $!\n";


print DUMP "SEED: " . $rng->as_hex . "\n";
print DUMP "MBLOCKS: \n";

# Set up decoder with other parameters (e,q,f) as default
my $dec = Net::OnlineCode::Decoder
  ->new(mblocks => $mblocks, initial_rng => $rng,
	expand_aux => 0);
die "Failed to create decoder. Quitting\n" unless ref($dec);

# pretty printer for adjacency and XOR list info (width is restricted
# to account for common run case where few blocks/edges are being
# graphed)
format STDOUT_TOP =
Block Expansion    Edges ->         <- Edges  Expansion   Edges ->         <- Edges  Expansion   Block
----- ------------ ------------ ------------ ------------ ------------ ------------ ------------ -----
.
my $spacer=<<END;
----- ------------ ------------ ------------ ------------ ------------ ------------ ------------ -----
END
sub pretty {

}


# extract parameters from decoder and report them
my $e = $enc->get_e;
my $q = $enc->get_q;
my $f = $enc->get_f;
my $ablocks  = $enc->get_ablocks;
my $coblocks = $enc->get_coblocks;

print DUMP "E: $e\n";
print DUMP "Q: $q\n";
print DUMP "F: $f\n";
print DUMP "ablocks: $ablocks\n";
print DUMP "coblocks: $coblocks\n";

# report on initial edges joining 

# main loop
my $check_count = 0;
my $done = 0;
until ($done) {

  # normally, we'd call seed_random, but for testing we want a
  # deterministic order
  my $block_id     = $erng->seed($erng->as_string);

  die "encoder random seed != block_id\n" unless $block_id eq $erng->get_seed;

  ++$check_count;
  print "\nENCODE Block #$check_count " . $erng->as_hex . "\n";

  my $enc_xor_list = $enc->create_check_block($erng);

  print "Encoder check block (after expansion): " . (join ", ", @$enc_xor_list) . "\n";


  # xor check block
  my $contents = substr($istring,  $blksiz * shift @$enc_xor_list, $blksiz);
  foreach (@$enc_xor_list) {
    xor_strings(\$contents,
		substr($istring,  $blksiz * $_, $blksiz));
  }

  # synchronise decoder rng with same seed as encoder
  $drng->seed($block_id);
  print "\nDECODE Block #$check_count " . $drng->as_hex . "\n";


  # save contents of checkblock
  push @check_blocks, $contents;

  my @decoded;
  ($done,@decoded)  = $dec->accept_check_block($drng);

  next unless @decoded;

  # right now I don't have a way to check that the check block was
  # composed the same was as in the decoder. That information is
  # stored in the decoder's graph object, though.

  print "This checkblock solved " . scalar(@decoded) . " message block(s)\n";
  print "This solves the entire message\n" if $done;

  foreach my $decoded_block (@decoded) {

    my @dec_xor_list = $dec->xor_list($decoded_block);

    print "Decoded message block $decoded_block is composed of: ",
      (join ", ", @dec_xor_list) . "\n";

    die "Decoded message block $decoded_block had empty XOR list\n" unless @dec_xor_list;

    my $block = "\0" x $blksiz;

    for my $i (@dec_xor_list) {
      if ($i < $mblocks) {
	print "codec: got message block $i as part of an expansion\n";
	xor_strings(\$block, $decoded_mblocks[$i]); # xor it anyway for now
	
      } elsif ($i >= $coblocks) { # check block
	print "DECODER: XORing block $i (check block) into $decoded_block\n";
	print "(check block # " . ($i - $coblocks) . ")\n";
	xor_strings(\$block, $check_blocks[$i - $coblocks]);
      } else {			# auxiliary block
	print "DECODER: XORing block $i (auxiliary block) into $decoded_block\n";
	xor_strings(\$block, $decoded_ablocks[$i - $ablocks]);
      }
    }
    if ($decoded_block < $mblocks) {
      print "Decoded message block $decoded_block: '$block'\n";
      $decoded_mblocks[$decoded_block] = $block;
    } else {
      print "Decoded auxiliary block $decoded_block\n";
      $decoded_ablocks[$decoded_block - $mblocks] = $block;
    }
  }
}


print "Decoded text: '" . (join("",@decoded_mblocks)) . "'\n";


#!/usr/bin/perl -w

# What do I want my extended encoder test to do?  The simplest thing
# is just to dump the structures created by Net::OnlineCode::Encoder
# and the parent object. This could be useful for debugging what's
# going on.

use lib '../lib';
use Net::OnlineCode::Encoder;

print "Testing: ENCODER\n";

# test string is 41 characters (a prime, so it needs padding unless
# blocksize is 1 or 41)
my $test = "The quick brown fox jumps over a lazy dog";

print "Test string: $test\n";

for my $blksiz (9,10) {

  my $string  = $test;
  $string .= "x" x ($blksiz - (length($string) % $blksiz));
  my $nblocks = length($string) / $blksiz;

  my ($mnum,$mblk,$mdeg,$mlinks);

  my $obj = new Net::OnlineCode(mblocks => $nblocks);



  $mnum = join "\n", (0..$nblocks -1);
  $mblk = join "'\n'", map { substr $string, $_ * $blksiz, $blksiz } (0..$nblocks -1);
  $mdeg = join "\n", (1, 1, 3, 4);
  $mlinks = join ",", (1,2,3,4);

  print "'$mblk'\n";

}


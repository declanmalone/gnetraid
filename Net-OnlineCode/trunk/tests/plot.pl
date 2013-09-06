#!/usr/bin/perl

use strict;
use warnings;

# Call up mindecoder lots of times and record # of decoded check blocks

use lib '../lib';
use Net::OnlineCode::Encoder;
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;


my ($mblocks, $trials, $of, @junk) = @ARGV;

die "$0 mblocks trials output-filename\n" unless defined($of);

$| = 1; # so we get output even if we ^C

open (OUT,">", "plot-$of.txt") or die "Output file? $!\n";



for (1..$trials) {

  open (IN, "./mindecoder.pl $mblocks |") or die "Input? $!\n";

  my ($line,$last) = "";
  while ($line = <IN>) { $last=$line };

  if ($last =~ /^(\d+) \(1\):/) {
    print OUT "$1\n";
    print "$1\n";
  } else {
    die "Format? $last\n";
  }

}


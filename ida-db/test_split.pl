#!/usr/bin/env perl

use strict;
use warnings;

use v5.20;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use IDA::Validate;

use Getopt::Std;

my $usage = <<"EOT";
$0 - confirm sha256 hash of share file

Usage:

 $0 [ida options] file {hex_row sha256_hash}+

IDA options:

 -k  quorum (defaults to 3)
 -w  field size in bytes (defaults to 1)

Other options:

 hex_row      a hexadecimal-encoded representation of the IDA transform
              row for this share
 sha256_hash  expected SHA256 output for this share (including header)

EOT


our($opt_k,$opt_w,$opt_h,$opt_d) = (3,1,0,0);

getopts("k:w:hd");

die $usage if ($opt_h);

my $file = shift @ARGV or die "Input file is required\n";

die "No shares to test. Quitting\n" unless @ARGV;
die "Odd number of additional {row,hash} arguments\n" if (@ARGV & 1);

my @res = 
ida_validate(infile => $file, k => $opt_k, w => $opt_w,
	     tests => [@ARGV]);

print "Results (1 = OK; 0 = mismatch):\n";
print join ":", @res;
print "\n";

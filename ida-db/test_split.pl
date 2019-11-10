#!/usr/bin/env perl

use strict;
use warnings;

use v5.20;

use Math::FastGF2::Matrix;
use Crypt::IDA::Algorithm;
use Crypt::IDA::ShareFile;

use Digest::SHA;

use Getopt::Std;

my $sf_file = "debug.sf";

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

my $debug = $opt_d;

die $usage if ($opt_h);

#say "Next option is " . shift @ARGV;
my $file = shift @ARGV or die "Input file is required\n";

die "No shares to test. Quitting\n" unless @ARGV;
die "Odd number of additional {row,hash} arguments\n" if (@ARGV & 1);

# Combine all the remaining arguments
my $bytes   = $opt_w * $opt_k;
my $nibbles = $bytes * 2;	# number of nibbles per field element
my $hashnib = 64;		# number of nibbles in a SHA256 hash

# We need a matrix of k columns and however many rows the user supplies
my $n       = @ARGV / 2;
my $xform = Math::FastGF2::Matrix->new(
    cols  => $opt_k,
    rows  => $n,
    width => $opt_w,
    org   => "rowwise"
);
# The following array will be the integer values to insert into xform
my @rowwise_xform = ();

my $xform_rows = 0;
my @xform_hex;
my @hash_hex;
while (@ARGV) {
    ++$xform_rows;
    my $hex  = shift @ARGV;
    my $hash = shift @ARGV;

    push @xform_hex, $hex;	# destroyed later, so save now

    die "Hex row $hex is not a hexadecimal string"
	unless $hex =~ /^[a-f0-9]+$/;

    die "Hex row $hex is not $nibbles nibbles in length\n"
	unless $nibbles == length $hex;

    die "SHA256 value $hash is not a valid hexadecimal string\n"
	unless $hash =~ /^[a-f0-9]+$/;

    die "SHA256 value $hash is not $hashnib nibbles in length\n"
	unless $hashnib == length($hash);

    # Build up the composite transform matrix a byte at a time
    while (length $hex) {
	push @rowwise_xform, ord pack "H2", substr $hex,0,2,'';
    }

    # save supplied values for later comparison/reporting
    push @hash_hex,  $hash;
}

die "Internal error: rowwise_xform is wrong size\n"
    unless @rowwise_xform == $opt_w * $opt_k * $n;

# Fill up the xform matrix
$xform->setvals(0,0,\@rowwise_xform);

# Using ::Algorithm, so we are responsible for I/O and padding
open my $fh, "<", $file or die "Couldn't open input file $file: $!\n";

my $filesize = (stat($fh))[7];
my $pad = "";
while ($filesize % $opt_k) {
    $pad.="\0";
    ++$filesize;
}
# fix up file size (back to original value)
$filesize -= length $pad;

# Set up splitter
my $s = Crypt::IDA::Algorithm
    ->splitter(k => $opt_k, xform => $xform, w => $opt_w)
    or die "Couldn't create splitter!\n";

my $bufsize = $s->bufsize;
warn "Using bufsize of $bufsize ($opt_w-byte) symbols\n";

my $sh;
if ($debug) {
    open $sh, ">", $sf_file or die "Couldn't create $sf_file: $!\n";
}

my @hashers = ();
for my $i (0 .. $xform_rows - 1) {

    # Set up SHA objects, one for each row
    my $hasher = Digest::SHA->new('sha256') or
	die "Failed to create Digest::SHA object. Aborting\n";

    # Each hasher has to be primed with the corresponding sharefile
    # header
    
    # Crypt::IDA::ShareFile is only designed to work with files, so it
    # doesn't have an explicit routine for returning a sharefile
    # header as a string. However, since it does allow passing in an
    # arbitrary closure for ostream, it can be used without
    # modification to write to a string. I just lifted the file write
    # code from the module and changed the syswrite to a string
    # append.
    my $header = '';		     # buffer to write to
    my $default_bytes_per_write = 1; # used in closure below
    my $writer = { WRITE => sub {
	my $num=shift;
	my ($override_bytes,$bytes_to_write);
	if ($override_bytes=shift) {
	    $bytes_to_write=$override_bytes;
	} else {
	    $bytes_to_write=$default_bytes_per_write;
	}
	my $buf="";
	if ($num >= 256 ** $bytes_to_write) {
	    warn "ostream: Number too large. Discarded high bits.";
	    $num %= (256 ** ($bytes_to_write) - 1);
	}
	my $hex_format="H" . ($bytes_to_write * 2);
	$buf=pack $hex_format, sprintf "%0*x", $bytes_to_write*2, $num;
	# syswrite $fh,$buf,$bytes_to_write;
	$header .= $buf;
		   }
    };

    # Call undocumented sf_write_ida_header method as a class method (->)
    #
    # transform option appears to need a list of words (not a string)
    my @transform = $xform->getvals($i,0,$opt_k,0);
    warn "Transform row (from matrix) is of of size " . scalar(@transform) . "\n";
    warn "filesize is $filesize\n";
    Crypt::IDA::ShareFile->sf_write_ida_header(
	ostream     => $writer,
	version     => 1,
	quorum      => $opt_k,
	width       => $opt_w,
	chunk_start => 0,
	chunk_next  => $filesize,
	transform   => \@transform,
	opt_final   => 1
    );
    warn "Created header with " . (length $header) . " bytes\n";

    # prime the hasher and save it for later
    print $sh $header if $debug;
    $hasher->add($header);
    push @hashers, $hasher;
}

# Main loop
my ($buf, $bytes_read, $bytes_wanted, $got);
my $eof = 0;
while ($filesize) {
    $bytes_wanted = $bufsize * $opt_w * $opt_k;
    $bytes_wanted = $filesize if $bytes_wanted > $filesize;
    $bytes_read = 0;
    $buf = '';
    while ($bytes_read < $bytes_wanted) {
	# will buffer shrink if we don't do a single read?
	# I might need two buffers below... or always read $byte_wanted

	# I'll use the 4-arg form that takes an offset just to be sure
	$got = read $fh, $buf, $bytes_wanted - $bytes_read, $bytes_read;
	die "Problem reading $bytes_wanted from file: $!\n" unless defined($got);
	if ($got == 0) {
	    # read and sysread semantics are different for EOF
	    # sysread returns 0 when we do the last read
	    # read seems to return a short count instead
	    #
	    # as a result, we never get here with a normal read
	    $eof = 1;
	    $got = $bytes_wanted - $bytes_read;
	}
	$bytes_read += $got;
    }

    $filesize -= $bytes_read;
    die "Internal error: filesize went below zero\n" if $filesize < 0;

    unless ($filesize) {
	warn "Manually setting eof (was $eof)\n";
	$eof = 1;
    }
    
    if ($eof) {
	# defensive/sanity checking code
	die "File truncated!\n" if ($bytes_read < $bytes_wanted);
	die "Internal error: filesize didn't go to zero on eof\n" if $filesize;

	warn "eof flag set\n";
	warn "buf was of size " . length($buf) . "\n";

	# normal operation resumes
	$buf .= $pad;
	warn "updated buf size: " . length($buf) . "\n";
    }

    # warn "buf is of size " . length($buf) . "\n";

    $s->fill_stream($buf);
    $s->split_stream;
    for my $i (0 .. $xform_rows - 1) {
	my $splitbuf = $s->empty_substream($i);
	print $sh $splitbuf if $debug;
	$hashers[$i]->add($splitbuf);
    }
}

# Check outputs
for my $i (0 .. $xform_rows - 1) {
    my $sha_hex = $hashers[$i]->hexdigest;
    if ($hash_hex[$i] ne $sha_hex) {
	warn "Hash mismatch\n";
    } else {
	warn "$i:$xform_hex[$i]:$sha_hex OK\n";
    }
}

    

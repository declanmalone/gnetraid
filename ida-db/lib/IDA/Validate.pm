package IDA::Validate;

use strict;
use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

our $VERSION = '0.01';
our @ISA = qw(Exporter);
our @EXPORT = qw(ida_validate);
#our @EXPORT_OK = qw(ida_validate);

use v5.20;

use Math::FastGF2::Matrix;
use Crypt::IDA::Algorithm;
use Crypt::IDA::ShareFile;

use Digest::SHA;

# I don't/won't implement a constructor. Just use the exported sub
# instead.
sub new { ... }

sub ida_validate {
    my %o = (
	k       => undef,
	w       => 1,
	infile  => undef,
	tests   => undef,
	@_
    );
    my ($opt_w, $opt_k, $file) = @o{qw(w k infile)};

    die "Option 'tests' not an ARRAY reference\n"
	unless ref($o{tests}) eq "ARRAY";
    my @tests = @{$o{tests}}; 	# copy values to fresh array

    die "Option 'k' must be an integer > 0\n"
	unless defined($opt_k) and $opt_k > 0;

    my $n = @tests / 2;
    die "No tests specified" unless $n;
    die "Odd number of elements in tests\n" if $n != int($n);

    # Make up the transform matrix (we'll create/test all the shares
    # at the same time)
    my $xform = Math::FastGF2::Matrix->new(
	cols  => $opt_k,
	rows  => $n,
	width => $opt_w,
	org   => "rowwise"
    );

    # constants used when validating/unpacking test fields
    my $bytes   = $opt_w * $opt_k;
    my $nibbles = $bytes * 2;	# number of nibbles per field element
    my $hashnib = 64;		# number of nibbles in a SHA256 hash

    my @rowwise_xform = ();	# store the k x n xform matrix values
    my @row_hex;
    my @hash_hex;
    my $xform_rows = 0;
    while (@tests) {
	++$xform_rows;
	my $hex  = shift @tests;
	my $hash = shift @tests;

	push @row_hex, $hex;	# destroyed later, so save now

	die "Transform row '$hex' is not a hexadecimal string"
	    unless $hex =~ /^[a-f0-9]+$/;

	die "Transform row '$hex' is not $nibbles nibbles in length\n"
	    unless $nibbles == length $hex;

	die "SHA256 value '$hash' is not a valid hexadecimal string\n"
	    unless $hash =~ /^[a-f0-9]+$/;

	die "SHA256 value '$hash' is not $hashnib nibbles in length\n"
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
    # fix up file size (revert to original value)
    $filesize -= length $pad;

    # Set up splitter
    my $s = Crypt::IDA::Algorithm
	->splitter(k => $opt_k, xform => $xform, w => $opt_w)
	or die "Couldn't create splitter!\n";

    my $bufsize = $s->bufsize;
    warn "Using bufsize of $bufsize ($opt_w-byte) symbols\n" if 0;

    my $sh;

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
	if (0) {
	    warn "Transform row (from matrix) is of of size " 
		. scalar(@transform) . "\n";
	    warn "filesize is $filesize\n";
	}
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
	warn "Created header with " . (length $header) . " bytes\n" if 0;

	# prime the hasher and save it for later
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
	    warn "Manually setting eof (was $eof)\n" if 0;
	    $eof = 1;
	}
	
	if ($eof) {
	    # defensive/sanity checking code
	    die "File truncated!\n" if ($bytes_read < $bytes_wanted);
	    die "Internal error: filesize didn't go to zero on eof\n" if $filesize;

	    if (0) {
		warn "eof flag set\n";
		warn "buf was of size " . length($buf) . "\n";
	    }
	    # normal operation resumes
	    $buf .= $pad;
	    warn "updated buf size: " . length($buf) . "\n" if 0;
	}

	# warn "buf is of size " . length($buf) . "\n";

	$s->fill_stream($buf);
	$s->split_stream;
	for my $i (0 .. $xform_rows - 1) {
	    my $splitbuf = $s->empty_substream($i);
	    $hashers[$i]->add($splitbuf);
	}
    }

    # Check outputs
    my @res = ();
    for my $i (0 .. $xform_rows - 1) {
	my $sha_hex = $hashers[$i]->hexdigest;
	if (0) {
	    if ($hash_hex[$i] ne $sha_hex) {
		warn "Hash mismatch\n";
	    } else {
		warn "$i:$row_hex[$i]:$sha_hex OK\n";
	    }
	} else {
	    push @res, $hash_hex[$i] eq $sha_hex ? 1 : 0;
	}
    }
    @res;
}

1;
__END__
=head1 NAME

IDA::Validate - Validate IDA shares from a replica and sharefile details

=head1 SYNOPSIS

 # exports ida_validate()
 use IDA::Validate;    

 # Use hex strings to encode transform matrix rows
 # (number of decoded bytes should match k)
 my @xform_rows = (
   "54fdac", "debc49", # ...
 );
 # Tell the routine what SHA256 hashes to expect from shares
 my @expected_hashes = (
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    # ...
 );
 my @res = ida_validate(
    k => $quorum_value,
    w => $field_width_in_bytes,
    infile  => "input_file.name",
    # tests => [row0 => hash0, row1 => hash1, ...] :
    tests => [
      map { $xform_row[$_] => $expected_hashes[$_] } 
       (0 .. $number_of_shares - 1)
    ],
 );

 for my $i (0 .. $number_of_shares - 1) {
   next if $res[$i]; 		# non-zero -> success
   warn "Share no. $i didn't match\n";
 }

=head1 DESCRIPTION

This module is intended to support validation of IDA shares that might
be stored remotely without having to collect them all and combine them.

Assumed setup:

=over

=item * You have access to a replica (original file) that you can
    perform a split on

=item * You have shares already created, and they are stored in
    various remote silos

=item * You have a database of containing meta-data about each share:

=over

=item * The SHA256 of that share file

=item * The transform matrix row for that share file (or a way of
    generating it)

=back

=item * You know which replicas map to which shares (eg, you have
    matching dir/file naming)

=back

You can create the sharefile meta-data database when you create the
shares initially, or you can scan them at a later date.

This routine does not create any new files. All SHA256 calculations
are done in memory, so it's quicker than using C<rabin-split.pl>
followed by C<sha256sum> individually.


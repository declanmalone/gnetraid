#!/usr/bin/perl

use strict;
use warnings;

use constant DEBUG => 0;

# Does an "all-or-nothing" transform on a block of data
#
# See Rivest "All-Or-Nothing Encryption and The Package Transform"
#

# The user must provide:
#
# * a "public" key used for the inner encoding
# * a hash algorithm (details below)
# * a block of data to operate on
#
# Optional:
#
# * an outer encoding key (randomly generated if not supplied)
#
# The hash algorithm has two points of interest:
# * it takes an arbitrary length stream of data and produces a hash value
# * the hash values produced are always the same length (bytes)
#
# The fundamental operation that this script does is to take three
# things and combines them to form a hash value:
#
# * an optional data block with the same size as the output hashes
# * an integer counter (which counts from 1 .. number of blocks)
# * an encryption key
#
# There are two different encryption keys, and two different
# encryption steps. Keys should be the same size as the hash function.
#
# The outer encryption uses the hash function to calculate:
#
# hash(outer key, counter)
#
# The inner encryption uses the hash function to calculate:
#
# hash(inner key, counter XOR data block)
#
# Since this script has to be portable across different platforms, we
# need a canonical way of representing counters as, effectively, a
# string. For the outer encryption, this is quite simple: we just have
# to use Perl's stringify operator, eg hash($key, "$counter").
#
# However, we cannot XOR a string with another string (a data block),
# so we need a portable way to combine the two in this way.
#
# Issues such as platform endianness and native integer size make it
# awkward to do this conversion between a native counter and a
# portable string format, while also using the counter as an iterator.
#
# Since hashes can be much larger than a native integer, and native
# integer themselves also vary in size between different platforms,
# there is no single way of implementing them that is both portable
# and efficient. Since both of these are important, though, the
# solution used here is to have a factory for creating counters. At
# the time the factory is created, the various factors relating to the
# platform and desired hash function are cached. Then, the factory can
# be instructed to create a new counter object (technically, an
# anonymous/unblessed) that works most efficiently within the
# constraints given.
#
# Note that while it is possible to use Perl's stringify operator when
# doing the outer encryption (recall that just the key and counter are
# hashed), I want this code to be interoperable with a future C
# implementation. Thus in order to avoid needing to call sprintf on
# every such encryption, I will use a binary representation of the
# counter (in little-endian form, since that's what most machines
# are).
#
# There is only one other operation used in the transform, which is
# XORing blocks which are the same size as the hash. Again, since Perl
# doesn't do xoring of strings natively, we need something that's
# correct and "close to the metal".
#
# I could try to come up with routines here that exploit the largest
# native integer (whether it be 32 or 64 bit), and do XORs on those,
# but it's simpler to use a byte-oriented routine. If speed is an
# issue, all or part of the code can be replaced with XS routines that
# call native C implementations.

# Use closure-based objects that can be either a string (which can be
# passed to hash functions) or a list of numbers (which can be XORed).
# Note that this object doesn't explicitly keep both representations
# synchronised when something happens (ie, an XOR or an INC). That's
# up to the algorithm that uses these objects.

use constant STR_VALUE => 0;	# these two just pull out values
use constant NUM_ARRAY => 1;
use constant TO_STR => 2;	# these two do conversions
use constant TO_NUM => 3;
use constant INCR => 4;		# "INC" causes a clash (with @INC?)
use constant XOR => 5;

sub create_union {

    # always take in a string to start with
    my $str = shift;
    my @num = ( unpack "C*", $str ); # assume little-endian

    return [
	sub { $str },
	sub { \@num },
	sub { $str = pack "C*", @num },
	sub { @num = unpack "C*", $str; return \@num },
	sub { for my $pos (0 .. $#num) { # INCR assumes NUM up to date
	        last if ($num[$pos] = ($num[$pos] + 1) & 0xff);
	      }
	},
	sub { my $other = shift;         # as does XOR
	      for my $pos (0 .. $#num) {
		  # print "$pos: $num[$pos] ^= $other->[$pos]\n";
#		  if (DEBUG) {
		      die "XOR: first op unset\n" unless defined $num[$pos];
		      die "XOR: second op unset\n" unless defined $other->[$pos];
#		  }
		  $num[$pos] ^= $other->[$pos];
	      }
	}
    ];
}

# Test cases for "union" closures...
sub test_union {
    my $zero_string = "\0\0\0\0";
    my $one_string  = "\1\0\0\0"; # little-endian
    my $zero = create_union($zero_string);
    my $one  = create_union($one_string);

    # make sure that both string and number representations are set
    # correctly
    print "Zero string test: ";
    print "NOT " if  $zero_string ne $zero->[STR_VALUE]->();
    print "OK\n";
    print "One string test: ";
    print "NOT " if  $one_string ne $one->[STR_VALUE]->();
    print "OK\n";

    print "Zero number test: ";
    print "NOT " if  0 != $zero->[NUM_ARRAY]->()->[0];
    print "OK\n";
    print "One number test: ";
    print "NOT " if  1 != $one->[NUM_ARRAY]->()->[0];
    print "OK\n";

    # INCR should update num part, but not string
    print "Incrementing 'zero'\n";
    $zero->[INCR]->();
    print "Number part did ";
    print "NOT " if 1 != $zero->[NUM_ARRAY]->()->[0];
    print "increment as expected\n";
    print "String part ";
    if ($zero_string eq $zero->[STR_VALUE]->()) {
	print "unchanged (as expected)\n" ;
    } else { 
	print "UNEXPECTEDLY CHANGED\n";
    }

    # TO_NUM should undo the previous INCR
    print "Undoing increment on zero by calling TO_NUM\n";
    $zero->[TO_NUM]->();
    print "Call did ";
    print "NOT " if  0 != $zero->[NUM_ARRAY]->()->[0];
    print "revert properly\n";

    # INCR again, but this time call TO_STR to get the counter
    # containing 1 in both sides of union.
    print "Incrementing zero again, then calling TO_STR\n";
    $zero->[INCR]->();
    $zero->[TO_STR]->();
    print "(assume INCR works on number as we already tested this)\n";
    print "String side did ";
    print "NOT " if $one_string ne $zero->[STR_VALUE]->();
    print "get updated properly to 1\n";

    # Only thing left to test is XOR...
    my $lower_case = "lowercase";
    my $case_toggle = " " x length $lower_case;
    my $lc = create_union($lower_case);
    my $ct = create_union($case_toggle);

    print "Testing doing XOR: Expect '$lower_case' to toggle case below.\n";
    $lc->[XOR]->($ct->[NUM_ARRAY]->());
    # we must manually call TO_STR
    print $lc->[TO_STR]->() . "\n";

    print "Redoing toggle. Expect lower-case again:\n";
    $lc->[XOR]->($ct->[NUM_ARRAY]->());
    # we must manually call TO_STR
    print $lc->[TO_STR]->() . "\n";

    # Actually, have to check arithmetic too, specifically carries.
    # If this works, all other INCR cases should work (by induction).
    my $ff_byte = create_union(chr 255);
    my $ff_word = create_union(chr(255) . chr(0));

    print "Incrementing 0xff byte. Got back: ";
    $ff_byte->[INCR]->();
    print $ff_byte->[NUM_ARRAY]->()->[0] . "\n";
    
    print "Incrementing 0x00ff. Got back (little-endian/LSB first): ";
    $ff_word->[INCR]->();
    print join ", ", @{$ff_word->[NUM_ARRAY]->()};
    print "\n";
}


sub create_random_key {
}

# A note on allowed hash functions. In Rivest's paper, all the
# encryption steps take two parameters: a key and some text.
#
# As I understand this, the intention is to use a HMAC construction
# rather than simply appending the key and text material together.
#
# However, I would like to allow the user the flexibility to use
# either method. Therefore it seems best to take an encryption
# callback function from the user when they call the encode/decode
# functions...
#
# Of course, Perl being Perl, TMTOWTDI. I could also package this as a
# module had have all the details of which encryption function to use
# being set up in the constructor. Then the caller wouldn't need to
# pass the callback every time, but they would have to use the OO
# interface.
#
# Another possible problem here is that we don't know, a-priori, what
# the block size of the encryption routine is. For now, I'm just going
# to keep this as a script, but later I will package it up to make it
# usable in a few different modes.

# The following is just so that I can quickly print binary keys for
# debugging
use YAML::XS qw(Load Dump LoadFile DumpFile);

## Decoding
#
# Decoding is a two-step process. 
#
# The first step recovers the random key by iterating over all
# non-final blocks i using the public encryption key (K_P). For all i,
# it calculates:
#
# E(K_P, encrypted data block_i XOR i)
#
# The results of these these calculations are all XOR'd together and
# then XOR'd with the final block. This recovers K_R, the random key.
#
# Once the random key is recovered, a second pass is done over all
# non-final blocks to recover the original message blocks:
#
# message block_i = encrypted block_i XOR E(K_R, i)
#
# Rivest notes that each pass, individually, is open to a parallel
# implementation, but Perl sucks at real multi-threading, so we'll
# stick to a serial implementation here. A later C/XS implementation
# may be multi-threaded to take advantage of modern multi-core CPUs.

sub decode {

    my %opts = (
	blocksize => undef,
	e_callback => undef,
	message => undef,
	pubkey  => undef,
	,@_
    );

    die "Missing parameter 'pubkey'"     unless defined $opts{pubkey};
    die "Missing parameter 'blocksize'"  unless defined $opts{blocksize};
    die "Missing parameter 'message'"    unless defined $opts{message};
    die "Missing parameter 'e_callback'" unless defined $opts{e_callback};
 
    my ($blocksize, $e, $msg, $pub) =
	@opts{qw/blocksize e_callback message pubkey/};

    if (DEBUG) {
	print "decoding:\n";
	print "blocksize: $blocksize\n";
	print "e: $e\n";
	print "pub: $pub\n";
    }

    # if pubkey isn't the same length as blocksize, we can probably do
    # the following, but it's really up to the user's implementation
    # of the e_callback:
    if (length $pub != $blocksize) {
	warn "upgrading pubkey by encrypting it using supplied function\n" 
	    if DEBUG;
	$pub = $e->("", $pub);
	die "Well that failed ..." if length $pub != $blocksize;
    }

    # Pass 1... recover the embedded random key
    #

    # the algorithm uses 1-based block indexing, but we want a
    # separate native 0-based iterator for calculating substr indexes
    my $i=0;
    my $one_string = "\01" . ("\0" x ($blocksize - 1));
    my $iu = create_union($one_string);
    my $blocks = (length $msg) / $blocksize; --$blocks;

    # Pre-XOR (and remove) the final block into the random key 
    my $rndu = create_union(substr $msg, -$blocksize,$blocksize,"");

    while ($i < $blocks) {

	my $blk = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with i, and XOR its encryption into rndu
	my $blk_u = create_union($blk);
	$blk_u->[XOR]->($iu->[NUM_ARRAY]->());
	$rndu->[XOR]->([unpack "C*",$e->($pub,$blk_u->[TO_STR]->())]);

    } continue {
	++$i;
	$iu->[INCR]->();
	$iu->[TO_STR]->();
    }

    # convert/extract $rndu
    my $rnd = $rndu->[TO_STR]->();
    
    if (DEBUG) {
	# Debug: print random key to check with what encode() created
	print "Decode rnd key: " . (Dump $rnd) . "\n";
    }

    # Pass 2... decode the blocks using extracted random key
    ($i,$iu) = (0, create_union($one_string));
    while ($i < $blocks) {

	my $blk = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with E(K_R,i)
	my $blku = create_union($blk);
	
	$blku->[XOR]->([unpack "C*", $e->($rnd,$iu->[TO_STR]->())]);

	# save the string version back into the message (completes XOR)
	substr $msg, $i * $blocksize, $blocksize, $blku->[TO_STR]->();

    } continue {
	++$i;
	$iu->[INCR]->();
    }

    return $msg;
}

## Encoding
#
# There are two operations, but they can be done in one pass 
# 

sub encode {

    my %opts = (
	blocksize => undef,
	e_callback => undef,
	message => undef,
	pubkey  => undef,
	rndkey  => undef, 	# not usually passed, but good for testing
	,@_
    );

    die "Missing parameter 'pubkey'"     unless defined $opts{pubkey};
    die "Missing parameter 'blocksize'"  unless defined $opts{blocksize};
    die "Missing parameter 'message'"    unless defined $opts{message};
    die "Missing parameter 'e_callback'" unless defined $opts{e_callback};
 
    my ($blocksize, $e, $msg, $pub, $rnd) =
	@opts{qw/blocksize e_callback message pubkey rndkey/};

    if (DEBUG) {
	print "encoding:\n";
	print "blocksize: $blocksize\n";
	print "e: $e\n";
	print "pub: $pub\n";
    }

    # if pubkey isn't the same length as blocksize, we can probably do
    # the following, but it's really up to the user's implementation
    # of the e_callback:
    if ($blocksize != length $pub) {
	warn "upgrading pubkey by encrypting it using supplied function\n"
	    if DEBUG;
	$pub = $e->("", $pub);
	die "Well that failed ..." if length $pub != $blocksize;
    }

    # We're usually not passed a rndkey, but if we are, we should
    # allow it to be upgraded, as with the pubkey above
    if (defined $rnd) {
	if (length $rnd != $blocksize) {
	    warn "upgrading rndkey by encrypting it using supplied function\n";
	    $rnd = &$e->("", $rnd);
	    die "Well that failed ...\n" if length $rnd != $blocksize;
	}
    } else {
	# generate a random key (poor quality; FIXME later)
	$rnd = join "", map { chr rand 256 } 1 .. $blocksize;	
    }

    if (DEBUG) {
	# Debug: dump random key in readable format
	print "Encode rnd key: " . (Dump $rnd) . "\n";
    }

    # Make sure that message is an even number of blocks long
    die "Make the message a multiple of blocksize\n" 
	if (length $msg) % $blocksize;

    # pre-allocating the output string is probably slightly faster
    # than appending all the time (I think)
    #    my $os = "\0" x length $msg;
    # Actually, we can do in-place substitution of the input string

    # the algorithm uses 1-based block indexing, but we want a
    # separate native 0-based iterator for calculating substr indexes
    my $i=0;
    my $one_string = "\01" . ("\0" x ($blocksize - 1));
    my $iu = create_union($one_string);
    
    my $blocks = (length $msg) / $blocksize;

    # while the string "$rnd" above is fine for passing to the
    # encryption callback, we'll also need a copy of it that we can do
    # XORs on. This eventually gets appended to the end of the file.
    my $rndu = create_union($rnd);

    # Go and do the algorithm
    while ($i < $blocks) {

	my $blk = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with the random encryption of itself
	my $blk_r = $e->($rnd,$iu->[STR_VALUE]->());

	# neither the original block nor the result of the encryption
	# have been upgraded to the union structure yet. We just have
	# to upgrade one of them and the other is handled by unpack.
	my $blk_ru = create_union($blk_r);
	$blk_ru->[XOR]->([unpack "C*", $blk]);

	# save the string version back into the message (completes XOR)
	substr $msg, $i * $blocksize, $blocksize, $blk_ru->[TO_STR]->();

	# The result of this is also used to further encrypt the
	# random key that will be appended to the file...  But first,
	# we must XOR blk_ru with i to get the message part of the
	# second encryption:
	$blk_ru->[XOR]->($iu->[NUM_ARRAY]->());

	# then update (XOR) the final block with the result of the
	# second encryption:
	$rndu->[XOR]->([unpack "C*", $e->($pub,$blk_ru->[TO_STR]->())]);
    } continue {
	++$i;
	$iu->[INCR]->();
	$iu->[TO_STR]->();
    }

    # append the encrypted random key and return
    return $msg . $rndu->[TO_STR]->();
}   

# Test everything with HMAC_MD5...

use Digest::MD5 qw(md5_hex);
use Digest::HMAC_MD5 qw(hmac_md5 hmac_md5_hex);

# For the two main algorithm test subs (test_hmac_md5 and test_aes),
# we will want to allow individual testing of encoder or decoder, or
# both together. In the decoder-only test, we just generate random
# data to work on.

my %test_modes = ( map { $_ => undef } qw/enc_only dec_only encdec/ );

sub test_hmac_md5 {
    my $v    = shift || 2;
    my $mode = shift || "encdec";

    die "test_hmac_md5: unknown mode $mode\n"
	unless exists $test_modes{$mode};

    my $encoder = (1 == $v) ? \&encode : \&encode_v2;
    my $decoder = (1 == $v) ? \&decode : \&decode_v2;
    
    my $msg_size = 8192;
    my $msg = "\0" x $msg_size;
    my $callback = sub { hmac_md5($_[1],$_[0]) };
    my $bytes = 128/8;
    my ($orig_hash, $aont, $decoded, $decoded_hash);

    print "Testing HMAC_MD5 with v$v codec ($mode)\n";

    print "Message size is $msg_size bytes\n";

    if ($mode =~ m/enc/) {
	$orig_hash = md5_hex($msg);
	print "Original message digest: $orig_hash\n";
	$aont = $encoder->(
	    message => $msg,
	    e_callback => $callback,
	    pubkey => "test",
	    blocksize => $bytes);
    } else {
	print "Original message digest: none (random decode)\n";
	# just add an extra block of data
	$aont = $msg . ("\0" x $bytes);
    }

    my $enc_hash = md5_hex($aont);
    print "Encoded message length: " . (length $aont) . "\n";
    print "Encoded message digest: $enc_hash\n";

    if ($mode =~ m/dec/) {
	$decoded = $decoder->(
	    message => $aont,
	    e_callback => $callback,
	    pubkey => "test",
	    blocksize => $bytes);
	
	$decoded_hash = md5_hex($decoded);
	print "Recovered message digest: $decoded_hash\n";
	die "recovered message digest mismatch\n"
	    if defined($orig_hash) and $orig_hash ne $decoded_hash;

	print "Running decoder 1023 more time(s)...\n";
	
	for (1..1023) {
	    $decoded = $decoder->(
		message => $aont,
		e_callback => $callback,
		pubkey => "test",
		blocksize => $bytes);
	    $decoded_hash = md5_hex($decoded);
	    die "recovered message digest mismatch\n"
		if defined($orig_hash) and $orig_hash ne $decoded_hash;
	}
	
	print "Done HMAC_MD5 test!\n";
    } else {
	print "Skipping decode in $mode mode\n";
    }
    
}

# I was trying to get things working with various different encryption
# algorithms but the files that were being returned ended up being
# larger than the input. It might still be possible to make this work
# (if the inflation factor/number of extra bytes is consistent) but
# that would involve changing the internals of the encode/decode
# algorithms to account for two different block sizes. I don't want to
# do that... at least not right now.
#
# 

# Now test an 8Mb message with AES and block size of 1024

use Crypt::GCrypt;

sub test_aes {
    my $v    = shift || 2;
    my $mode = shift || "encdec";

    die "test_hmac_md5: unknown mode $mode\n"
	unless exists $test_modes{$mode};

    my $encoder = (1 == $v) ? \&encode : \&encode_v2;
    my $decoder = (1 == $v) ? \&decode : \&decode_v2;
    
    my $msg_size = 8 * 1024 * 1024;
    my $msg = "\0" x $msg_size;
    my $callback;
    my $bytes = 1024;
    my ($orig_hash, $aont, $decoded, $decoded_hash);

    print "Testing AES on an 8Mb block with v$v decoder ($mode)\n";

    # same cipher/callback used in encode/decode
    my $cipher = Crypt::GCrypt->new(
	type => 'cipher',
	algorithm => 'aes',
	mode => 'cbc'
    );

    # After debugging, I think that there's a bug in Crypt::GCrypt
    $callback = sub { 
	my ($key, $data) = @_;
	my $keylen  = length $key;
	my $datalen = length $data;
	if (0) {
	    warn "key size $keylen, data size $datalen\n";
	    warn "Chosen algorithm requires key length " . $cipher->keylen() .
		" and block size " . $cipher->blklen() . "\n";
	}
	$cipher->start('encrypting');
	$cipher->setkey($key);
	my $output = $cipher->encrypt($data);
	my $finish_bit = $cipher->finish; # BUG (see below)

	# There seems to be a bug in the Crypt::GCrypt module in how it
	# handles "finish". It seems that if the output from "encrypt" is
	# an even multiple of the block size, then calling "finish" will
	# output an extra block instead of nothing. This can be worked
	# around by checking the size of the data returned from encrypt
	# and only calling finish if it is not a multiple of the block
	# size. I haven't tested this workaround in all cases, though. All
	# I have done here is simply call encrypt, with the assumption
	# that the data size is a multiple of the block size.
	
	warn "finish bit is " . (length $finish_bit) . " bytes \n" if 0;
    
	my $len = length $output;
	die "Encryption output of wrong size (got $len, expected $bytes)\n"
	    unless $len == $bytes;
	# ignore output of ->finish() for now.
	return $output;
    };

    if (0) {
	# test callback on sample blocks (to debug above)
	my $short_key = "\0" x $cipher->keylen;
	my $sample_block = "\0" x $bytes;
	$callback->($short_key,$sample_block);
	
	my $sample_key = "\0" x $bytes;
	my $sample_data = $sample_key;
	$callback->($sample_key,$sample_data);
    }

    if ($mode =~ m/enc/) {

	print "Doing encode...\n";
	
	print "Message size is $msg_size bytes\n";
	$orig_hash = md5_hex($msg);
	print "Original message digest: $orig_hash\n";

	$aont = $encoder->(
	    message => $msg,
	    e_callback => $callback,
	    pubkey => "test" x (1024 / 4),
	    # pubkey => "AES keys >= 20-chars",   # FIXME
	    blocksize => $bytes);
    } else {
	print "Skipping encode (random decode)\n";
	# just add an extra block of data
	$aont = $msg . ("\0" x $bytes);
    }

    my $enc_hash = md5_hex($aont);
    print "Encoded message digest: $enc_hash\n";

    if ($mode =~ m/dec/) {
	$decoded = $decoder->(
	    message => $aont,
	    e_callback => $callback,
	    pubkey => "test" x (1024 / 4),
	    # pubkey => "AES keys >= 20-chars",
	    blocksize => $bytes);

	$decoded_hash = md5_hex($decoded);
	print "Recovered message digest: $decoded_hash\n";
	die "recovered message digest mismatch\n"
	    if defined($orig_hash) and $orig_hash ne $decoded_hash;
    } else {
	print "Skipping decode in $mode mode\n";
    }
}

## Version 2
#
# After verifying that the algorithm above works, I benchmarked and
# profiled the code. Firstly, it's clear that it's not fast enough to
# be practical enough for most real-world uses. The second thing is
# that the "union" abstraction is too inefficient. It was useful for
# writing the first prototype and proving that the algorithm works as
# intended, but it will have to go in the next version.
#
# Profiling showed that the top-level decode algorithm was taking a
# lot of time. Although it's not quite clear from the profile which
# operations were particularly slowing it down (especially given that
# some lines could have up to 4 distinct operations rolled up
# together), it seems that the calling overheads of the "union"
# structure was one main source of inefficiency (even using the
# normally quite efficient closure approach, and using constant array
# indexes to refer to the operations rather than hash-based
# dereferences). The overheads in the decode routine were particularly
# noticeable in the SHA test since there were many more blocks to
# iterate over.
#
# The other main inefficiency was in the XOR routine. This was most
# striking in the AES test.
#
# For version 2, we'll implement the same algorithm without using the
# union abstraction. All things being operated on will be stored as
# native Perl strings, and we'll add two routines that do things we
# normally can't do on native strings in Perl, namely:
#
# * XOR
# * INCR
#
# I already have a couple of implementations of XOR (one pure Perl,
# the other a C routine that's callable from Perl), while the INCR
# routine can be just implemented in Perl to begin with. If it turns
# out to be too inefficient, I can write a C version of that, too.
#
# Summary of benchmarks for v1 decoding 8Mb of data:
#
# 23s using HMAC_MD5 (16-byte blocks)  [main bottleneck: decode]
# 15s using AES (1024-byte blocks)     [main bottleneck: XOR]
#

# Get access to safe_xor_strings (pure Perl) or fast_xor_strings (C)
# routines. C version should have automatically compiled to use the
# largest-supported native int during Net::OnlineCode installation.
use Net::OnlineCode ':xor';

# No need to re-implement encode just yet
# sub encode_v2 {}

sub incr {
    my $strref = shift;
    my $strlen = shift;

    # TOTEST: it might be quicker to do length($$strref) here rather
    # than passing $strlen every call. Then again, it might not be.

    # assume that caller won't pass zero-length strings by accident
    # (if they do, the do/while below will fail noisily)
    die unless $strlen;
    return if DEBUG and !$strlen;

    my ($i, $ord) = (0);
    do {
	$ord = (ord (substr $$strref, $i, 1) + 1) & 0xff;
	substr $$strref, $i, 1, chr $ord;
	return if $ord;
    } while (++$i < $strlen);
}

# Use the same parameters as original decode()
sub decode_v2 {
    my %opts = (
	blocksize => undef,
	e_callback => undef,
	message => undef,
	pubkey  => undef,
	,@_
    );

    die "Missing parameter 'pubkey'"     unless defined $opts{pubkey};
    die "Missing parameter 'blocksize'"  unless defined $opts{blocksize};
    die "Missing parameter 'message'"    unless defined $opts{message};
    die "Missing parameter 'e_callback'" unless defined $opts{e_callback};
 
    my ($blocksize, $e, $msg, $pub) =
	@opts{qw/blocksize e_callback message pubkey/};

    if (DEBUG) {
	print "decoding:\n";
	print "blocksize: $blocksize\n";
	print "e: $e\n";
	print "pub: $pub\n";
    }

    # if pubkey isn't the same length as blocksize, we can probably do
    # the following, but it's really up to the user's implementation
    # of the e_callback:
    if (length $pub != $blocksize) {
	warn "upgrading pubkey by encrypting it using supplied function\n" 
	    if DEBUG;
	$pub = $e->("", $pub);
	die "Well that failed ..." if length $pub != $blocksize;
    }

    # Pass 1... recover the embedded random key
    #

    # Stick with the same variable naming convention, with the suffix
    # "u" denoting something that's a "union" of a string/number
    my $i=0;
    my $one_string = "\01" . ("\0" x ($blocksize - 1));
    my $iu = $one_string;
    my $blocks = (length $msg) / $blocksize; --$blocks;

    # Pre-XOR (and remove) the final block into the random key 
    my $rndu = substr $msg,-$blocksize,$blocksize,"";

    while ($i < $blocks) {

	my $blku = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with i, and XOR its encryption into rndu
	fast_xor_strings(\$blku, $iu);
	fast_xor_strings(\$rndu, $e->($pub,$blku));

    } continue {
	++$i;
	incr(\$iu,$blocksize);
    }

    # convert/extract $rndu
    my $rnd = $rndu;
    
    if (DEBUG) {
	# Debug: print random key to check with what encode() created
	print "Decode rnd key: " . (Dump $rnd) . "\n";
    }

    # Pass 2... decode the blocks using extracted random key
    ($i,$iu) = (0,$one_string);
    while ($i < $blocks) {

	my $blku = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with E(K_R,i)
	#my $blku = create_union($blk);
	
	fast_xor_strings(\$blku, $e->($rnd,$iu));

	# save the string version back into the message (completes XOR)
	substr $msg, $i * $blocksize, $blocksize, $blku;

    } continue {
	++$i;
	incr(\$iu,$blocksize);
    }

    return $msg;
}

sub test_incr {

    my ($zero,$one,$ff) = ("\0","\1",chr 255);
    incr(\$zero,1);
    die "0 + 1 != 1\n" unless $zero eq $one;
    incr(\$ff,1);
    incr(\$ff,1);
    die "0xff byte + 2 != 1\n" unless $ff eq $one;

    # do word-value tests (little-endian)
    my ($w0,$w1,$wff,$w100) = ("\0\0","\1\0","\377\0","\0\1");
    incr(\$w0,2);
    # print Dump $w0;
    die "0000 + 0001 != 0001\n" unless $w0 eq $w1;
    incr(\$wff,2);
    die "00ff + 0001 != 0100\n" unless $wff eq $w100;
}

#test_incr();
#test_hmac_md5(1);
#test_hmac_md5(2);
#test_aes(1);
#test_aes(2);

# Benchmarks after writing v2 decoder (8MB of data)
#
# hmac_md5  v1  25.825s  25.681s  25.937s
# hmac_md5  v2   5.397s   5.314s   4.778s
# aes       v1  15.032s  15.038s  14.994s
# aes       v2   7.366s   7.456s   7.357s
#
# All of these include a call to the old v1 encoder.
#
# Profiling info (nytprof) for runs with v2 decoder...
#
# hmac_md5 total run time 24.7s (of 31.7s)
#
# Top routines (excl time, incl time, routine):
#
# 8.89s   24.50s     decode_v2
# 5.60s    7.07s     Digest::HMAC::hmac
# 2.70s    9.77s     Digest::HMAC_MD5::hmac_md5
# 2.59s   12.40s     anon [e_callback]
# 2.43s    2.43s     incr
# 1.47s    1.47s     Digest::MD5::md5 (xsub)
#
# aes total run time 16.5s (of 36.4s)
#
# Top routines (excl time, incl time, routine):
# 13.30s   13.3s      anon [encode XOR]
#  1.16s   16.0s      encode
#
# In the AES result, most of the time is spent in encoding the file. I
# would have to rerun the tests with the encoding part elminated to
# get more accurate timing/profiling information here.
#
# I will do that by adding options to the two test routines.


# the decode-only tests generate dummy input data
if ("Exhaustive profile test" eq "set equal to enable") {
    test_hmac_md5(1,"enc_only");
    test_hmac_md5(2,"enc_only");
    test_aes(1,"enc_only");
    test_aes(2,"enc_only");
    test_hmac_md5(1,"dec_only");
    test_hmac_md5(2,"dec_only");
    test_aes(1,"dec_only");
    test_aes(2,"dec_only");
}

# By doing all the above in the same run of the program, we can look
# at the profile data to compare the inclusive time of each line...
#
# aont.pl: NYTProf total runtime 147s (of 244s)
#
#    V1    | Encode | Decode        V2    | Encode | Decode      
#  --------+--------+--------     --------+--------+--------     
#  HMAC_MD5| 58.1ms | 73.6s       HMAC_MD5| 57.6ms | 25.0s
#  AES     | 15.6s  | 16.5s       AES     | 15.7s  | 484ms
#
# Next, test without the overheads of the profiler ...

use Benchmark qw/:all :hireswallclock/;

if (0) {
    cmpthese(10, {
	hmc_v1_enc => 'test_hmac_md5(1,"enc_only")',
	hmc_v2_enc => 'test_hmac_md5(2,"enc_only")',
	aes_v1_enc => 'test_aes(1,"enc_only")',
	aes_v2_enc => 'test_aes(2,"enc_only")',
	hmc_v1_dec => 'test_hmac_md5(1,"dec_only")',
	hmc_v2_dec => 'test_hmac_md5(2,"dec_only")',
	aes_v1_dec => 'test_aes(1,"dec_only")',
	aes_v2_dec => 'test_aes(2,"dec_only")',
	     });
}

# At this point, I will implement a v2 encoder, if for no other reason
# but to save time when running benchmarks...

sub encode_v2 {
    my %opts = (
	blocksize => undef,
	e_callback => undef,
	message => undef,
	pubkey  => undef,
	rndkey  => undef, 	# not usually passed, but good for testing
	,@_
    );

    die "Missing parameter 'pubkey'"     unless defined $opts{pubkey};
    die "Missing parameter 'blocksize'"  unless defined $opts{blocksize};
    die "Missing parameter 'message'"    unless defined $opts{message};
    die "Missing parameter 'e_callback'" unless defined $opts{e_callback};
 
    my ($blocksize, $e, $msg, $pub, $rnd) =
	@opts{qw/blocksize e_callback message pubkey rndkey/};

    if (DEBUG) {
	print "encoding:\n";
	print "blocksize: $blocksize\n";
	print "e: $e\n";
	print "pub: $pub\n";
    }

    # if pubkey isn't the same length as blocksize, we can probably do
    # the following, but it's really up to the user's implementation
    # of the e_callback:
    if ($blocksize != length $pub) {
	warn "upgrading pubkey by encrypting it using supplied function\n"
	    if DEBUG;
	$pub = $e->("", $pub);
	die "Well that failed ..." if length $pub != $blocksize;
    }

    # We're usually not passed a rndkey, but if we are, we should
    # allow it to be upgraded, as with the pubkey above
    if (defined $rnd) {
	if (length $rnd != $blocksize) {
	    warn "upgrading rndkey by encrypting it using supplied function\n";
	    $rnd = &$e->("", $rnd);
	    die "Well that failed ...\n" if length $rnd != $blocksize;
	}
    } else {
	# generate a random key (poor quality; FIXME later)
	$rnd = join "", map { chr rand 256 } 1 .. $blocksize;	
    }

    if (DEBUG) {
	# Debug: dump random key in readable format
	print "Encode rnd key: " . (Dump $rnd) . "\n";
    }

    # Make sure that message is an even number of blocks long
    die "Make the message a multiple of blocksize\n" 
	if (length $msg) % $blocksize;

    # pre-allocating the output string is probably slightly faster
    # than appending all the time (I think)
    #    my $os = "\0" x length $msg;
    # Actually, we can do in-place substitution of the input string

    # ---start of new/changed code---

    # use the "u" suffix to indicate where we were using "unions"
    my $i=0;
    my $one_string = "\01" . ("\0" x ($blocksize - 1));
    my $iu = $one_string;

    my $blocks = (length $msg) / $blocksize;
    my $rndu = $rnd; # the block that will get appended

    # Go and do the algorithm
    my ($blk,$blk_ru,$blk_pu);
    my ($safe,$fast);
    while ($i < $blocks) {

	$blk = substr $msg, $i * $blocksize, $blocksize;

	# XOR this block with the random encryption of itself
	$blk_ru = $e->($rnd,$iu);
	fast_xor_strings(\$blk_ru,$blk);

	# save the string version back into the message (completes XOR)
	substr $msg, $i * $blocksize, $blocksize, $blk_ru;

	# The result of this is also used to further encrypt the
	# random key that will be appended to the file...  But first,
	# we must XOR blk_ru with i to get the message part of the
	# second encryption:
	fast_xor_strings(\$blk_ru,$iu);

	# then update (XOR) the final block with the result of the
	# second encryption:
	$blk_pu=$e->($pub,$blk_ru);
	die unless $blocksize == length $rndu;
	die unless $blocksize == length $blk_pu;

	# is failing here when using fast_xor_strings...
	#fast_xor_strings(\$rndu,$blk_pu);
	safe_xor_strings(\$rndu,$blk_pu);
	next;	

	# debug the above problem (XS library bug?)
	$safe = $fast = $rndu;
	fast_xor_strings(\$fast,$blk_pu);
	safe_xor_strings(\$safe,$blk_pu);
	unless ($safe eq $fast) {
	    print "i   : " . Dump $i;
	    print "rndu: " . Dump $rndu;
	    print "bkpu: " . Dump $blk_pu;
	    print "safe: " . Dump $safe;
	    print "fast: " . Dump $fast;
	    warn "encode_v2: safe/fast mismatch\n" 
	}
	$rndu=$safe;
    } continue {
	++$i;
	incr(\$iu,$blocksize);
    }

    # append the encrypted random key and return
    return $msg . $rndu;

}

#test_hmac_md5(1,"encdec");
test_hmac_md5(2,"encdec");
#test_aes(1);
test_aes(2);

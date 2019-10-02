#!/usr/bin/env perl

use strict;
use warnings;

use v5.20;

my $debug = 0;

use Inline 'C';

use Carp;

use IO::All;

# I have an implementation of GF(2**8)
use Math::FastGF2 qw/:ops/;
use Math::FastGF2::Matrix;

# I also have an implementation of fast XOR on strings
use Net::OnlineCode ':xor';

use Getopt::Long;

# General options that don't affect algorithm
my $infile    = undef;
my $blocksize = 32;
my $verbose   = 0;
my $hacky     = 0;
my $packets   = 0;		# 0   -> run until decoded;
                                # +ve -> stop after this many packets
my $test_what = '';		# run internal tests

# Algorithm-specific stuff
my $q         = 2;   		# default to GF(2) == GF(2**1);
my $alpha     = 8;		# aperture size alpha
my $gen       = 32;

# Random number stuff
my $deterministic = 0;		# whether to use a predictable seed
my $seed = undef;

GetOptions ("blocksize=i"       => \$blocksize,
	    "q|field=i"         => \$q,
	    "packets=i"         => \$packets,
	    "alpha|aperture=i"  => \$alpha,
	    "infile=s"          => \$infile,
	    "test=s"            => \$test_what,
	    "verbose"           => \$verbose,
	    "hacky"             => \$hacky,
	    "seed=i"            => \$seed,
	    "generation=i"      => \$gen,
	    "deterministic"     => \$deterministic)
    or die("Error in command line arguments\n");

# Check command-line arguments

# Later, I might implement F_16, though I'm not sure that it would be
# any faster than F_256. It would rely on assembler optimisations,
# specifically doing in-register lookups on the log table, anyway, but
# it might still need memory lookup for exp...
die "Field must be 2 or 256\n" if ($q != 2 and $q != 256);

# Alpha has a max of gen - 1:
die "Aperture too big!\n" if $alpha >= $gen;

# Strictly speaking, setting a seed is deterministic, but I use
# --deterministic to indicate using a fixed seed of 0.
die "Incompatible options --seed and --deterministic\n"
    if $deterministic and defined $seed;

$seed = 0 if $deterministic;
if (defined($seed)) {
    $seed = srand($seed);
} else {
    $seed = srand;
}

die "Must specify an input file with --infile\n"
    unless defined $infile;

# File I/O: read in $gen blocks of size $blocksize
my ($fh, @message);
open $fh, "<", "$infile" or die "Failed to open input file: $!\n";
for (0 .. $gen-1) {
    my $block = '';
    my $got_bytes =  read $fh, $block, $blocksize;
    die "Error reading: $!\n" unless defined($got_bytes);
    if ($got_bytes != 0) {
	die "Got fewer than $blocksize bytes from file (error '$!')"
	    unless $blocksize == $got_bytes;
    }
    push @message, $block;
}

# How many bits does q represent?
my $qbits = log($q) / log(2);

# Make working with full bytes/words a requirement:
die "Alpha times bits(field) must be a multiple of 8 bits\n" 
    if $alpha * $qbits % 8;


my $zero_code  = "\0" x ($alpha * $qbits >> 3);
my $zero_block = "\0" x $blocksize; # independent of alpha, gen, q

# Simulate a square matrix of size $gen
my @filled = ((0) x $gen);
my @coding = ();
my @symbol = ();
my $remain = $gen;
my @pivot_queue = ();

# Forward declaration of subs
sub encode_block_f2;
sub encode_block_f256;
sub solve_f2;
sub solve_f256;
sub codec_f2;
sub codec_f256;

# Tests available from command line as '--test <what>'
my %valid_tests = map { $_ => undef } qw(
   vec_mul solve_f2 codec_f2 vec_clz vec_ctz vec_shl codec_f256
   gf256_maths
);

if ($test_what) {
    unless (exists $valid_tests{$test_what}) {
	warn "Invalid test $test_what\n";
	warn "Select from: " . (join ", ", sort keys %valid_tests) . "\n";
	exit 1;
    }
    if ($test_what eq "gf256_maths") {
	my ($a,$b) = (0x53, 0xca);
	my $one = gf256_mul_elems($a,$b);
	die "Expected 53 x ca == 1 (got $one)" unless $one == 0x01;
	$one = gf256_inv_elem(0x01);
	die "Expected inv(1) == 1 (got $one)" unless $one == 0x01;
	my $inv = gf256_inv_elem(0x53);
	die "Expected inv(53) == ca (got $one)" unless $inv == 0xca;
	$inv = gf256_inv_elem(0xca);
	die "Expected inv(ca) == 53 (got $one)" unless $inv == 0x53;
	
	print "Looks OK\n";
	exit 0;
    } elsif ($test_what eq "vec_clz") {
	my @ones = map { chr } qw(128 64 32 16 8 4 2 1);
	my $zero = chr 0;
	for my $leading (0..2) {
	    for my $trailing (0..2) {
		for my $one_byte (0..7) {
		    my $s = $zero x $leading;
		    $s.= $ones[$one_byte];
		    $s.= $zero x $trailing;
		    my $count = vec_clz($s);
		    my $expect = $leading * 8 + $one_byte;
		    next if $count == $expect;
		    warn "Failed: vec_clz wrong for leading $leading, ".
			"bit position $one_byte, trailing $trailing\n";
		    die "Got $count, expected $expect\n";
		}
	    }
	}
	
    } elsif ($test_what eq "vec_ctz") {
	my @ones = map { chr } qw(1 2 4 8 16 32 64 128);
	my $zero = chr 0;
	for my $leading (0..2) {
	    for my $trailing (0..2) {
		for my $one_byte (0..7) {
		    my $s = $zero x $leading;
		    $s.= $ones[$one_byte];
		    $s.= $zero x $trailing;
		    my $count = vec_ctz($s);
		    my $expect = $trailing * 8 + $one_byte;
		    next if $count == $expect;
		    warn "Failed: vec_ctz wrong for leading $leading, ".
			"bit position $one_byte, trailing $trailing\n";
		    die "Got $count, expected $expect\n";
		}
	    }
	}
    } elsif ($test_what eq "vec_shl") {
	# The easiest way to test this is by building up strings by
	# hand, then testing various b values. Note that 0x55 and 0xaa
	# are rotations (inverses) of each other, so the pattern is
	# ...0101010101010101...
	my @strings = (
	    "\x00\xAA\xAA\x00\x00\x01",
	    "\x01\x55\x54\x00\x00\x02",
	    "\x02\xAA\xA8\x00\x00\x04",
	    "\x05\x55\x50\x00\x00\x08",

	    "\x0A\xAA\xA0\x00\x00\x10",
	    "\x15\x55\x40\x00\x00\x20",
	    "\x2A\xAA\x80\x00\x00\x40",
	    "\x55\x55\x00\x00\x00\x80",

	    # Pattern repeats, after shifting one byte over
	    "\xAA\xAA\x00\x00\x01\x00",
	    "\x55\x54\x00\x00\x02\x00",
	    "\xAA\xA8\x00\x00\x04\x00",
	    "\x55\x50\x00\x00\x08\x00",

	    "\xAA\xA0\x00\x00\x10\x00",
	    "\x55\x40\x00\x00\x20\x00",
	    "\xAA\x80\x00\x00\x40\x00",
	    "\x55\x00\x00\x00\x80\x00",

	    # Pattern repeats, after shifting one byte over
	    "\xAA\x00\x00\x01\x00\x00",
	    "\x54\x00\x00\x02\x00\x00",
	    "\xA8\x00\x00\x04\x00\x00",
	    "\x50\x00\x00\x08\x00\x00",

	    "\xA0\x00\x00\x10\x00\x00",
	    "\x40\x00\x00\x20\x00\x00",
	    "\x80\x00\x00\x40\x00\x00",
	    "\x00\x00\x00\x80\x00\x00",

	    # Pattern repeats, after shifting one byte over
	    "\x00\x00\x01\x00\x00\x00",
	    "\x00\x00\x02\x00\x00\x00",
	    "\x00\x00\x04\x00\x00\x00",
	    "\x00\x00\x08\x00\x00\x00",

	    "\x00\x00\x10\x00\x00\x00",
	    "\x00\x00\x20\x00\x00\x00",
	    "\x00\x00\x40\x00\x00\x00",
	    "\x00\x00\x80\x00\x00\x00",

	);
	for my $bits (0,8,0,8,1,1..16) {
	    die unless @strings == 32;
	    for my $start (0.. @strings -2) {
		last if $start + $bits >= @strings;
		# Weirdly, you need to explicitly stringify below:
		my $str = "$strings[$start]";
		my $old = unpack "H12", $str;
		vec_shl($str, $bits);
		my $expect = $strings[$start + $bits];
		if ($str ne $expect) {
		    $str = unpack "H*", $str;
		    $expect = unpack "H*", $expect;
		    warn "vec_shl: wrong output for start $start, bits $bits\n";
		    warn "Expected $old << $bits = $expect; got $str\n";
		}
	    }
	}

    } elsif ($test_what eq "vec_mul") {
	my $str = "CamelCase";
	my $nul = "\0" x length($str);
	gf256_vec_mul($str,"\001");	# in-place update!
	die "gf256_vec_mul identity failed (got '$str')\n" if $str ne 'CamelCase';
	gf256_vec_mul($str,"\0");
	die "gf256_vec_mul zero failed (got '$str')\n" if $str ne $nul;
	print "vec_mul tests passed\n";

    } elsif ($test_what eq "solve_f2") {
	solve_f2;

    } elsif ($test_what eq "codec_f2") {
	codec_f2;

    } elsif ($test_what eq "codec_f256") {
	codec_f256;
    }

    exit;
}

# default test... just generate packets, but don't try to decode
if ($packets) {
    my ($i, $vec, $sym);
    print "Benchmarking encode_block_f2.\n";
    print "Generating $packets packets equivalent to ",
    ($packets * $blocksize), " bytes\n";
    while ($packets--) {
	if ($qbits == 1) {
	    ($i, $vec, $sym) = encode_block_f2;
	} else {
	    ($i, $vec, $sym) = encode_block_f256;
	}
    }
    print "All packets produced\n";
    exit (0);
}
sub check_symbol_f2;
# Loop producing packets until message decoded fully into @symbol
sub codec_f2 {
    my ($rp, $matched) = (0,0);
    warn "Seed: $seed\n";
    my @msg = @message;
    my ($in,$out);
    while (1) {
	my ($i, $code, $sym);
	if (@pivot_queue) {
	    my $new = shift @pivot_queue;
	    ($i, $code, $sym) = @{$new};
	    warn "Re-pivoting\n";
	} else {
	    ($i, $code, $sym) = encode_block_f2();
	    ++$rp;		# received packets
	}
	check_symbol_f2($i,$code,$sym) if $debug>1;
	if (pivot_f2($i, "$code", "$sym") == 0) {
	    warn "Trying to solve\n";
	    last if solve_f2() == 0;
	    warn "After initial solve, need to go again\n";
	    $matched = 0;
	    for (0 .. $gen-1) {
		++$matched if $msg[$_] eq $symbol[$_];
	    }
	    # Check for corruption of original array
	    for (0 .. $gen-1) {
		die unless $msg[$_] eq $message[$_];
	    }
	    warn "Matched $matched source <=> decoded blocks\n";
	}
    };
    warn "Fully decoded after $rp packets\n";
    $matched = 0;
    for (0 .. $gen-1) {
	++$matched if $msg[$_] eq $symbol[$_];
    }
    # Check for corruption of original array
    for (0 .. $gen-1) {
	die unless $msg[$_] eq $message[$_];
    }
    warn "Matched $matched source <=> decoded blocks";
    if ($debug) {
	$in  = unpack("H*", $message[0]);
	$out = unpack("H*", $symbol[0]);
	warn "Input block 0 was $in\n";
	warn "Output block 0 was $out\n";
	$in  = unpack("H*", $message[$gen - 1]);
	$out = unpack("H*", $symbol[$gen - 1]);
	warn "Input block $gen-1 was $in\n";
	warn "Output block $gen-1 was $out\n";
    }
    exit;
}

sub check_symbol_f256;
sub codec_f256 {
    my ($rp, $matched) = (0,0);
    warn "Seed: $seed\n";
    my @msg = @message;
    my ($in,$out);
    while (1) {
	my ($i, $code, $sym);
	if (@pivot_queue) {
	    my $new = shift @pivot_queue;
	    ($i, $code, $sym) = @{$new};
	    warn "Re-pivoting\n";
	} else {
	    ($i, $code, $sym) = encode_block_f256();
	    ++$rp;		# received packets
	}
	check_symbol_f256($i,$code,$sym) if $debug>1;
	if (pivot_f256($i, "$code", "$sym") == 0) {
	    warn "Trying to solve\n";
	    last if solve_f256() == 0;
	    warn "After initial solve, need to go again\n";
	    $matched = 0;
	    for (0 .. $gen-1) {
		++$matched if $msg[$_] eq $symbol[$_];
	    }
	    # Check for corruption of original array
	    for (0 .. $gen-1) {
		die unless $msg[$_] eq $message[$_];
	    }
	    warn "Matched $matched source <=> decoded blocks\n";
	}
    };
    warn "Fully decoded after $rp packets\n";
    $matched = 0;
    for (0 .. $gen-1) {
	++$matched if $msg[$_] eq $symbol[$_];
    }
    # Check for corruption of original array
    for (0 .. $gen-1) {
	die unless $msg[$_] eq $message[$_];
    }
    warn "Matched $matched source <=> decoded blocks";
    if ($debug) {
	$in  = unpack("H*", $message[0]);
	$out = unpack("H*", $symbol[0]);
	warn "Input block 0 was $in\n";
	warn "Output block 0 was $out\n";
	$in  = unpack("H*", $message[$gen - 1]);
	$out = unpack("H*", $symbol[$gen - 1]);
	warn "Input block $gen-1 was $in\n";
	warn "Output block $gen-1 was $out\n";
    }
    exit;
}

# Fountain Code for F_2
sub encode_block_f2 {
    my ($i, $code_vector, $block);

    $i = int(rand $gen);
    $block = "$message[$i]";

    # Need to convert random number into both a string (for later
    # XORs), and into integers that we can scan for binary 1's.
    # Rather than using pack, will just do byte-wise conversion,
    # treating the code vector as a network (big endian) byte order
    # number.
    my $j = ($i + 1) % $gen;
    $code_vector = "";
    my $bytes = $alpha / 8;
    die if int($bytes) != $bytes;
    while ($bytes--) {
	my $rand_int  = int rand 256;
	$code_vector .= chr $rand_int;
	my $mask = 128;
	while ($mask) {
	    if ($rand_int & $mask) {
		if (0) {
		    fast_xor_strings(\$block, "$message[$j]");
		} else {
		    $block ^= "$message[$j]";
		}
	    }
	    ++$j; $j -= $gen if $j >= $gen;
	    $mask >>= 1;
	}
    }

    return ($i, $code_vector, $block);
}

# Fountain Code for F_256
sub encode_block_f256 {
    my $hack = shift;
    my ($i, $code_vector, $block);
    $i = int(rand $gen);
    $block = "$message[$i]";

    # Here, we multiply message blocks by a randomly selected GF(2**8)
    # element.

    my $j = ($i + 1) % $gen;
    $code_vector = "";
    my $bytes = $alpha;
    while ($bytes--) {
	my $rand_int  = int rand 256;
	$code_vector .= chr $rand_int;
	if ($rand_int) {
	    # I should really write a vector multiply method in
	    # Math::FastGF2 (would speed this up a lot). 

	    # use Inline C routine
	    my $product = "$message[$j]"; # copy
	    gf256_vec_fma($block, $product, $rand_int);
	}
	++$j; $j = 0 if $j >= $gen;
    }

    return ($i, $code_vector, $block);
}

# Like encode_block_f2, but instead of randomly generating a code,
# takes i and code and checks that the symbol is correct.
sub check_symbol_f2 {
    my ($i,$code,$sym,$msg) = @_;
    $msg = "" unless defined $msg;
    warn "Checking: i is $i\n";
    warn "Checking: Code is " . (unpack "B*", $code) . "\n";
    my $check = "$message[$i]";
    for (0..$alpha-1) {
	my $bit = vec_bit($_);
	my $j = ($i + $_ + 1) % $gen;
	next unless vec($code,$bit,1) == 1;
	warn "Checking: XORing in \$message[$j]\n";
	$check ^= "$message[$j]";
    }
    die "Symbol not correct. $msg\n" unless $sym eq $check;
}

# Like encode_block_f2, but instead of randomly generating a code,
# takes i and code and checks that the symbol is correct.
sub check_symbol_f256 {
    my ($i,$code,$sym,$msg) = @_;
    $msg = "" unless defined $msg;
    warn "Checking: i is $i\n";
    warn "Checking: Code is " . (unpack "H*", $code) . "\n";
    my $check = "$message[$i]";
    my $k;
    for my $bit (0..$alpha-1) {
	my $j = ($i + $bit + 1) % $gen;
	$k = substr $code, $bit, 1;
	next if "\0" eq $k;
	my $khex = unpack "H2", $k;
	warn "Checking: XORing in $khex times \$message[$j]\n";
	gf256_vec_fma($check, "$message[$j]", ord $k);
    }
    die "Symbol not correct. $msg\n" unless $sym eq $check;
}

# Pivot will return the number of additional pivots required
sub pivot_f2 {

    my ($i, $code, $sym) = @_;
    my $zero_code  = "\0" x ($alpha * $qbits >> 3);

    my $tries = 0;
    while (++$tries < $gen * 2) {
	warn "Trying to pivot into row $i\n" if $debug;
	# We can get here if the original i slot was empty, or if we
	# substituted in another row and advanced i accordingly,
	# finding a subsequent empty i' slot.
	if ($filled[$i] == 0) {
	    warn "Successfully pivoted into row $i\n" if $debug;
	    $filled[$i] = 1;
	    $coding[$i] = $code;
	    $symbol[$i] = $sym;
	    return --$remain
	}
	if ($debug) {
	    warn "Row $i is occupied\n";
	    warn "Row code is ", (unpack "B*", $coding[$i]), "\n";
	    warn "Our code is ", (unpack "B*", $code), "\n";
	}

	die unless length $code == length $zero_code;

	# My inline C routines for vec_clz and vec_ctz can go off the
	# ends of the array, so before calling them, I must make sure
	# that the array isn't zero.
	if (1) {     # BUG... fixed (check for zero code first)
	    my ($ctz_row, $ctz_code) = ($alpha,$alpha);

	    $ctz_code = vec_ctz("$code")       unless $code eq $zero_code;
	    $ctz_row  = vec_ctz("$coding[$i]") unless $coding[$i] eq $zero_code;

	    warn "ctz_row  is $ctz_row\n"  if $debug;
	    warn "ctz_code is $ctz_code\n" if $debug;
	    if ($ctz_code > $ctz_row) {
		warn "Evicting row $i\n" if $debug;
		check_symbol_f2($i,$coding[$i],$symbol[$i], "(evicted)")
		    if $debug > 1;
		($code, $coding[$i]) = ("$coding[$i]", "$code");
		($sym,  $symbol[$i]) = ("$symbol[$i]", "$sym");
	    }
	}

	if ($debug) {
	    # Bug fix?... don't XOR something with a copy of itself!
	    # (actually, was already handled in the code below)
	    if ("$coding[$i]" eq "$code") {
		die "Inconsistent packet symbol received for row $i\n"
		    if "$symbol[$i]" ne "$sym";
		return $remain;
	    }
	}

	# Substitute the existing code vector and symbol into the ones
	# we're trying to insert
	#
	# Note: I see that recent versions of perl let you do xors (as
	# well as and, or, and bitwise not) on strings directly, so
	# I'll use that.
	if (0) {
	    fast_xor_strings(\$code, "$coding[$i]");
	    fast_xor_strings(\$sym,  "$symbol[$i]");
	} else {
	    $code ^= "$coding[$i]";
	    $sym  ^= "$symbol[$i]";
	}
	warn "Our code is ", (unpack "B*", $code), " after XOR\n" if $debug;

	# The implicit '1' before the code has been cancelled, so if
	# the code itself has also gone to zero, we expect the symbol
	# to also be cancelled (another self-check).
	if ($code eq $zero_code) {
	    warn "Our code got cancelled\n" if ($debug);
	    die "failed: zero code vector => zero symbol (i=$i)"
		unless $sym eq $zero_block;
	    warn "As expected, so did our symbol\n" if ($debug);
	    return $remain;
	}

	# update the coding vector and i (symbol done already)
	if ($debug) {
	    warn "Updating coding vector and i\n";
	    warn "old i: $i\n";
	    warn "code is ", (unpack "B*", $code), "\n";
	}
	my $clz_code = vec_clz("$code");
	warn "$clz_code leading zeroes\n" if $debug;
	vec_shl($code, $clz_code + 1);
	warn "shifted code is ", (unpack "B*", $code), "\n" if $debug;
	$i += $clz_code + 1;
	$i -= $gen if $i >= $gen;
	warn "new i: $i" if $debug;

	check_symbol_f2($i,$code,$sym, "(after attempted pivot)")
	    if $debug > 1;
    }

    carp "Bailed out trying to pivot element after $tries tries\n";
    return $remain;
}

sub pivot_f256 {
    my ($i, $code, $sym) = @_;
    my $zero_code = "\0" x $alpha;

    my $tries = 0;
    while (++$tries < $gen * 2) {
	warn "Trying to pivot into row $i\n" if $debug;
	if ($filled[$i] == 0) {
	    warn "Successfully pivoted into row $i\n" if $debug;
	    $filled[$i] = 1;
	    $coding[$i] = $code;
	    $symbol[$i] = $sym;
	    return --$remain
	}
	if ($debug) {
	    warn "Row $i is occupied\n";
	    warn "Row code is ", (unpack "H*", $coding[$i]), "\n";
	    warn "Our code is ", (unpack "H*", $code), "\n";
	}
	die unless $alpha == length $code;

	if (1) {
	    my ($ctz_row, $ctz_code);
	    $coding[$i] =~ m/(\0*)$/; $ctz_row  = length($1);
	    $code       =~ m/(\0*)$/; $ctz_code = length($1);
	    warn "ctz_row  is $ctz_row\n"  if $debug;
	    warn "ctz_code is $ctz_code\n" if $debug;

	    if ($ctz_code > $ctz_row) {
		warn "Evicting row $i\n" if $debug;
		check_symbol_f256($i,$coding[$i],$symbol[$i], "(evicted)")
		    if $debug > 1;
		($code, $coding[$i]) = ("$coding[$i]", "$code");
		($sym,  $symbol[$i]) = ("$symbol[$i]", "$sym");
	    }
	}

	# Need to do fused multiply-add? No.
	# But we do need to normalise ... a little bit later
	
	$code ^= "$coding[$i]";
	$sym  ^= "$symbol[$i]";
	warn "Our code is ", (unpack "H*", $code), " after XOR\n" if $debug;
	
	if ($code eq $zero_code) {
	    warn "Our code got cancelled\n" if ($debug);
	    die "failed: zero code vector => zero symbol (i=$i)"
		unless $sym eq $zero_block;
	    warn "As expected, so did our symbol\n" if ($debug);
	    return $remain;
	}
	# update the coding vector and i (symbol done already)
	if ($debug) {
	    warn "Updating coding vector and i\n";
	    warn "old i: $i\n";
	    warn "code is ", (unpack "H*", $code), "\n";
	}
	$code       =~ m/^(\0*)/;
	my $clz_code = length($1);
	warn "$clz_code leading zeroes\n" if $debug;

	my ($k,$inv_k);
	$k = substr($code, $clz_code, 1);
        $inv_k = gf256_inv_elem(ord $k);

	warn "Multiplying code by " . (unpack "H*", chr $inv_k) . "\n"
	    if $debug;
	gf256_vec_mul($code, $inv_k);
	gf256_vec_mul($sym,  $inv_k);
	warn "Multiplied code is ", (unpack "H*", $code), "\n" if $debug;
	
	$code  = substr($code, $clz_code + 1) . ("\0" x ($clz_code + 1));
	warn "shifted code is ", (unpack "H*", $code), "\n" if $debug;

	$i += $clz_code + 1;
	$i -= $gen if $i >= $gen;
	warn "new i: $i" if $debug;

	check_symbol_f256($i,$code,$sym, "(after attempted pivot)")
	    if $debug > 1;
    }
    carp "Bailed out trying to pivot element after $tries tries\n";
    return $remain;
}

sub vec_bit {
    return (($_[0] >> 3) << 3) + (7 - $_[0] & 7);
    # Alternative way of phrasing this (seems to be a bit slower, even
    # with fewer ops: shows overhead of naming variables):
    my $bit = shift;
    my $mask = $bit & 7;
    return ($bit ^ $mask) + 7 - $mask;
}

sub solve_f2 {

    # steps:
    #
    # 1. forward propagation of gen - alpha rows into bottom alpha rows
    # 2. conversion of bottom right alpha x alpha submatrix into echelon form
    # 3. back-propagation to clear any 1's apart from on main diagonal
    #
    # The second step can fail if there are not enough 1's to produce
    # a diagonal. However, we can still continue the pivot algorithm
    # so long as we clear any zeros from underneath the diagonal in
    # the remaining rows. We'll report the problem to the calling
    # program, which will go back into the loop where it waits for a
    # new packet to fill any remaining holes.
    #
    # The first step breaks the optimisation of only storing alpha
    # values per matrix row. I'll use vec and bitwise string xor
    # extensively here to work on full matrix rows.

    my ($j, $overhang) = (0, 0);

    # Upgrade last alpha rows to full matrix rows
    my @arows;			# last alpha rows of matrix
    do {
	my $row  = "";
	my $from = $coding[$gen - $alpha + $j];
	my $diag = $gen - $alpha + $j;

	# I want the first bit to be the most significant bit, but vec
	# counts from the LSB!  If I don't work this way, then
	# shifting left won't work as expected.
	vec($row, vec_bit($diag), 1) = 1;
	my $b = 0;
	do {
	    $diag++; $diag = 0 if $diag == $gen;
	    vec($row, vec_bit($diag), 1) = vec($from, vec_bit($b), 1)
	} until ++$b == $alpha;
	push @arows, $row;

    } until (++$j == $alpha);

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after creation\n";
	for (0..$alpha -1) {
	    my $r = unpack "B*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Step 1: Forward propagation!

    # Can use vec_shl when subtracting rows as an alternative to
    # unshifting a 1 bit then rotating right...

    my $shl = 7;		# as --$shl wraps around,
    my $col = 0;		# this increments by 1
    my $width = ($alpha / 8) + 1;
    for my $diag (0 .. $gen - $alpha - 1) {
	my $idrow = "\001$coding[$diag]";
	#warn "idrow before shl $shl: " . unpack("B*", $idrow);
	die if ($alpha / 8 + 1) != length $idrow;
	vec_shl($idrow,$shl) if $shl;
	#warn "idrow  after shl $shl: " . unpack("B*", $idrow);
	for my $arow (0 .. $alpha - 1) {
	    if (vec($arows[$arow], vec_bit($diag), 1) == 1) {
		if ($debug) {
		    warn "Did forward prop from $diag to \$arow[$arow]\n";
		    warn "code was ", unpack("B*", $idrow), "\n";
		}
		substr($arows[$arow], $col, $width) ^= "$idrow";
		$symbol[$gen - $alpha + $arow] ^= "$symbol[$diag]";
	    }
	}
	($shl, $col) = (7, $col + 1) if (--$shl < 0);
    }

    warn "Did step 1";

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after step 1\n";
	for (0..$alpha -1) {
	    my $r = unpack "B*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Step 2: convert submatrix at bottom right to echelon form
    # (what [2015] called "inversion")

    my $decode_ok = 1;		# be optimistic
    my $zero_alpha = "\0" x ($alpha / 8);
    # reduce @arows to alpha * alpha
    for (0..@arows -1) {
	substr $arows[$_], 0, ($gen - $alpha) / 8, '';
	#	warn "Length now " . length($arows[$_]);
    }

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after reduction to alpha x alpha\n";
	for (0..$alpha -1) {
	    my $r = unpack "B*", $arows[$_];
	    warn "| $r |\n";
	}
    }


  ZERO_BELOW:
    for my $diag (0 .. $alpha - 1) { ## BUG
	my $swap_row = $diag;
	if (vec ($arows[$diag], vec_bit($diag), 1) == 0) {
	  SWAP_ROW:
	    for my $down_row ($diag + 1 .. $alpha - 1) {
		if (vec ($arows[$down_row], vec_bit($diag), 1) == 1) {
		    warn "Swapping row $swap_row with $down_row" if $debug;
		    $swap_row = $down_row;
		    last SWAP_ROW;
		}
	    }
	    if ($swap_row == $diag) {
		# this column is all 0's, so see if we need to
		# re-pivot the row
		$decode_ok = 0;
		# either way, we remove this row from the big matrix
		$filled[$gen - $alpha + $diag] = 0;
		$remain++;
		die if length($arows[$diag]) != length($zero_alpha);
		warn "No ones found to swap with in column $diag\n" if $debug;
		if ($arows[$diag] eq $zero_alpha) {
		    # no, completely cancelled: discard it
		    warn "Cancelled alpha row was zero, not re-pivoting\n" if $debug;
		    die "bug: cancelled alpha row had nonzero symbol"
			if $symbol[$diag + $gen - $alpha] ne $zero_block;
		} else {
		    # We have to find the right i value by using vec_clz
		    warn "Re-pivoting alpha row $diag\n" if $debug;
		    my $code = "$arows[$diag]";
		    warn "Code before shift: " . (unpack "B*", $code) . "\n"
			if $debug;
		    my $i    = $gen - $alpha + $diag; # existing row
		    my $sym  = $symbol[$i];

		    # Can't check symbol yet, because we have to find the
		    # first 1 value and skip it.
		    #check_symbol_f2($i,"$code","$sym", "(before repivot)");

		    # Now try to repivot
		    my $lz = vec_clz("$arows[$diag]");
		    $i += ($lz-$diag); # don't count triangle of zeroes
		    vec_shl($code, $lz + 1);
		    if ($debug) {
			warn "Code after shift: " . (unpack "B*", $code) . "\n";
			warn "Symbol: " . (unpack "B*", $sym) . "\n";
		    }
		    $i %= $gen;
		    warn "new i: $i\n" if $debug;

		    # The last (?!) remaining bug is triggered here...
		    check_symbol_f2($i,"$code","$sym", "(after repivot)")
			if $debug>1;
		    push @pivot_queue, [$i, "$code", "$sym"];

		    # Clear out the hole everywhere
		    $arows [$diag]                 = $zero_alpha;
		    $symbol[$gen - $alpha + $diag] = $zero_block;
		    $coding[$gen - $alpha + $diag] = $zero_code;
		}
		# skip to next diagonal element so that we end
		# with echelon form
		next ZERO_BELOW;

	    } else {
		# we did find a row to swap with; swap in arows and
		# symbol tables.
		warn "Row $swap_row has a 1, so swapping with row $diag (0)\n"
		    if $debug;
		my $gen_base = $gen - $alpha;
		@arows [$diag,$swap_row] = @arows[$swap_row,$diag];
		@symbol[$gen_base + $diag, $gen_base + $swap_row] =
		    @symbol[$gen_base + $swap_row, $gen_base + $diag];
		if (0) {
		    # don't update coding until later; it's not
		    # consistent with the current @arows values
		    @coding[$gen_base + $diag, $gen_base + $swap_row] =
			@coding[$gen_base + $swap_row, $gen_base + $diag];
		}
	    }
	}

	# found a 1 on the diagonal: use it to cancel 1's below
	# (start from swap_row + 1: we might have skipped some zeros)
	for my $down_row ($swap_row + 1 .. $alpha - 1) {
	    if (vec ($arows[$down_row], vec_bit($diag), 1) == 1) {
		#next if $arows[$down_row] eq $zero_alpha;
		$arows[$down_row] ^= "$arows[$diag]";
		die if length($arows[$down_row]) != length($zero_alpha);
		$symbol[$gen - $alpha + $down_row] ^=
		    "$symbol[$gen - $alpha + $diag]";
		# @coding is updated at the end
	    }
	}

	# More debug messages...
	if ($debug) {
	    warn "Alpha matrix after clearing column $diag\n";
	    for (0..$alpha -1) {
		my $r = unpack "B*", $arows[$_];
		warn "| $r |\n";
	    }
	}


    }
    

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after \"inversion\"\n";
	for (0..$alpha -1) {
	    my $r = unpack "B*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Have been working on @arows, now have to move updated values
    # back into @coding
    $coding[$gen - 1] = $zero_alpha;
    $shl = 1;			# shift left by one to remove diagonal
    for my $i (0 .. $alpha - 1) {
	my $code = "$arows[$i]";
	vec_shl($code,$shl);
	$coding[$gen - $alpha + $i] = $code;
	++$shl;
    }

    # Dump out the last alpha rows of @coding
    if ($debug) {
	warn "Coding matrix after conversion from \@arows\n";
	my $matched = 0;
	for (0 .. $gen - 1) {
	    my $r = unpack "B*", $coding[$_];
	    my $fill = $filled[$_] ? "[FILLED] " : "         ";
	    my $match = ($message[$_] eq $symbol[$_]) ?
		(++$matched, " [MATCH]") : "";
	    warn "| $r | $fill $match\n";
	    warn "+-" . ("-" x $alpha) . "-+" if $gen - $alpha -1 == $_;
	}
	warn "Remaining is $remain\n";
	warn "Matched $matched rows";
    }

    warn "Did step 2" if $debug;

    return 1 unless $decode_ok;
    
    # Step 3: back-substitute
    #
    # This is straightforward, but we're back to using the compressed
    # matrix form. Note that we only have to update the @symbol table.
    # We don't need to update @coding because it's implied that it's
    # going to end up with zero values to the right of the diagonal.
    my $diag = $gen - 1;	# bottom right
    do {
	# Counter is usually alpha, but not when we get to the top
	# of the matrix.
	my $rows = $alpha < $diag ? $alpha : $diag;
	#warn "Rows is $rows\n";
	#$rows = $diag;	# DEBUG
	warn "Working up from row $diag\n" if $debug;
	if ($rows) {
	    my $i = $diag - 1;	# row pointer
	    my $bit = 0;
	    die if $i < 0;
	    do {
		warn "Checking bit $bit of coding/symbol $i\n" if $debug;
		if (vec($coding[$i], vec_bit($bit), 1) == 1) {
		    warn "1: substituting\n" if $debug;
		    $symbol[$i] ^= "$symbol[$diag]";
		    # do clear the bit in case 
		    # vec($coding[$i], vec_bit($bit), 1) = 0;
		} else {
		    warn "0: not substituting\n" if $debug;
		}
	    } while (++$bit, --$i, --$rows);
	}
    } while (--$diag);		# stop at top row

    # After decoding
    if ($debug) {
	warn "Matrix after final back-propagation:\n";
	my $matched = 0;
	for (0 .. $gen - 1) {
	    my $r = unpack "B*", $coding[$_];
	    my $fill = $filled[$_] ? "[FILLED] " : "         ";
	    my $match = ($message[$_] eq $symbol[$_]) ?
		(++$matched, " [MATCH]") : "";
	    warn "| $r | $fill $match\n";
	    warn "+-" . ("-" x $alpha) . "-+" if $gen - $alpha -1 == $_;
	}
	warn "Remaining is $remain\n";
	warn "Matched $matched rows";
    }

    return ($decode_ok) ? 0 : 1;
}

sub solve_f256 {

    # steps: same as in solve_f2
    #
    #
    my $j = 0;

    # Upgrade last alpha rows to full matrix rows
    my @arows;
    do {
	my ($from,$row) = ($coding[$gen - $alpha + $j++]); # NB: ++
	$row  = substr $from, -$j, $j, ''; # splice from tail end
	$row .= "\0" x ($gen - $alpha -1);
	$row .= "\01$from";
	die unless $gen == length $row;
	push @arows, $row;

    } until ($j == $alpha);

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after creation\n";
	for (0..$alpha -1) {
	    my $r = unpack "H*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Step 1: Forward propagation!

    # No need for bit shifts, since everything is byte-aligned.
    # However, we do need to multiply a code/symbol row above before
    # xoring it into the row below.
    #
    # Note that gf256_vec_fma operates on strings of equal length, so
    # we need to do a bit of string splicing.

    for my $diag (0 .. $gen - $alpha - 1) {
	for my $arow (0 .. $alpha - 1) {
	    my $k = substr $arows[$arow], $diag, 1; # mult. factor
	    next if "\0" eq $k;

	    # skip the first element containing k, since it's implicit
	    # in the main coding vector table.
	    my $updated = substr $arows[$arow], $diag + 1, $alpha;
	    # $updated = "$updated"; # just in case
	    # gf256_vec_fma($updated, $coding[$diag], ord $k);
	    # leading k is implicitly cancelled, so make it explicit
	    substr $arows[$arow], $diag, $alpha + 1, "\0$updated";

	    # Likewise, multiply and add to the symbol table entry
	    gf256_vec_fma($symbol[$gen - $alpha + $arow],
			  $symbol[$diag], ord $k);
	    
	}
    }

    warn "Did step 1";

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after step 1\n";
	for (0..$alpha -1) {
	    my $r = unpack "H*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Step 2: convert submatrix at bottom right to echelon form
    # (what [2015] called "inversion")

    my $decode_ok = 1;		# be optimistic
    my $zero_alpha = "\0" x $alpha;
    # reduce @arows to alpha * alpha
    for (0..@arows -1) {
	substr $arows[$_], 0, ($gen - $alpha), '';
	warn "Length now " . length($arows[$_]) if $debug;
    }

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after reduction to alpha x alpha\n";
	for (0..$alpha -1) {
	    my $r = unpack "H*", $arows[$_];
	    warn "| $r |\n";
	}
    }


  ZERO_BELOW:
    for my $diag (0 .. $alpha - 1) { ## BUG (not really)
	my $swap_row = $diag;
	my $k = substr $arows[$diag], $diag, 1;
	if ("\0" eq $k) {
	  SWAP_ROW:
	    for my $down_row ($diag + 1 .. $alpha - 1) {
		if ("\0" ne substr $arows[$down_row], $diag, 1) {
		    warn "Swapping row $swap_row with $down_row" if $debug;
		    $swap_row = $down_row;
		    last SWAP_ROW;
		}
	    }
	    if ($swap_row == $diag) {

		# Skipping implementation for now. It's more likely
		# that we won't get here because the probability that
		# the rows are all linearly independent is much better
		# than for F_2.
		...;

		    
		# this column is all 0's, so see if we need to
		# re-pivot the row
		$decode_ok = 0;
		# either way, we remove this row from the big matrix
		$filled[$gen - $alpha + $diag] = 0;
		$remain++;
		die if length($arows[$diag]) != length($zero_alpha);
		warn "No ones found to swap with in column $diag\n" if $debug;
		if ($arows[$diag] eq $zero_alpha) {
		    # no, completely cancelled: discard it
		    warn "Cancelled alpha row was zero, not re-pivoting\n" if $debug;
		    die "bug: cancelled alpha row had nonzero symbol"
			if $symbol[$diag + $gen - $alpha] ne $zero_block;
		} else {
		    # We have to find the right i value by using vec_clz
		    warn "Re-pivoting alpha row $diag\n" if $debug;
		    my $code = "$arows[$diag]";
		    warn "Code before shift: " . (unpack "B*", $code) . "\n"
			if $debug;
		    my $i    = $gen - $alpha + $diag; # existing row
		    my $sym  = $symbol[$i];

		    # Can't check symbol yet, because we have to find the
		    # first 1 value and skip it.
		    #check_symbol_f2($i,"$code","$sym", "(before repivot)");

		    # Now try to repivot
		    my $lz = vec_clz("$arows[$diag]");
		    $i += ($lz-$diag); # don't count triangle of zeroes
		    vec_shl($code, $lz + 1);
		    if ($debug) {
			warn "Code after shift: " . (unpack "B*", $code) . "\n";
			warn "Symbol: " . (unpack "B*", $sym) . "\n";
		    }
		    $i %= $gen;
		    warn "new i: $i\n" if $debug;

		    # The last (?!) remaining bug is triggered here...
		    check_symbol_f2($i,"$code","$sym", "(after repivot)")
			if $debug>1;
		    push @pivot_queue, [$i, "$code", "$sym"];

		    # Clear out the hole everywhere
		    $arows [$diag]                 = $zero_alpha;
		    $symbol[$gen - $alpha + $diag] = $zero_block;
		    $coding[$gen - $alpha + $diag] = $zero_code;
		}
		# skip to next diagonal element so that we end
		# with echelon form
		next ZERO_BELOW;

	    } else {
		# Back to implementing for F_256 ...

		# Actually, this bit should be unchanged from F_2
		warn "Row $swap_row has a non-zero element. " .
		    "Swapping with row $diag (0)\n" if $debug;
		my $gen_base = $gen - $alpha;
		@arows [$diag,$swap_row] = @arows[$swap_row,$diag];
		@symbol[$gen_base + $diag, $gen_base + $swap_row] =
		    @symbol[$gen_base + $swap_row, $gen_base + $diag];

		# This is new:
		$k = substr $arows[$diag], $diag, 1;
	    }
	}

	# Add an extra step here: normalise the diagonal to 1
	if ("\0" eq $k) {
	    0 or die;
	} elsif ("\001" eq $k) {
	    1;
	} else {
	    my $inv_k = gf256_inv_elem(ord $k); # calculate 1/k
	    gf256_vec_mul($arows[$diag],  $inv_k);
	    gf256_vec_mul($symbol[$gen - $alpha + $diag], $inv_k);
	}

	# use the diagonal to cancel non-zero values below (start from
	# swap_row + 1: we might have skipped some zeros)
	for my $down_row ($swap_row + 1 .. $alpha - 1) {
	    my $k = substr $arows[$down_row], $diag, 1;
	    next if $k eq "\0";

	    # The diagonal element above has been normalised to 1, so
	    # we can do the same kind of fma as before, except now that
	    # we're working with 2 @arows, the 1's are explicit

	    gf256_vec_fma($arows[$down_row], $arows[$diag], ord $k);
	    my $gen_base = $gen - $alpha;
	    gf256_vec_fma($symbol[$gen_base + $down_row], 
			  $symbol[$gen_base + $diag], ord $k);
	}

	# More debug messages...
	if ($debug) {
	    warn "Alpha matrix after clearing column $diag\n";
	    for (0..$alpha -1) {
		my $r = unpack "H*", $arows[$_];
		warn "| $r |\n";
	    }
	}


    }

    # Dump out the @arows version of the matrix
    if ($debug) {
	warn "Alpha matrix after \"inversion\"\n";
	for (0..$alpha -1) {
	    my $r = unpack "H*", $arows[$_];
	    warn "| $r |\n";
	}
    }

    # Have been working on @arows, now have to move updated values
    # back into @coding
    for my $i (0 .. $alpha - 1) {
	my $zero_padded = $arows[$i] . $zero_alpha;
	$coding[$gen - $alpha + $i] = substr($zero_padded, $i + 1, $alpha);
	check_symbol_f256($gen - $alpha + $i,
			  $coding[$gen - $alpha + $i],
			  $symbol[$gen - $alpha + $i],
			  "(after conversion to \@coding)")
	    if $debug > 1;

    }
    
    # Dump out the last alpha rows of @coding
    if ($debug) {
	warn "Coding matrix after conversion from \@arows\n";
	my $matched = 0;
	for (0 .. $gen - 1) {
	    my $r = unpack "H*", $coding[$_];
	    my $fill = $filled[$_] ? "[FILLED] " : "         ";
	    my $match = ($message[$_] eq $symbol[$_]) ?
		(++$matched, " [MATCH]") : "";
	    warn "| $r | $fill $match\n";
	    warn "+-" . ("-" x $alpha) . "-+" if $gen - $alpha -1 == $_;
	}
	warn "Remaining is $remain\n";
	warn "Matched $matched rows";
    }

    warn "Did step 2" if $debug;

    return 1 unless $decode_ok;

    # Before I implement the next bit, I'm going to just make sure
    # that there are no syntax errors, then go back and test what
    # happens in the F_2 code when I don't update the coding vector in
    # step 3.
    #
    # My intuition is that all we have to do here is just substitute
    # symbols.

    # Actually, scratch that. The code below is simple enough for me
    # to just finish changing it...
    
    # Step 3: back-substitute
    #
    # This is straightforward, but we're back to using the compressed
    # matrix form. Note that we only have to update the @symbol table.
    # We don't need to update @coding because it's implied that it's
    # going to end up with zero values to the right of the diagonal.
    my $diag = $gen - 1;	# bottom right
    do {
	# Counter is usually alpha, but not when we get to the top
	# of the matrix.
	my $rows = $alpha < $diag ? $alpha : $diag;
	#warn "Rows is $rows\n";
	#$rows = $diag;	# DEBUG
	warn "Working up from row $diag\n" if $debug;
	if ($rows) {
	    my $i = $diag - 1;	# row pointer
	    my $bit = 0;
	    die if $i < 0;
	    do {
		warn "Checking bit $bit of coding/symbol $i\n" if $debug;
		my $k = substr $coding[$i], $bit, 1;
		if ("\0" eq $k) {
		    warn " =0: not substituting\n" if $debug;
		} elsif ("\001" eq $k) {
		    warn " =1 : substituting use XOR\n" if $debug;
		    $symbol[$i] ^= $symbol[$diag];
		    # do clear the bit in case 
		    substr $coding[$i], $bit, 1, "\0";
		} else {
		    warn " >1 : substituting using vec_fma\n" if $debug;
		    gf256_vec_fma($symbol[$i], $symbol[$diag], ord $k);
		    # do clear the bit in case 
		    substr $coding[$i], $bit, 1, "\0";
		}
	    } while (++$bit, --$i, --$rows);
	}
    } while (--$diag);		# stop at top row

    # After decoding
    if ($debug) {
	warn "Matrix after final back-propagation:\n";
	my $matched = 0;
	for (0 .. $gen - 1) {
	    my $r = unpack "H*", $coding[$_];
	    my $fill = $filled[$_] ? "[FILLED] " : "         ";
	    my $match = ($message[$_] eq $symbol[$_]) ?
		(++$matched, " [MATCH]") : "";
	    warn "| $r | $fill $match\n";
	    warn "+-" . ("-" x $alpha) . "-+" if $gen - $alpha -1 == $_;
	}
	warn "Remaining is $remain\n";
	warn "Matched $matched rows";
    }

    return ($decode_ok) ? 0 : 1;
}

# The remaining is a rewrite to handle the scheme described in:
#
# "Perpetual Codes: Cache-friendly Coding", Petar Maymounkov, 2006
#
# Some differences:
#
# * encoded packets for row i don't have to have source block [i]
#   incorporated in it. (this might have some implication for the row
#   "eviction" code I borrowed for the implementation above)
#
# * a pre-coding step adds two types of redundant symbols, which are
#   interleaved with message blocks.
#
# * these are basically random source blocks, not constrained to being
#   selected from the apterture (alpha)
#
# * stops decoding when the main matrix (labelled 'A') is "almost"
#   full, and then attempts to solve the full set of equations by
#   substituting it into the other matrix (labelled B) containing the
#   sparse, random redundancy blocks.
#
# * an optimisation that reduces the work in the previous step
#   (labelled "Inner System Disjoin")
#
# * some notes on implementation, such as organisation of matrices in
#   memory (or an external file) in order to ensure decoded symbols
#   are contiguous, and to optimise for a forward scan of data where
#   possible.
#
# * a new set of parameters relating to the pre-coding step

# Implementation details
#
# Option handling and function naming gets a little bit unweildy when
# we've got two major axes:
#
# * choice of algorithm
# * choice of field
#
# I might just write a parallel implementation of all the high-level
# routines (such as pivot_f2), but I'll need to rename the existing
# subs. I think that the easiest way to name them is after the
# respective papers that I'm following. So these will be _2015 for the
# current implementation above, and _2006 for the new one, below.
#
# I had considered jumping straight to a C implementation for the new
# algorithms, but it seems that it's better to iron out the kinks in
# Perl first, get the thing working, and then look at how I can
# approach the C version.
#
# Due to interleaving of source blocks and redundant blocks, as well
# as the desire to have each matrix contiguous in its own memory
# space, I will need some sort of permutation system. For example, in
# the previous code, I worked with the @coding and @symbol matrices
# (vectors, really). In the new code, however, a given row in these
# could refer to:
#
# * a zero block, which the pre-code adds at the start of the stream
#   for padding (to eliminate the forward substitution step in [2016].
#
# * a source message block
#
# * a redundant symbol (the two types can be stored in the same matrix
#   and have compatible types)
#
# Strictly speaking, this sort of permutation/depermutation is only of
# interest for the @symbol matrix. Each element in a coding vector can
# refer to different types of symbol.
#
# I can re-use the existing compact interpretation of the coding
# vector array (plus a new permutation layer to map the effective row
# i to the correct symbol), but I will need to have a different
# representation for the random redundant symbols. I assume that the
# zero blocks do not need explicit storage. Or that I will have to
# store no more than one of them.
#
# There are actually two ways to handle the mapping of i (and
# effective i) values used to index the @coding array to the
# appropriate symbol table entries:
#
# 1. by means of a permutation function (and its inverse, if needed);
#    
# 2. by means of a lookup table
#
# The second method would store references to the appropriate symbol
# table entry, so an extra dereferencing step would be needed to
# access the symbol. A similar table of references would work in
# reverse, too, should we need to convert i references in the B
# (redundancy) matrix into the correct source message blocks within A.
#
# The formulation of the permutation function in the paper uses a
# formal numerical description, which is quite difficult to follow,
# although it seems to simply boil down to saying that the two types
# of non-zero redundant symbols should be inserted at equal intervals
# among the source symbols.
#
# The paper suggests that the gamma value (which determines the number
# of non-zero redundant blocks) be a rational number, and that it
# creates a spread of redundant blocks that book-ends the non-zero
# values. For example:
#
# | 0 0 0 R m m R m m R m m R |
#
# We might also use something like Bresenham's line drawing algorithm
# to find the correct points.
#
# For longer sequences where everything to the right of the first R
# does not divide into equal m,m,..,m,R segments, we have to use the
# accumulated error (or the floor-based calculation mentioned in the
# text) to decide to add a final m before the R or not.
#
# Interpreting this as line in two dimensions gives us an intuitive
# way of looking at the permutation and its inverse, eg:
#
#     rho(i) 
# R_last   ^        x
# m_k-1	   |   	      
# m_k-2	   |   	      
# R_...	   |     x   
# m_...	   |  	      
# ...	   |  	      
#	   |  x      
# ...	   |  	      
# m_0	   | 	      
# R_0	   x	      
# 0	   |	      
# 0	   |	      
# ...	   |	      
# 0        |	
#          +------------> R
#          0  1  2  3
#
# This shows the mapping of R values in the redundancy matrix to
# positions in the coding matrix. You can also go in the opposite
# direction by transposing the graph.
#
# All i values and effective i values (ie, column positions to the
# right of the diagonal) refer to the Y axis above, though logically
# speaking we will have a redundant matrix B which is actually ordered
# as per the X axis, and a disjoint "message matrix", which is the
# complement of the B matrix (ignoring zero elements).
#
# I feel more comfortable calculating the mappings once and using
# lookup tables (dealing with integers all the time) rather than using
# numeric formulas.
#
#
# "Filled" vector
#
# In the Inner System Disjoin step, coding vectors are effectively
# shifted to the right of the matrix by some number of columns until
# they align with a hole below (without wrap-around). We can do this
# without needing to expand the compact form of @coding out into a
# full matrix representation by shifting left the coded form after
# back-substitution. However, this means that we have to track the
# number of times the vector has shifted (logically, to the right
# within the matrix, but physically left in the coded form). We can
# re-use the @filled vector, but change it slightly:
#
# * before this step, we use a value of -1 to indicate the row is empty
# * a value of 0 indicates fullness
# * positive values indicates fullness + a shift of that amount
#
# After the step:
#
# | 1     1 0 1       | normalised, filled = 2 (shifted twice)
# |   1   1 1 0       | normalised, filled = 1
# |     1 0 0 1       | normalised, filled = 0 (not shifted)
# |   ... 0 0 0 ...   | hole, filled = -1
#
#
# About this step... I had previously imagined that it was carried out
# from the top of the matrix to the bottom, but actually it is carried
# out from the bottom up. In fact, it is basically a modification of a
# normal back-propagation step except that instead of "pushing up" a 1
# in a column as far as it will go, we "pull up" all diagonal elements
# from below for a particular row. Also, we stop when we hit a hole
# and treat that as if it were the end of the matrix.
#
#
#
__END__
__C__
/* Miscellaneous GF(2**8) stuff */

// nibble-based leading zero counts
const static short leading[] = {
  4, 3, 2, 2, 1, 1, 1, 1, // 0-7
  0, 0, 0, 0, 0, 0, 0, 0  // 8-15
};

// No boundary checking done here; caller needs to make sure string
// is not all zeroes first
unsigned int vec_clz(char *s) {
    int zeroes = 0;
    while (*s == (char) 0) { zeroes+=8; ++s; }
    if (*s & 0xf0) {
        return zeroes + leading[((unsigned char) *s) >> 4];
    } else {
        return zeroes + 4 + leading[*s];
    }
}

// nibble-based trailing zero counts
const static short trailing[] = {
  4, 0, 1, 0, 2, 0, 1, 0, // 0-7 
  3, 0, 1, 0, 2, 0, 1, 0  // 8-15
};
// No boundary check done here either.
unsigned vec_ctz(SV *sv) {
    STRLEN len;
    char *s;
    s = SvPV(sv, len);

    s += len - 1;
    int zeroes = 0;
    while (*s == (char) 0) { zeroes+=8; --s; }
    if (*s & 0x0f) {
        return zeroes + trailing[(*s) & 0x0f];
    } else {
        return zeroes + 4 + trailing[((unsigned char) *s) >> 4];
    }
}

// Shift a vector (string) left by b bits
void vec_shl(SV *sv, unsigned b) {
    STRLEN len;
    unsigned char *s;
    unsigned full_bytes;

    if (b == 0) return;

    s = SvPV(sv, len);
    full_bytes = b >> 3;

    // shifting by full bytes is easy
    if ((b & 7) == 0) {
        int c = len - full_bytes;
        while (c--) {
            *s = s[full_bytes];
            ++s;
        }
        while (full_bytes--) { *(s++) = (char) 0; }
        return;
    }

    //return;

    // or else combine bits from two bytes
    int c = len - full_bytes - 1;
    unsigned char l,r;
    b &= 7;
    while (c--) {
        l = s[full_bytes]    <<      b;
        r = ((unsigned char) s[full_bytes +1]) >> (8 - b);
        *(s++) = l | r;
    }
    // final byte to shift should be at end of vector
    l = s[full_bytes]  << b;
    *(s++) = l;
    // zero-pad the rest
    while (full_bytes--) { *(s++) = (char) 0; }
}

// Field operations (single/pair of elements)
const static unsigned char exp_table[];
const static signed short log_table[];

unsigned char gf256_mul_elems(unsigned char a, unsigned char b) {
    const static signed short *log =  log_table;
    const static char         *exp =  exp_table + 512;
    return exp[log[a] + log[b]];
}

unsigned char gf256_inv_elem(unsigned char a) {
    const static signed   short *log =  log_table;
    const static unsigned char  *exp =  exp_table + 512;
    return exp[255-log[a]];
}

// multiply all elements of a vector by a constant.

// Inline::C automatically handles passing of strings by value
// (letting us write char *s), but not pass by reference, so we have
// to use SV* below instead

void gf256_vec_mul(SV *sv, unsigned char val) {
    const static char         *exp =  exp_table + 512;
    const static signed short *log =  log_table;
    signed short log_a = log[(unsigned char) val];

    // extract length and pointer to string
    STRLEN len;
    char *s;
    s = SvPV(sv, len);

    while (len--) {
        *s = exp[log_a + log[(unsigned char) *s]];
        ++s;
    }
}

// multiply all elements of a vector by a constant, then add another
// vector of the same length (ie, "fused multiply-add")
void gf256_vec_fma(SV *dv, SV *sv, unsigned char val ) {
    static char         *exp =  exp_table + 512;
    static signed short *log =  log_table;
    unsigned char *d, *s;
    STRLEN len_d;
    STRLEN len_s;
    signed short log_a = log[(unsigned char) val];

    d = SvPV(dv, len_d);
    s = SvPV(sv, len_s);

    if (len_s != len_d) {
        fprintf(stderr, "vec_mul: Source, destination string size mismatch\n");
        exit(1);
    }

    while (len_d--) {
        *(d++) ^= exp[log_a + log[(unsigned char) *(s++)]];
    }

}

const static unsigned char exp_table[] = {
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    1, 3, 5, 15, 17, 51, 85, 255,
    26, 46, 114, 150, 161, 248, 19, 53,
    95, 225, 56, 72, 216, 115, 149, 164,
    247, 2, 6, 10, 30, 34, 102, 170,
    229, 52, 92, 228, 55, 89, 235, 38,
    106, 190, 217, 112, 144, 171, 230, 49,
    83, 245, 4, 12, 20, 60, 68, 204,
    79, 209, 104, 184, 211, 110, 178, 205,
    76, 212, 103, 169, 224, 59, 77, 215,
    98, 166, 241, 8, 24, 40, 120, 136,
    131, 158, 185, 208, 107, 189, 220, 127,
    129, 152, 179, 206, 73, 219, 118, 154,
    181, 196, 87, 249, 16, 48, 80, 240,
    11, 29, 39, 105, 187, 214, 97, 163,
    254, 25, 43, 125, 135, 146, 173, 236,
    47, 113, 147, 174, 233, 32, 96, 160,
    251, 22, 58, 78, 210, 109, 183, 194,
    93, 231, 50, 86, 250, 21, 63, 65,
    195, 94, 226, 61, 71, 201, 64, 192,
    91, 237, 44, 116, 156, 191, 218, 117,
    159, 186, 213, 100, 172, 239, 42, 126,
    130, 157, 188, 223, 122, 142, 137, 128,
    155, 182, 193, 88, 232, 35, 101, 175,
    234, 37, 111, 177, 200, 67, 197, 84,
    252, 31, 33, 99, 165, 244, 7, 9,
    27, 45, 119, 153, 176, 203, 70, 202,
    69, 207, 74, 222, 121, 139, 134, 145,
    168, 227, 62, 66, 198, 81, 243, 14,
    18, 54, 90, 238, 41, 123, 141, 140,
    143, 138, 133, 148, 167, 242, 13, 23,
    57, 75, 221, 124, 132, 151, 162, 253,
    28, 36, 108, 180, 199, 82, 246, 1,
    3, 5, 15, 17, 51, 85, 255, 26,
    46, 114, 150, 161, 248, 19, 53, 95,
    225, 56, 72, 216, 115, 149, 164, 247,
    2, 6, 10, 30, 34, 102, 170, 229,
    52, 92, 228, 55, 89, 235, 38, 106,
    190, 217, 112, 144, 171, 230, 49, 83,
    245, 4, 12, 20, 60, 68, 204, 79,
    209, 104, 184, 211, 110, 178, 205, 76,
    212, 103, 169, 224, 59, 77, 215, 98,
    166, 241, 8, 24, 40, 120, 136, 131,
    158, 185, 208, 107, 189, 220, 127, 129,
    152, 179, 206, 73, 219, 118, 154, 181,
    196, 87, 249, 16, 48, 80, 240, 11,
    29, 39, 105, 187, 214, 97, 163, 254,
    25, 43, 125, 135, 146, 173, 236, 47,
    113, 147, 174, 233, 32, 96, 160, 251,
    22, 58, 78, 210, 109, 183, 194, 93,
    231, 50, 86, 250, 21, 63, 65, 195,
    94, 226, 61, 71, 201, 64, 192, 91,
    237, 44, 116, 156, 191, 218, 117, 159,
    186, 213, 100, 172, 239, 42, 126, 130,
    157, 188, 223, 122, 142, 137, 128, 155,
    182, 193, 88, 232, 35, 101, 175, 234,
    37, 111, 177, 200, 67, 197, 84, 252,
    31, 33, 99, 165, 244, 7, 9, 27,
    45, 119, 153, 176, 203, 70, 202, 69,
    207, 74, 222, 121, 139, 134, 145, 168,
    227, 62, 66, 198, 81, 243, 14, 18,
    54, 90, 238, 41, 123, 141, 140, 143,
    138, 133, 148, 167, 242, 13, 23, 57,
    75, 221, 124, 132, 151, 162, 253, 28,
    36, 108, 180, 199, 82, 246, 1, 0,
    // The following are needed to make 1/0 = 0 on some platforms
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};
const static signed short log_table[] = {
    -256, 255, 25, 1, 50, 2, 26, 198,
    75, 199, 27, 104, 51, 238, 223, 3,
    100, 4, 224, 14, 52, 141, 129, 239,
    76, 113, 8, 200, 248, 105, 28, 193,
    125, 194, 29, 181, 249, 185, 39, 106,
    77, 228, 166, 114, 154, 201, 9, 120,
    101, 47, 138, 5, 33, 15, 225, 36,
    18, 240, 130, 69, 53, 147, 218, 142,
    150, 143, 219, 189, 54, 208, 206, 148,
    19, 92, 210, 241, 64, 70, 131, 56,
    102, 221, 253, 48, 191, 6, 139, 98,
    179, 37, 226, 152, 34, 136, 145, 16,
    126, 110, 72, 195, 163, 182, 30, 66,
    58, 107, 40, 84, 250, 133, 61, 186,
    43, 121, 10, 21, 155, 159, 94, 202,
    78, 212, 172, 229, 243, 115, 167, 87,
    175, 88, 168, 80, 244, 234, 214, 116,
    79, 174, 233, 213, 231, 230, 173, 232,
    44, 215, 117, 122, 235, 22, 11, 245,
    89, 203, 95, 176, 156, 169, 81, 160,
    127, 12, 246, 111, 23, 196, 73, 236,
    216, 67, 31, 45, 164, 118, 123, 183,
    204, 187, 62, 90, 251, 96, 177, 134,
    59, 82, 161, 108, 170, 85, 41, 157,
    151, 178, 135, 144, 97, 190, 220, 252,
    188, 149, 207, 205, 55, 63, 91, 209,
    83, 57, 132, 60, 65, 162, 109, 71,
    20, 42, 158, 93, 86, 242, 211, 171,
    68, 17, 146, 217, 35, 32, 46, 137,
    180, 124, 184, 38, 119, 153, 227, 165,
    103, 74, 237, 222, 197, 49, 254, 24,
    13, 99, 140, 128, 192, 247, 112, 7
};

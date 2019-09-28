#!/usr/bin/env perl

use strict;
use warnings;

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
my $blocksize = 1024;
my $verbose   = 0;
my $hacky     = 0;
my $packets   = 0;		# 0   -> run until decoded;
                                # +ve -> stop after this many packets
my $test_what = '';		# run internal tests

# Algorithm-specific stuff
my $q         = 2;   		# default to GF(2) == GF(2**1);
my $alpha     = 32;		# aperture size alpha
my $gen       = 2048;

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
	    "deterministic"     => \$deterministic,
)
    or die("Error in command line arguments\n");

if ($test_what eq "vec_mul") {
    my $str = "CamelCase";
    my $nul = "\0" x length($str);
    gf256_vec_mul($str,"\001");	# in-place update!
    die "gf256_vec_mul identity failed (got '$str')\n" if $str ne 'CamelCase';
    gf256_vec_mul($str,"\0");
    die "gf256_vec_mul zero failed (got '$str')\n" if $str ne $nul;
    print "vec_mul tests passed\n";
    exit 0;
}


die "Field must be 2 or 256\n" if ($q != 2 and $q != 256);

# strictly speaking, setting a seed is deterministic, but I use
# --deterministic to indicate using a fixed seed of 0.
die "Incompatible options --seed and --deterministic\n"
    if $deterministic and defined $seed;
$seed = 0 if $deterministic;
srand($seed) if defined($seed);

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

# Meaning that we can do this:
my $zero_code  = "\0" x ($alpha * $qbits >> 3);
my $zero_block = "\0" x $blocksize; # independent of alpha, gen, q


# Implement the algorithm over F2 first
if ($q == 256) { ...  }



# Simulate a square matrix of size $gen
my @filled = ((0) x $gen);
my @coding = ();
my @symbol = ();
my $remain = $gen;

# Fountain Code for F_2
sub encode_block_f2 {
    my ($i, $code_vector, $block);

    $i = int(rand $gen);
    $block = $message[$i];

    # Need to convert random number into both a string (for later
    # XORs), and into integers that we can scan for binary 1's.
    # Rather than using pack, will just do byte-wise conversion,
    # treating the code vector as a network (big endian) byte order
    # number.
    my $j = ($i + 1) % $gen;
    $code_vector = "";
    my $bytes = $alpha / 8;
    while ($bytes--) {
	my $rand_int  = int rand 256;
	$code_vector .= chr $rand_int;
	my $mask = 128;
	while ($mask) {
	    if ($rand_int & $mask) {
		fast_xor_strings(\$block, $message[$j])
	    }
	    ++$j; $j = 0 if $j >= $gen;
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
    $block = $message[$i];

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
	    if ($hacky) {
		# use Inline C routine
		my $product = $message[$j]; # copy
		if ("no" eq "mult, then add") {
		    # do multiply-add as two steps
		    gf256_vec_mul($product, chr $rand_int);
		    fast_xor_strings(\$block, $product);
		} else {
		    # fused multiply-add
		    gf256_vec_fma($block, $product, chr $rand_int);
		}
	    } else {
		my $product = '';
		my @elems = map { ord $_ } (split '', $message[$j]);
		# my $a = $log_table[$rand_int];
		for my $k (0 .. $blocksize - 1) {
		    #		if (!$hacky) {
		    $product .= chr gf256_mul_elems($rand_int, $elems[$k]);
		    #		} else {
		    # use lookup tables directly
		    #		    $product .= 
		    #			chr $exp_table[$a + $log_table[$elems[$k]] + 512];
		    #		}
		}
		fast_xor_strings(\$block, $product)
	    }
	}
	++$j; $j = 0 if $j >= $gen;
    }

    return ($i, $code_vector, $block);
}


# Quick test... just generate packets, but don't try to decode
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

## Initial Results
#
# The basic algorithm with F2 seems sound when it comes to encoding.
# Although an average of alpha/2 blocks are XORed into each block
# that's sent, it's not a huge burden.
#
# As for using GF(2**8), I don't have anything right now that will
# efficiently multiply a vector (such as a source block) by a
# constant. This should be easily remedied, and providing (as seems
# likely) that the resulting XS operation is no more than 5x slower
# than a single XOR, it's likely that using alpha/8 with GF(2**8) is
# going to be faster than using GF(2**1). That's not even taking into
# account the algorithmic complexity curve associated with increasing
# alpha.

## Next steps
#
# I'll ignore GF(2**8) calculations for now. There are three more
# things to do:
#
# 1. handover of the "packet" (i, coding vector, encoded symbol)
#
# 2. the "initial descent" / "on-the-fly decoding" step
#
# 3. solving a complete matrix (which should always succeed)
#
# From here on, we use an optimised representation of the sparse
# matrix, apart from at the very end where we have a step that
# involves the last alpha rows needing to have the full row
# stored/worked on.

# Pivot will return the number of additional pivots required
sub pivot_f2 {

    my ($i, $code, $sym) = @_;

    # Use three "optimisations" here
    #
    # 1. break infinite loop
    #
    # Some elements can't be pivoted because they can't be cancelled
    # out. For example, if our matrix looks like:
    #
    # A + B = x0
    # B + C = x1
    # C + A = x2
    #
    # Then if we receive A + D = x3, the pivot routine will get stuck
    # in an infinite loop because we can never cancel A (or B, or
    # C). Cycle detection is possible, but adds complexity. Instead,
    # use a loop counter and bail if it exceeds a set value. [2015]
    # suggests 2g or 3g, but I think that the "effective aperture"
    # trick from [2006] may reduce the average number of rows updated,
    # allowing us to bring the cutoff down further.
    #
    # 2. memoise operations
    #
    # Some blocks can fail to pivot, as above, so save the workings
    # and apply them only if it succeeds.
    #
    # Note that it seems possible to use memoisation to detect cycles
    # as above. If we find ourselves redoing the same substitution as
    # we had already done previously, it should indicate that we are
    # in an infinite loop.
    #
    # 3. "effective aperture" trick
    #
    # As described in [2006]. We try to maximise the number of zero
    # elements in the array with a heuristic method of counting the
    # number of trailing zero elements of the array row and the
    # element being pivoted. If the element being pivoted has more
    # trailing zeros than the row it's being pivoted into, we swap
    # them, then continue to pivot the row that was evicted.
    #    
    # Other:
    #
    # Also, we can do a peephole optimisation by writing C routines
    # for checking whether a coding vector has become zero and for
    # counting the number of leading and trailing zero bits it has.
    # Also for shifting a string left some number of bits.
    # 

    # First pass of implementation won't implement memoisation. Note
    # that even if we fail to pivot, all changes that are carried out
    # are elementary row operations, so we don't need to undo them.
    # The only impact is that we're doing unnecessary row updates.

    my $tries = 0;
    while (++$tries < $gen * 2) {
	# We can get here if the original i slot was empty, or if we
	# substituted in another row and advanced i accordingly,
	# finding a subsequent empty i' slot.
	if ($filled[$i] == 0) {
	    $filled[$i] = 1;
	    $coding[$i] = $code;
	    $symbol[$i] = $sym;
	    return --$remain
	}

	# My inline C routines for vec_clz and vec_ctz can go off the
	# ends of the array, so before calling them, I must make sure
	# that it's not all zeroes.
	my ($ctz_row, $ctz_code, $clz_code);
	if ($code ne $zero_code) {
	    # decide whether to swap with already pivoted row
	    my $ctz_row  = vec_ctz($coding[$i]);
	    my $ctz_code = vec_ctz($code);
	    if ($ctz_code > $ctz_row) {
		($code, $coding[$i]) = ($coding[$i], $code);
		($sym,  $symbol[$i]) = ($symbol[$i], $sym);
	    }
	    # ... and fall through ...
	} else {
	    # if we get here, it means that we've received a
	    # duplicate, so we can do a self-check to make sure that
	    # the new value and the previously-solved value agree.
	    die "Inconsistent value calculated for row $i\n"
		unless $sym eq $symbol[$i];

	    # In any case, we don't need to do any more work now
	    return $remain;
	}

	# Substitute the existing code vector and symbol into the ones
	# we're trying to insert
	fast_xor_strings(\$code, $coding[$i]);
	fast_xor_strings(\$sym,  $symbol[$i]);

	# The implicit '1' before the aperture has been cancelled, so
	# if the aperture has also gone to zero, we expect the symbol
	# to also be cancelled (another self-check).
	if ($code eq $zero_code) {
	    die "failed: zero code vector => zero symbol\n"
		unless $sym eq $zero_block;
	    return $remain;
	}

	# update the coding vector and i
	$clz_code = vec_clz($code);
	vec_shl($code, $clz_code + 1);
	$i += $clz_code + 1;
	$i -= $gen if $i >= $gen;
    }

    carp "Baled out trying to pivot element after $tries tries\n";
    return $remain;
}

sub solve_f2 {



}


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
    while (*(s++) == (char) 0) { zeroes+=8; }
    if (*s & 0xf0) {
        return zeroes + leading[(*s) >> 4];
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
void vec_ctz(SV *sv) {
    STRLEN len;
    char *s;
    s = SvPV(sv, len);

    s += len - 1;
    int zeroes = 0;
    while (*(s--) == (char) 0) { zeroes+=8; }
    if (*s & 0x0f) {
        return zeroes + trailing[(*s) & 0x0f];
    } else {
        return zeroes + 4 + leading[(*s) >> 4];
    }
}

// Shift a vector (string) left by b bits
void vec_shl(SV *sv, unsigned b) {
    STRLEN len;
    char *s;
    unsigned full_bytes;

    if (b == 0) return;

    s = SvPV(sv, len);
    full_bytes = b >> 3;

    // shifting by full bytes is easy
    if (b & 7 == 0) {
        int c = len - full_bytes;
        while (c--) {
            *s = s[full_bytes];
            ++s;
        }
        while (full_bytes--) { *(s++) = (char) 0; }
        return;
    }

    // or else combine bits from two bytes
    int c = len - full_bytes - 1;
    char l,r;
    b &= 7;
    while (c--) {
        l = s[full_bytes]     <<      b;
        r = s[full_bytes +1 ] >> (8 - b);
        *(s++) = l | r;
    }
    // final byte to shift should be at end of vector
    l = s[full_bytes]  << b;
    *(s++) = l;
    // zero-pad the rest
    while (full_bytes--) { *(s++) = (char) 0; }
}

const static unsigned char exp_table[];
const static signed short log_table[];

unsigned char gf256_mul_elems(unsigned char a, unsigned char b) {
    const static char         *exp =  exp_table + 512;
    const static signed short *log =  log_table;
    return exp[log[a] + log[b]];
}

// multiply all elements of a vector by a constant.

// Inline::C automatically handles passing of strings by value
// (letting us write char *s), but not pass by reference, so we have
// to use SV* instead

void gf256_vec_mul(SV *sv, char val) {
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
void gf256_vec_fma(SV *dv, SV *sv, char val ) {
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

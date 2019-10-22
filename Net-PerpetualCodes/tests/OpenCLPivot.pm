package OpenCLPivot;

use strict;
use warnings;

use OpenCL;
use Math::FastGF2 qw/:ops/;

# An OpenCL implementation of the pivot_f256 routine.
#
# I would like to use Perpetual Codes as part of a multicast/broadcast
# step in a storage application. One or more senders will multicast
# the file, and each (low-powered) storage node will decode it and
# then locally use an IDA-like step to create and store a share on its
# disk.

# The idea is that a multicast/broadcast protocol (with error
# correction), combined with low-powered machines creating their own
# shares should be more effective/efficient than doing share creation
# centrally and then shipping them to the storage nodes, particularly
# if the IDA scheme has high redundancy.
#
# Unfortunately, my previous experiments in multicast transmission of
# a file in this sort of scenario have not worked well:
#
# * udpcast uses a fixed-rated forward error-correction code, and
#   finding suitable values for the FEC and interleaving parameters is
#   non-trivial when working with multiple receivers of varying
#   network and CPU capability. It's also quite fragile in dealing
#   with transient network conditions (temporary congestion). The FEC
#   calculations are also quite expensive.
#
# * Online Codes work best when the file size is very large. It
#   achieves asymptotic best-case reception probability only when the
#   number of blocks being sent approaches ~1e6. It also tends not to
#   be able to decode much of the file until all packets have been
#   received, leading to a very expensive post-reception step that
#   requires working on blocks on disk, with many random reads and
#   writes per received block. The combination of needing to persist
#   received blocks to disk and huge post-reception overhead makes it
#   unsuitable when the receiver is a small board like a Raspberry Pi.
#
# * Perpetual Codes have a couple of major advantages. Firstly, it can
#   be used to transmit smaller chunks of the file (referred to as
#   "generations" in the literature), allowing a more lightweight
#   acknowledgement scheme compared to TCP. Using smaller chunks
#   allows reception and decoding to take place in memory. The second
#   advantage is that most of the decoding work takes place as packets
#   are received, allowing receivers to acknowledge successful receipt
#   of the chunk sooner. There is still a probability that the
#   post-reception part of the algorithm will fail, however, so
#   sending an acknowledgement needs to wait until decoding is
#   complete. However, practically speaking, this will probably not be
#   much of an issue.
#
# Using Perpetual Codes does seem to be the most promising technique.
# However, after implementing it in Perl, and then C, it appears that
# the achievable decoder bandwidth on Raspberry Pi is very poor. Using
# a chunk size of 2Mbytes (2,048 blocks, each 1Kbyte in size) and a
# coding vector of 24 8-bit field elements, the Pi has to do in the
# order of 100,000 XOR operations on 1Kbyte blocks. Even implementing
# this in C, it takes approximately 2.5s to decode the block. For
# comparison, the network bandwitdh is approximately 12.5Mbyte/s,
# whereas 2Mbytes in 2.5s translates to a bandwidth of 0.8Mbyte/s.
#
# There are obviously some things that I can try:
#
# 1. Reduce the generation size and increase the symbol size
#
# Assuming that 2Mbyte is a reasonable low end for the chunk size (to
# make sure that dealing with acknowledgement packets doesn't become
# an issue), increasing the symbol size would let us reduce the
# generation size. The MTU on most LANs is 1500, so after reducing
# this by the UDP header size (22 bytes?), a 2-byte sequence number
# and a 24-byte coding vector, the symbol payload could be increased
# to 1452 bytes, a factor of ~1.4. Thus the generation size could be
# reduced by a similar factor to ~1444.
#
# 2. Reduce the generation size
#
# Assuming everything else is kept the same, reducing the generation
# size to 1024 would mean that the decoder would need to decode and
# acknowledge 1Mb blocks. This should greatly reduce the number of XOR
# operations needed. Indeed, we could also reduce the alpha value
# (size of the coding vector) at the same time, further reducing the
# reception overhead. The trade-off is that twice as many
# acknowledgments need to be sent.
#
# 3. Experiment with field size
#
# I've implemented the [2015] paper using a binary field (F_2) and
# GF(2**8). The latter has much better performance. I haven't yet
# implemented the algorithm for GF(2**4), GF(2**16) or GF(2**32).
# There is probably not a smooth correlation between field size and
# overall algorithmic complexity due to variations in performace of
# the particular implementations of the field arithmetic routines.
#
# For example, it might be that GF(2**4) could even outperform the
# GF(2**8) implementation due to the need for fewer table lookups
# there.
#
# In general, though, increasing the field size does allow for the
# size of the coding vector to be reduced by a more or less
# proportional amount, decreasing the number of vector operations.
#
# 4. Utilise the Pi's GPU
#
# This is the approach that I'm taking here.
#
# I did a quick experiment on a different machine, running a kernel
# that performs 100,000 operations on 1Kbyte vectors. That machine
# actually has 1,024 work units, so it could effectively treat the
# calculation as a 1024-way SIMD operation.
#
# This test took several seconds to complete. I should mention that I
# was using the Perl OpenCL library, though, so perhaps the C calling
# overhead would be much less. However, I suspect that there wouldn't
# be much difference in the overall run time. I also note that the
# Pi's GPU has far fewer work units (effectively 12 * 16), so it would
# be expected to spend more time on the GPU itself, in addition to the
# calling overheads.
#
# Based on that experiment, it seems that simply offloading the vector
# operations will probably increase the overall run time rather than
# improving it.
#
# I've never written OpenCL programs before, but it seems that the
# correct approach to porting the pivot routine is to run the whole
# algorithm in each thread. An alternative way of trying to have task
# parallelism (running several pivot routines in parallel) is not
# really supported by OpenCL, and would require complicated global
# synchronisation to enforce read/write consistency on the coding and
# symbol tables. Also, it's unlikely that this method would get as
# good utilisation of the hardware.
#
# Pi-centric implementation
# =========================
#
# I'll be developing/testing this using Perl's OpenCL module, but for
# actual deployment, I'll shift over to using C. For one thing, it's
# possible that the OpenCL module won't work. Also, since I have a
# complete decoder written in C already, it's better if I stick to
# low-level code throughout.
#
# There are various limitations of the Pi hardware which will inform
# how I implement the OpenCL here. I'll go through them below.
#
# 1. No local/constant memory
#
# All threads have to have a consistent view of the state of the
# algorithm, so they will all need to have their own private copies
# of:
#
# * i, the row number;
# * clz and ctz values;
# * various working variables;
# * the coding vector being pivoted; and
# * (maybe; probably not) the symbol being pivoted
#
# This should all fit in the private memory space of a thread. If we
# have to store the coding vector being pivoted in global memory, it does
# complicate things.
#
# Pivoting relies on a few reads and updates to the (external) coding
# vector table. Each thread will have to read in its own copy of
# these, but only a subset of them will be involved in writing back
# the updated value (swaps). I'm not sure how global barriers/fences
# work when reading in small values (less than the full simd width)
# like this.
#
# Only a subset of threads will be involved in writing to the coding
# vector table, but all will be involved in writing out the symbol.
#
# Since there's no constant space (it's stored in global memory), it
# means that it's probably not going to be a good idea to use table
# lookups for field arithmetic.
#
# We can either fall back to a purely arithmetic routine (involving
# bit operations) or simulate the tables by means of switch/case
# statements. Using switch statements would probably be fine for
# GF(2**8), but there's probably not enough program space to be able
# to embed tables for GF(2**16) or GF(2**32).
#
# Needing to splat the coding vector across all threads does increase
# the memory bandwidth used, but it seems that at least we won't have
# to splat the symbols.
#
# ALU
#
# Each QPU (compute unit) has two ALUs, but only one of them can be
# used for operations such as addition, multiplication or bit
# operations (also, comparisons, I think). There are also extra
# latencies between issuing a calculation and reading the result.
#
# I assume that the OpenCL compiler will take care of writing code
# that minimises pipeline stalls, but that may not be the case, and
# besides, it may not always be possible, especially if I have to use
# dense arithmetical algorithms to do multiplication/xor.
#
# The ALU doesn't have division or modulo operations, but they can be
# avoided. It should have XOR. If not, I'll have a big problem.
#
# Compute Unit (QPU)
#
# There are 12 of these, each implementing virtual 16-way SIMD
# operations. It's "virtual" 16-way because it does 4 cycles, each
# doing a full hardware 4-way operation.
#
# My main concern here is that 12 has factors 2, 2 and 3, meaning that
# we can't divide a block size that's a power of 2 evenly over each
# core. Rather than trying to divide evenly or introducing a factor of
# 3 into the block size, it's easier to have the final thread do a
# little bit less work than the others.
#
# With a block size of 1024, and 192 threads we can have:
#
# 170 threads each working on 6 elements each (10.65 QPUs)
# 1   thread working on 4 elements
# 192 - 171 = 21 threads unused (one QPU + 5 threads)
#
# Other schemes are possible, such as:
#
# * solving 6a + 5b <= 192 and having the first a threads operate on 6
#   elements, the remaining b threads on 5 each
# * an exact digital solution (eg 5,5,5,6,5,5,5...,x), where x <= 6
# * padding the block size to be a multiple of gcd(blocksize,12)
#
# For the sake of simplicity, initially I will go with the first
# scheme that leaves one QPU and 5 threads unused.
#
# Finally, I want my development version to match the Pi's setup as
# closely as possible. Since that machine has 8 compute units
# (compared to the Pi's 12), I will only use 6 of them, with a work
# group size of 32. I'll have to look up the nd_range_kernel
# documentation to see if I can specify this. Perhaps I will need to
# use 2-D addressing.
#
# General OpenCL issues
# =====================
#
# To avoid the need for global synchronisation (so that all threads
# have a consistent view of the data they're working on), I'll take
# these steps:
#
# 1. Changes to the filled[] vector will happen in the host code
#
# 2. Dealing with swapped rows
#
# The routine may read from many different coding vector rows, but it
# may also swap the values with the current symbol. To keep data in a
# consistent state, every swapped row will be stored in a separate
# table. Also, to prevent the same row being swapped twice, implement
# a counter that tracks how far i has advanced beyond its initial
# value. If this counter reaches gen - 1 without finding a hole to
# pivot into, the routine returns the current value of the code vector
# and symbol being pivoted and sets a flag to indicate that pivoting
# was not successful.
#
# The host program will then be responsible for updating all the
# "dirty" rows in the code and symbol tables, and it can retry.
#
# (alternatively, we can start the counter the first time we swap a
# row)
#
# 3 Dealing with writing code, symbol to the table
#
# Since a new code vector can only pivot into a blank row, there is no
# problem with read/write consistency (the final value is write-only,
# and all others are read-only). The filled[] vector, however, should
# not be updated within the code (point 1 above).
#
# 4 Calculations on the code vector
#
# Each thread will have a full private copy of this so that it can perform
# ctz, clz and shift operations locally.
#
# When returning the code vector, only the first alpha threads will
# contribute to writing it.
#

# 
sub new {
    my $class = shift;
    my %o = (
	# algorithm parameters
	alpha     => 24,
	gen       => 2048,
	blocksize => 1024,
	swapsize  => 48,
	# tuning/debugging (sets #define FOO in code, test using #ifdef)
	defines   => [qw/SEND_INV/],
	# variables used in main program
	filled    => undef,
	symbol    => undef,
	coding    => undef,
	# OpenCL parameters?
	@_);

    # OpenCL boilerplate
    my ($platform) = OpenCL::platforms;   # find first platform
    my ($dev,$dev2) = $platform->devices; # find first device of platform
    if (defined $dev2) {
	warn "We have a 2nd device; using it.\n";
	$dev=$dev2;
    }
    my $ctx = $platform->context (undef, [$dev]); # create context out of those
    my $queue = $ctx->queue ($dev);     # create a command queue for the device

    # configure and build the kernel
    my @src_lines = (<DATA>);
    unshift @src_lines, "#define ALPHA     $o{alpha}\n";
    unshift @src_lines, "#define GEN       $o{gen}\n";
    unshift @src_lines, "#define SWAPSIZE  $o{swapsize}\n";
    unshift @src_lines, "#define BLOCKSIZE $o{blocksize}\n";
    unshift @src_lines, "#define $_\n" for (@{$o{defines}});
    my $src = join("", @src_lines);

    print $src;
    
    my $prog = $ctx->build_program ($src);
    my $kernel = $prog->kernel ("pivot_gf8");

    # Some parameters won't change between calls

    # It seems that MEM_COPY_HOST_PTR will copy the data from the host
    # to the device. I can't see anything that defines the type of
    # memory used on the device, though. Later on I can do
    # benchmarking to see if explicitly copying into private memory is
    # faster or slower.

    # Name bufs according to kernel parameters; anything set to undef
    # must be set up in pivot.

    # In addition, pivot needs to call $queue->write_buffer to put
    # values into the host_code and host_sym buffers.
    my %bufs;
    $bufs{host_i}     = undef;	# set with $kernel->set_uint($index,$value)
    $bufs{host_code}  = $ctx->buffer (0, $o{alpha});
    $bufs{host_sym}   = $ctx->buffer (0, $o{blocksize});

    $bufs{code_swap}  = $ctx->buffer (0, $o{swapsize} * $o{alpha});
    $bufs{sym_swap}   = $ctx->buffer (0, $o{swapsize} * $o{blocksize});
    # swaps is an output variable
    $bufs{swaps}      = $ctx->buffer (0, OpenCL::SIZEOF_UINT); # should be 4 bytes!

    # filled is an array in my Perl program, but it's better to use a
    # string array or, better yet, a bit vector
    my $filled_bv = (chr 0) x ($o{gen} / 8);

    # I think I need MEM_USE_HOST_PTR so kernel sees latest data
    $bufs{filled_bv}  = $ctx->buffer_sv (OpenCL::MEM_USE_HOST_PTR, $filled_bv);

    my $inv_table = chr 0;
    $inv_table .= chr(gf2_inv(8,$_)) for (1..255);
    $bufs{host_inv}   = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, $inv_table);
    
    $bufs{new_i}      = $ctx->buffer (0, OpenCL::SIZEOF_UINT); # should be 4 bytes!
    $bufs{new_code}   = $ctx->buffer (0, $o{alpha});	
    $bufs{new_sym}    = $ctx->buffer (0, $o{blocksize});
    $bufs{rc}         = $ctx->buffer (0, OpenCL::SIZEOF_UINT); # should be 4 bytes!
    
    
    my $self = {
	platform  => $platform,
	dev       => $dev,
	ctx       => $ctx,
	queue     => $queue,
	prog      => $prog,
	kernel    => $kernel,
	filled_bv => $filled_bv,
	symbol    => $o{symbol},
	coding    => $o{coding},
	remain    => $o{gen},
	options   => \%o,
	buffers   => \%bufs,
    };
    bless $self, $class;
}

sub pivot {
    my $self = shift;
    my ($i, $code, $sym) = @_;

    
    # No point in doing this in OpenCL kernel
    if (0 == vec($self->{filled_bv}, $i, 1)) {
	vec($self->{filled_bv}, $i, 1) = 1;
	$self->{coding}->[$i] = $code;
	$self->{symbol}->[$i] = $sym;
	return --($self->{remain});
    }
	

}

# Since the Pi QPUs don't have private constant storage space, and I
# don't know the size of the private memory, I'll probably have to
# calculate gf8 multiplications explicitly. This routine tests the
# algorithm that I'm using, comparing the values with those from
# Math::FastGF2

# Polynomial is 0x11b = 0100011011, so rather than upgrading to shorts,
# shift the poly right = 010001101 + 1 remainder = 0x8d
#
# Now do this XOR before the shift and add in the remainder afterward
#
# I'm not sure if there's anything to be gained by this
# "optimisation", though. It adds an extra 7 additions compared to a
# few type casts.

sub _long_mul_gf8_v1 {
    my ($a,$b,$prod) = @_;
    # Optionally, return immediately if either operand is 0 or 1
    if (0) {
	return $a ? $b : 0 if ($a < 2);
	return $b ? $a : 0 if ($b < 2);
    }

    $prod = ($b & 1) ? $a : 0;
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 2);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 4);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 8);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 16);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 32);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 64);
    # Optimise last bit: don't update a unless we need to
    return ($b & 128) == 0 ? $prod :
	($prod ^ (($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1));
}

# This is the original version that uses 0x11b
sub _long_mul_gf8_v2 {
    my ($a,$b,$prod) = @_;
    # Optionally, return immediately if either operand is 0 or 1
    if (0) {
	return $a ? $b : 0 if ($a < 2);
	return $b ? $a : 0 if ($b < 2);
    }

    $prod = ($b & 1) ? $a : 0;
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 2);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 4);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 8);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 16);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 32);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 64);
    # Optimise last bit: don't update a unless we need to
    return ($b & 128) == 0 ? $prod :
	($prod ^ (($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1)));
}

sub test_gf8_maths {
    for my $i (0..255) {
	for my $j (0..255) {
	    my $correct = gf2_mul(8,$i,$j);
	    my $maybe = _long_mul_gf8_v1($i,$j);
	    die "_long_mul_gf8_v1 incorrect with $i x $j\n"
		if $maybe != $correct;
	}
    }
    warn "v1 was fully correct\n";
    for my $i (0..255) {
	for my $j (0..255) {
	    my $correct = gf2_mul(8,$i,$j);
	    my $maybe = _long_mul_gf8_v2($i,$j);
	    die "_long_mul_gf8_v2 incorrect with $i x $j\n"
		if $maybe != $correct;
	}
    }
    warn "v2 was fully correct\n";
}

1;

__DATA__

// prefix this code with #define lines for:
//
// ALPHA
// GEN
// BLOCKSIZE
// SWAPSIZE
//
// (plus any flags for conditional compilation with #ifdef FLAG .. #endif)

kernel void pivot_gf8(
    // inputs (all read-only)
           unsigned       host_i,
    global unsigned char *host_code,
    global unsigned char *host_sym,
    global unsigned char *coding,
    global unsigned char *symbol,
    global unsigned char *filled,

    // input-output (host allocates, we write)
    global unsigned char *code_swap,
    global unsigned char *sym_swap,

    // outputs
    global unsigned      *new_i,
    global unsigned char *new_code,
    global unsigned char *new_sym,
    global unsigned      *swaps,
    global unsigned      *rc

    // other inputs (lookup tables)

    // I'm putting these at the end so that I can use conditional
    // compilation to enable/disable them without messing up parameter
    // indices. Listing in order from most important to least. Note
    // the comma at the start of these blocks.

#ifdef SEND_INV
    , global unsigned char *host_inv
#endif
    // will not use optimised tables since they are fairly large
#ifdef SEND_LOG_EXP
    , global unsigned char *host_log
    , global unsigned char *host_exp
#endif
) {
    int id = get_global_id(0);
    unsigned tries = 0;
    unsigned i = host_i;
    unsigned char code[ALPHA];
    unsigned char sym[BLOCKSIZE];
#ifdef SEND_INV
    unsigned char inv[256];
#endif
    unsigned char *cp, *rp, *bp;
    unsigned char cancelled, zero_sym;

    // copy code, sym [and inv] into private storage


    return;

}

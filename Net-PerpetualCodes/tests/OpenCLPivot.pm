package OpenCLPivot;

use strict;
use warnings;

use OpenCL;
use Math::FastGF2 qw/:ops/;

our $debug = 0;

# Reserve some rc slots for debugging
our $retvals = 8;
# 0 - main rc
# 1 - symbol cancel problem (fatal error)
# 2 - number of filled slots encountered
# 3 - last ctz_code
# 4 - last ctz_row
# 5 - bit mask
# 6 - maths error
# 7 - inverse

sub check_symbol_f256 {
    my ($self,$i,$code,$sym,$msg) = @_;
    my $message = $self->{message};
    my $fma =     $self->{fma};
    $msg = "" unless defined $msg;
    warn "Checking: i is $i\n";
    warn "Checking: Code is " . (unpack "H*", $code) . "\n";
    my $check = "$message->[$i]";
    my $k;
    for my $byte (0..$self->{alpha}-1) {
	my $j = ($i + $byte + 1) % $self->{gen};
	$k = substr $code, $byte, 1;
	next if "\0" eq $k;
	my $khex = unpack "H2", $k;
	#warn "Checking: XORing in $khex times \$message[$j]\n" if $debug > 2;
	$fma->($check, "$message->[$j]", ord $k);
    }
    die "Symbol not correct. $msg\n" unless $sym eq $check;
}

sub new {
    my $class = shift;
    my %o = (
	# algorithm parameters
	alpha     => 24,
	gen       => 2048,
	blocksize => 1024,
	swapsize  => 48,
	# tuning/debugging (sets #define FOO in code, test using #ifdef)
	defines   => [qw/SWITCH_TABLES/],
	# variables used in main program
	filled    => undef,
	symbol    => undef,
	coding    => undef,
	# OpenCL parameters?
	groups    => 6,         # how many groups?
	groupsize => 32,	# how many threads per group?
	worksize  => 6,		# how many bytes does each work item process?
	# The above should work for block size of 1024;
	# 6 * 32 * 6 = 1152, so 6*32 threads each working on 6 bytes
	# is more threads than we need to cover 1024 byte symbols...
	#
	# if message is passed in, we can use it to check symbols
	message   => undef,
	fma       => undef,
	@_);

    # OpenCL boilerplate
    my ($platform) = OpenCL::platforms;   # find first platform
    my ($dev,$dev2) = $platform->devices; # find first device of platform
    if (defined $dev2) {
	warn "We have a 2nd device; using it.\n";
	$dev=$dev2;
    }
    # Create context from the above
    # my $ctx = $platform->context (undef, [$dev]);

    warn "OpenCL Platform: ". $platform->name() . "\n";
    warn "Device: " . $dev->name() . "\n";

    # Alternative: Make sure that we're running on GPU
    my $ctx = $platform->context_from_type (undef,OpenCL::DEVICE_TYPE_GPU);
    my $queue = $ctx->queue ($dev);     # create a command queue for the device

    my $pv = $dev->info(OpenCL::DEVICE_TYPE);
    $pv = ord (substr $pv, 0, 1);
    warn "Device appears to be a GPU\n" if $pv &OpenCL::DEVICE_TYPE_GPU;

    # configure and build the kernel
    my @src_lines = (<DATA>);
    unshift @src_lines, "#define ALPHA     $o{alpha}\n";
    unshift @src_lines, "#define GEN       $o{gen}\n";
    unshift @src_lines, "#define SWAPSIZE  $o{swapsize}\n";
    unshift @src_lines, "#define BLOCKSIZE $o{blocksize}\n";
    unshift @src_lines, "#define WORKSIZE  $o{worksize}\n"; # stride
    unshift @src_lines, "#define $_\n" for (@{$o{defines}});
    my $src = join("", @src_lines);

    # print $src;
    
    my $prog = $ctx->build_program ($src);
    my $kernel = $prog->kernel ("pivot_gf8");

    my $threads = $o{groups} * $o{groupsize};
    
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
    $bufs{i}          = undef;
    $bufs{host_code}  = $ctx->buffer (0, $o{alpha} * $threads);
    $bufs{host_sym}   = $ctx->buffer (0, $o{blocksize});

    # I don't think that OpenCL guarantees that allocated buffers will
    # be zeroed, so do it explicitly for some buffers.
    my $zero_coding = "\0" x ($o{gen} * $o{alpha});
    my $zero_symbol = "\0" x ($o{gen} * $o{blocksize});

    # Allocate the coding and symbol arrays
    $bufs{coding}     = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR,
					 $zero_coding);
    $bufs{symbol}     = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR,
					 $zero_symbol);

    # filled was an array in my Perl program, but it's better to use a
    # string array or, better yet, a bit vector
    my $filled = "\0" x ($o{gen} / 8);

    
    # Giving up on trying to map filled
    $bufs{filled}     = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, $filled);
    # $bufs{filled}     = $ctx->buffer (0, ($o{gen} / 8));

    # Swap stack-related (no need to zero these)
    $bufs{i_swap}     = $ctx->buffer (0, $o{swapsize} * OpenCL::SIZEOF_UINT);
    $bufs{code_swap}  = $ctx->buffer (0, $o{swapsize} * $o{alpha});
    $bufs{sym_swap}   = $ctx->buffer (0, $o{swapsize} * $o{blocksize});

    # swaps is an output-only variable
    $bufs{swaps}      = $ctx->buffer (0, OpenCL::SIZEOF_UINT); # 4 bytes

    # Outputs (no need to zero)
    
    $bufs{new_i}      = $ctx->buffer (0, OpenCL::SIZEOF_UINT); # 4 bytes
    $bufs{new_code}   = $ctx->buffer (0, $o{alpha});
    $bufs{new_sym}    = $ctx->buffer (0, $o{blocksize});
    $bufs{rc_vec}     = $ctx->buffer (0, $retvals);

    # i -> set_uint(0, i)
    $kernel->set_buffer(1,  $bufs{host_code});
    $kernel->set_buffer(2,  $bufs{host_sym});
    $kernel->set_buffer(3,  $bufs{coding});
    $kernel->set_buffer(4,  $bufs{symbol});
    $kernel->set_buffer(5,  $bufs{filled});
    $kernel->set_buffer(6,  $bufs{i_swap});
    $kernel->set_buffer(7,  $bufs{code_swap});
    $kernel->set_buffer(8,  $bufs{sym_swap});
    $kernel->set_buffer(9,  $bufs{new_i});
    $kernel->set_buffer(10, $bufs{new_code});
    $kernel->set_buffer(11, $bufs{new_sym});
    $kernel->set_buffer(12, $bufs{swaps});
    $kernel->set_buffer(13, $bufs{rc_vec});
    
    my $self = {
	%o,
	platform  => $platform,
	dev       => $dev,
	ctx       => $ctx,
	queue     => $queue,
	prog      => $prog,
	kernel    => $kernel,
	threads   => $threads,
	filled    => $filled,
	symbol    => $o{symbol},
	coding    => $o{coding},
	remain    => $o{gen},
	buffers   => \%bufs,
    };
    bless $self, $class;
}

sub pivot {
    my $self = shift;
    my ($i, $code, $sym) = @_;

    my $alpha     = $self->{alpha};
    my $gen       = $self->{gen};
    my $blocksize = $self->{blocksize};

    my $kernel = $self->{kernel};
    my $bufs   = $self->{buffers};
    my $queue  = $self->{queue};

    my $groups    = $self->{groups};
    my $groupsize = $self->{groupsize};
    my $threads   = $self->{threads};
    my $rvec = pack "C*", 0xff,(0) x ($retvals - 1);

    my ($new_i, $new_code, $new_sym, $rc_str, $swaps);

    if (0) {
	# We get 'Use of uninitialized value in subroutine entry' below if
	# we don't specify the size
	my $fill_size = $gen / 8;
	die "bufs->{filled} not defined\n" unless defined $bufs->{filled};
	my $filled = $queue->map_buffer(
	    $bufs->{filled} , 1,
	    OpenCL::MAP_READ|OpenCL::MAP_WRITE,
	0, $fill_size
	);
    }
    my ($byte, $mask);

    my @status = qw(success cancelled memory stack tries);
    $status[255] = "undefined";

    die "Wrong code length: " . length($code) . "\n" 
	if length($code) != $alpha;
    # $code =~ m|^.*?(\0*)$|;
    # print "Has " . length($1) . " trailing zeros\n";

    # Most things are now stored in OpenCL buffers so we need
    # read_buffer and write_buffer to access them

    my $check_for_hole = 1;
    warn "accel->pivot called with i=$i\n" if $debug;
    my $retries = 2;

    while (1) {
	# Can we access filled on host/device? Do they map to the
	# same memory?
	if ($debug) {
	    warn "RC: Perl Pivot [i=$i]\n";
	    warn "Attempting to pivot into row $i (Perl)\n";
	}
	($byte, $mask) = ($i >> 3, 1 << ($i & 7));
	warn "Byte $byte; Mask $mask (Perl)\n" if $debug;
	my $bitvec;
	$queue->read_buffer($bufs->{filled}, 1, $byte, 1, $bitvec);
	$bitvec = ord $bitvec;
	warn "Bitvec $bitvec\n" if $debug;
	if (0 == ($bitvec & $mask)) {
	    warn "Filling hole in row $i (Perl)\n" if $debug; 
	    $bitvec = chr ($bitvec | $mask);
	    $queue->write_buffer($bufs->{filled},1, $byte, $bitvec);
	    $queue->write_buffer($bufs->{coding},1,$i * $alpha, $code);
	    $queue->write_buffer($bufs->{symbol},1,$i * $blocksize, $sym);
	    return --($self->{remain});
	}

	while ($retries--) {
	    warn "retries is now $retries (OpenCL)\n" if $debug;
	    # Set up to call pivot kernel
	    $kernel->set_uint(0, $i);

	    $queue->write_buffer($bufs->{host_code},1,0,"$code" x $threads);
	    $queue->write_buffer($bufs->{host_sym}, 1,0,$sym);

	    # {coding}, {symbol} and {filled} shouldn't need setup

	    # swap-related buffers shouldn't need setup

	    # output i, code and sym shouldn't need setup

	    $queue->write_buffer($bufs->{rc_vec},1,0,$rvec);

	    #$queue->barrier;
	    $queue->nd_range_kernel($kernel, undef, [$threads], [$groupsize]);
	    $queue->barrier;

	    # Before I go on, just examine the outputs
	    $queue->read_buffer($bufs->{rc_vec},1,0,$retvals,$rc_str);
	    my @rc = unpack("C*", $rc_str);

	    $queue->read_buffer($bufs->{swaps},1,0,4,$swaps);
	    $swaps = unpack("V", $swaps);

	    $queue->read_buffer($bufs->{new_i},1,0,4,$new_i);
	    $new_i = unpack("V", $new_i);
	    
	    $queue->read_buffer($bufs->{new_code},1,0,$alpha,$new_code);
	    $queue->read_buffer($bufs->{new_sym},1,0,$blocksize,$new_sym);

	    warn "RC: " . (join ", ", @rc) .
		" ($status[$rc[0]] old_i=$i; new_i=$new_i)\n"  if $debug;

	    # unrecoverable error
	    if ($rc[6]) {
		die "Maths error";
	    }
	    # in case of maths error, the following are meaningless
	    if ($debug) {
		warn "New i: $new_i\n";
		warn "Swaps: $swaps\n";
	    }
	    if ($rc[1]) {
		die "Symbol wasn't cancelled even though code was\n";
	    }

	    # If no error, we should update dirty rows from swap
	    my $sp = 0;
	    while ($sp < $swaps) {
		my ($swap_i,$swap_code,$swap_sym);
		$queue->read_buffer(
		    $bufs->{i_swap},1,
		    $sp*4,4,$swap_i);
		$swap_i = unpack("V", $swap_i);
		warn "Finishing swap of row $swap_i\n"  if $debug;
		$queue->read_buffer(
		    $bufs->{code_swap},1,
		    $sp*$alpha,$alpha,$swap_code);
		$queue->read_buffer(
		    $bufs->{sym_swap},1,
		    $sp*$blocksize,$blocksize,$swap_sym);

		if (defined ($self->{message}) and $debug > 1) {
		    $self->check_symbol_f256($swap_i,$swap_code,$swap_sym,
		    "Row $swap_i taken from swap stack is invalid.");
		}

		# Write code,sym into the correct row
		$queue->write_buffer(
		    $bufs->{coding},1,
		    $swap_i * $alpha, $swap_code);
		$queue->write_buffer(
		    $bufs->{symbol},1,
		    $swap_i * $blocksize, $swap_sym);
		++$sp;
	    }
	    # Seems like we should also update i,code,sym
	    my $old_i = $i;
	    ($i,$code,$sym) = ($new_i,$new_code,$new_sym);

	    warn "Checking return code\n" if $debug;
	    # Decide what to do based on main rc
	    if ($rc[0] == 1) {
		# cancelled, so no further action required
		warn "RC: Cancelled [i=$i]\n" if $debug;
		return $self->{remain};

	    }

	    # only check code,symbol if it wasn't cancelled
	    if (defined ($self->{message}) and $debug > 1 ) {
		$self->check_symbol_f256($i,$code,$sym,
                   "code/symbol $i returned from pivot kernel.");
	    }

	    if ($rc[0] == 0) {
		# success, so place new values in table
		warn "RC: Success [old_i=$old_i; i=$i]\n" if $debug;
		($byte, $mask) = ($i >> 3, 1 << ($i & 7));
		warn "Byte $byte; Mask $mask (OpenCL)\n" if $debug;
		my $bitvec;
		$queue->read_buffer($bufs->{filled}, 1, $byte, 1, $bitvec);
		$bitvec = ord $bitvec;
		warn "Bitvec $bitvec\n" if $debug;

		warn "Filling hole in row $i (OpenCL)\n" if $debug;

		die "Succeeded in pivoting, but row $i is full\n"
		    if (1 == ($bitvec & $mask));

		# Escape this inner loop and go back to Perl
		last;

		warn "Filling hole in row $i (OpenCL)\n" if $debug; 
		$bitvec = pack "C", ($bitvec | $mask);
		
		$queue->write_buffer($bufs->{filled},1, $byte, $bitvec);
		$queue->write_buffer($bufs->{coding},1,$i * $alpha, $code);
		$queue->write_buffer($bufs->{symbol},1,$i * $blocksize, $sym);
		return --($self->{remain});

	    } elsif ($rc[0] == 4) {
		warn "RC: Tries [i=$i]\n" if $debug;
		# tries, so warn and abandon
		warn "Exceeded max tries; abandoning attempt to pivot\n";
		return $self->{remain};
	    } else {
		warn "RC: Memory|Stack [i=$i]\n";
		# memory or stack: try again with updated values
		warn "Memory or stack: retrying\n";
	    }
	}
    }
    die;
}


1;

__DATA__

// prefix this code with #define lines for:
//
// ALPHA
// GEN
// BLOCKSIZE
// SWAPSIZE
// WORKSIZE
//
// (plus any flags for conditional compilation with #ifdef FLAG .. #endif)

#include "OpenCLPivot.c"

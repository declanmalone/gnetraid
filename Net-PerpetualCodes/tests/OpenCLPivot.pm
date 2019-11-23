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

our $log_table = pack "C256", (
    0, 255, 25, 1, 50, 2, 26, 198,
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
);

our $exp_table = pack "C256", (
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
    28, 36, 108, 180, 199, 82, 246, 1
);

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
	swapsize  => 128,
	# tuning/debugging (sets #define FOO in code, test using #ifdef)
	# Main options: LONG_MULTIPLY | SWITCH_TABLES | HOST_TABLES
	defines   => [qw/LONG_MULTIPLY HOST_TABLES/], 
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

    my %hashdef = ();
    $hashdef{$_} = 1 for (@{$o{defines}});
    my @logs = (0);
    my @exps = (0);

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

    # log/exp buffers
    if ($hashdef{HOST_TABLES}) {
	warn "Log table of size " . length($log_table) . "\n";
	$bufs{host_log} = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, $log_table);
	warn "Exp table of size " . length($exp_table) . "\n";
	$bufs{host_exp} = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, $exp_table);
    }

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
    if ($hashdef{HOST_TABLES}) {
	$kernel->set_buffer(14, $bufs{host_log});
	$kernel->set_buffer(15, $bufs{host_exp});
    }
    
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
	    if ($swaps) {
		warn "Need to swap $swaps rows back into tables\n"
		    if $debug;

		my (@is,@codes,@syms,$buf);

		$queue->read_buffer($bufs->{i_swap},1,
				    0, $swaps * OpenCL::SIZEOF_UINT,$buf);
		@is = unpack("V*", $buf);

		$queue->read_buffer($bufs->{code_swap},1,
				    0 ,$swaps * $alpha, $buf);
		@codes = unpack("a[$alpha]" x $swaps, $buf);

		$queue->read_buffer($bufs->{sym_swap},1,
				    0 ,$swaps * $blocksize,$buf);
		@syms = unpack("a[$blocksize]" x $swaps, $buf);

		my ($this_i, $this_code, $this_sym);
		while (@is) {
		    $this_i    = shift @is;
		    $this_code = shift @codes;
		    $this_sym  = shift @syms;

		    warn "Finishing swap of row $this_i\n" if $debug;

		    if (defined ($self->{message}) and $debug > 1) {
			$self->check_symbol_f256(
			    $this_i,$this_code,$this_sym,
			    "Row $this_i taken from swap stack is invalid.");
		    }

		    # Write code,sym into the correct row
		    $queue->write_buffer(
			$bufs->{coding},1,
			$this_i * $alpha, $this_code);
		    $queue->write_buffer(
			$bufs->{symbol},1,
			$this_i * $blocksize, $this_sym);
		}
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

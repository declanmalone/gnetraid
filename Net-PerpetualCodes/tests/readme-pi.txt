
# An OpenCL implementation of the pivot_f256 routine.

I would like to use Perpetual Codes as part of a multicast/broadcast
step in a storage application. One or more senders will multicast
the file, and each (low-powered) storage node will decode it and
then locally use an IDA-like step to create and store a share on its
disk.

The idea is that a multicast/broadcast protocol (with error
correction), combined with low-powered machines creating their own
shares should be more effective/efficient than doing share creation
centrally and then shipping them to the storage nodes, particularly
if the IDA scheme has high redundancy.

Unfortunately, my previous experiments in multicast transmission of
a file in this sort of scenario have not worked well:

* udpcast uses a fixed-rated forward error-correction code, and
  finding suitable values for the FEC and interleaving parameters is
  non-trivial when working with multiple receivers of varying
  network and CPU capability. It's also quite fragile in dealing
  with transient network conditions (temporary congestion). The FEC
  calculations are also quite expensive.

* Online Codes work best when the file size is very large. It
  achieves asymptotic best-case reception probability only when the
  number of blocks being sent approaches ~1e6. It also tends not to
  be able to decode much of the file until all packets have been
  received, leading to a very expensive post-reception step that
  requires working on blocks on disk, with many random reads and
  writes per received block. The combination of needing to persist
  received blocks to disk and huge post-reception overhead makes it
  unsuitable when the receiver is a small board like a Raspberry Pi.

* Perpetual Codes have a couple of major advantages. Firstly, it can
  be used to transmit smaller chunks of the file (referred to as
  "generations" in the literature), allowing a more lightweight
  acknowledgement scheme compared to TCP. Using smaller chunks
  allows reception and decoding to take place in memory. The second
  advantage is that most of the decoding work takes place as packets
  are received, allowing receivers to acknowledge successful receipt
  of the chunk sooner. There is still a probability that the
  post-reception part of the algorithm will fail, however, so
  sending an acknowledgement needs to wait until decoding is
  complete. However, practically speaking, this will probably not be
  much of an issue.

Using Perpetual Codes does seem to be the most promising technique.
However, after implementing it in Perl, and then C, it appears that
the achievable decoder bandwidth on Raspberry Pi is very poor. Using
a chunk size of 2Mbytes (2,048 blocks, each 1Kbyte in size) and a
coding vector of 24 8-bit field elements, the Pi has to do in the
order of 100,000 XOR operations on 1Kbyte blocks. Even implementing
this in C, it takes approximately 2.5s to decode the block. For
comparison, the network bandwitdh is approximately 12.5Mbyte/s,
whereas 2Mbytes in 2.5s translates to a bandwidth of 0.8Mbyte/s.

There are obviously some things that I can try:

1. Reduce the generation size and increase the symbol size

Assuming that 2Mbyte is a reasonable low end for the chunk size (to
make sure that dealing with acknowledgement packets doesn't become
an issue), increasing the symbol size would let us reduce the
generation size. The MTU on most LANs is 1500, so after reducing
this by the UDP header size (22 bytes?), a 2-byte sequence number
and a 24-byte coding vector, the symbol payload could be increased
to 1452 bytes, a factor of ~1.4. Thus the generation size could be
reduced by a similar factor to ~1444.

2. Reduce the generation size

Assuming everything else is kept the same, reducing the generation
size to 1024 would mean that the decoder would need to decode and
acknowledge 1Mb blocks. This should greatly reduce the number of XOR
operations needed. Indeed, we could also reduce the alpha value
(size of the coding vector) at the same time, further reducing the
reception overhead. The trade-off is that twice as many
acknowledgments need to be sent.

3. Experiment with field size

I've implemented the [2015] paper using a binary field (F_2) and
GF(2**8). The latter has much better performance. I haven't yet
implemented the algorithm for GF(2**4), GF(2**16) or GF(2**32).
There is probably not a smooth correlation between field size and
overall algorithmic complexity due to variations in performace of
the particular implementations of the field arithmetic routines.

For example, it might be that GF(2**4) could even outperform the
GF(2**8) implementation due to the need for fewer table lookups
there.

In general, though, increasing the field size does allow for the
size of the coding vector to be reduced by a more or less
proportional amount, decreasing the number of vector operations.

4. Utilise the Pi's GPU

This is the approach that I'm taking here.

I did a quick experiment on a different machine, running a kernel
that performs 100,000 operations on 1Kbyte vectors. That machine
actually has 1,024 work units, so it could effectively treat the
calculation as a 1024-way SIMD operation.

This test took several seconds to complete. I should mention that I
was using the Perl OpenCL library, though, so perhaps the C calling
overhead would be much less. However, I suspect that there wouldn't
be much difference in the overall run time. I also note that the
Pi's GPU has far fewer work units (effectively 12 * 16), so it would
be expected to spend more time on the GPU itself, in addition to the
calling overheads.

Based on that experiment, it seems that simply offloading the vector
operations will probably increase the overall run time rather than
improving it.

I've never written OpenCL programs before, but it seems that the
correct approach to porting the pivot routine is to run the whole
algorithm in each thread. An alternative way of trying to have task
parallelism (running several pivot routines in parallel) is not
really supported by OpenCL, and would require complicated global
synchronisation to enforce read/write consistency on the coding and
symbol tables. Also, it's unlikely that this method would get as
good utilisation of the hardware.

## Pi-centric implementation

I'll be developing/testing this using Perl's OpenCL module, but for
actual deployment, I'll shift over to using C. For one thing, it's
possible that the OpenCL module won't work. Also, since I have a
complete decoder written in C already, it's better if I stick to
low-level code throughout.

There are various limitations of the Pi hardware which will inform
how I implement the OpenCL here. I'll go through them below.

1. No local/constant memory

All threads have to have a consistent view of the state of the
algorithm, so they will all need to have their own private copies
of:

* i, the row number;
* clz and ctz values;
* various working variables;
* the coding vector being pivoted; and
* (maybe; probably not) the symbol being pivoted

This should all fit in the private memory space of a thread. If we
have to store the coding vector being pivoted in global memory, it does
complicate things.

Pivoting relies on a few reads and updates to the (external) coding
vector table. Each thread will have to read in its own copy of
these, but only a subset of them will be involved in writing back
the updated value (swaps). I'm not sure how global barriers/fences
work when reading in small values (less than the full simd width)
like this.

Only a subset of threads will be involved in writing to the coding
vector table, but all will be involved in writing out the symbol.

Since there's no constant space (it's stored in global memory), it
means that it's probably not going to be a good idea to use table
lookups for field arithmetic.

We can either fall back to a purely arithmetic routine (involving
bit operations) or simulate the tables by means of switch/case
statements. Using switch statements would probably be fine for
GF(2**8), but there's probably not enough program space to be able
to embed tables for GF(2**16) or GF(2**32).

Needing to splat the coding vector across all threads does increase
the memory bandwidth used, but it seems that at least we won't have
to splat the symbols.

Addendum: trade-offs involved with copying structures into private
memory

My instinct is that the routine should work better if we have
private lookup tables, but you also have to look at the cost of
copying the data plus how often we will look up those tables.

Initially, I was thinking that the inverse table was the most
important structure to copy over, since it's a bit awkward to
calculate it "manually".

Every time the pivot routine loops, it has to do:

* an inversion on a single field element   (1 operation)
* a fused multiply-add on the code vector  (alpha operations)
* a fused multiply-add on the symbol       (blocksize operations)

With parameters alpha = 24, gen = 2048 and blocksize = 1024,
profiling shows that these are in the region of:

    42676 / 2248 = 18

calls to each of those routines. This means that copying the inverse
table (256 elements) would probably not be worthwhile unless global
memory access (latency) is a factor of 16x worse than accessing
private memory.

On the other hand, copying over (abbreviated) exp and log tables
should quickly recoup the initial copy overhead, since even doing a
single fma on code and symbol costs 3x (alpha + blocksize) memory
reads (two log table lookups, plus an exp table lookup), which is
roughly 6 times more than the cost of copying the log, exp tables.

The other option, which I'm leaning towards implementing first, is
to embed the lookup tables in the code by means of a switch
statement. I'm not sure about the maximum kernel code size, or
whether the compiler will generate space-efficient code for this
(ideally it would be able to use a computed jump), but hopefully
this will work on the Pi.

Another note on this: embedding exp/log tables as a switch statement
(or even transferring them to private arrays) lets us calculate
inverses, too, so a separate inv table wouldn't be needed. And if we
can embed the tables, we can simplify the calling interface, too.

ALU

Each QPU (compute unit) has two ALUs, but only one of them can be
used for operations such as addition, multiplication or bit
operations (also, comparisons, I think). There are also extra
latencies between issuing a calculation and reading the result.

I assume that the OpenCL compiler will take care of writing code
that minimises pipeline stalls, but that may not be the case, and
besides, it may not always be possible, especially if I have to use
dense arithmetical algorithms to do multiplication/xor.

The ALU doesn't have division or modulo operations, but they can be
avoided. It should have XOR. If not, I'll have a big problem.

Compute Unit (QPU)

There are 12 of these, each implementing virtual 16-way SIMD
operations. It's "virtual" 16-way because it does 4 cycles, each
doing a full hardware 4-way operation.

My main concern here is that 12 has factors 2, 2 and 3, meaning that
we can't divide a block size that's a power of 2 evenly over each
core. Rather than trying to divide evenly or introducing a factor of
3 into the block size, it's easier to have the final thread do a
little bit less work than the others.

With a block size of 1024, and 192 threads we can have:

    170 threads each working on 6 elements each (10.65 QPUs)
    1   thread working on 4 elements
    192 - 171 = 21 threads unused (one QPU + 5 threads)

Other schemes are possible, such as:

* solving 6a + 5b <= 192 and having the first a threads operate on 6
  elements, the remaining b threads on 5 each
* an exact digital solution (eg 5,5,5,6,5,5,5...,x), where x <= 6
* padding the block size to be a multiple of gcd(blocksize,12)

For the sake of simplicity, initially I will go with the first
scheme that leaves one QPU and 5 threads unused.

Finally, I want my development version to match the Pi's setup as
closely as possible. Since that machine has 8 compute units
(compared to the Pi's 12), I will only use 6 of them, with a work
group size of 32. I'll have to look up the nd_range_kernel
documentation to see if I can specify this. Perhaps I will need to
use 2-D addressing.

## General OpenCL issues

To avoid the need for global synchronisation (so that all threads
have a consistent view of the data they're working on), I'll take
these steps:

1. Changes to the filled[] vector will happen in the host code

2. Dealing with swapped rows

The routine may read from many different coding vector rows, but it
may also swap the values with the current symbol. To keep data in a
consistent state, every swapped row will be stored in a separate
table. Also, to prevent the same row being swapped twice, implement
a counter that tracks how far i has advanced beyond its initial
value. If this counter reaches gen - 1 without finding a hole to
pivot into, the routine returns the current value of the code vector
and symbol being pivoted and sets a flag to indicate that pivoting
was not successful.

The host program will then be responsible for updating all the
"dirty" rows in the code and symbol tables, and it can retry.

(alternatively, we can start the counter the first time we swap a
row)

3 Dealing with writing code, symbol to the table

Since a new code vector can only pivot into a blank row, there is no
problem with read/write consistency (the final value is write-only,
and all others are read-only). The filled[] vector, however, should
not be updated within the code (point 1 above).

4 Calculations on the code vector

Each thread will have a full private copy of this so that it can perform
ctz, clz and shift operations locally.

When returning the code vector, only the first alpha threads will
contribute to writing it.

## Results

As of commit 82e230f0c29392d4bea10d12781ca4bedf85b41a the code seems
to be working fine, but it's taking far too long.

Checking the output of an NYTProf profile of the code, the bulk of the
time is being spent here:

    270ms   $queue->nd_range_kernel($kernel, undef, [$threads], [$groupsize]);
    2.98ms  $queue->barrier;
    9.21s   $queue->read_buffer($bufs->{rc_vec},1,0,$retvals,$rc_str);

I interpret this not as the read_buffer taking nearly 10s, but as the
code blocking there while waiting for the kernels to finish running.
The actual read from the buffer probably is only in the order of 100ms
in total, in line with costs of the other calls to read_buffer.

There are more expensive calls in handling the swap arrays:

    1.17s   $queue->read_buffer($bufs->{i_swap},1, $sp*4,4,$swap_i);
   23.5ms   $swap_i = unpack("V", $swap_i);
            $queue->read_buffer(
    977ms   $bufs->{code_swap},1, $sp*$alpha,$alpha,$swap_code);
    1.08s   $queue->read_buffer(
            $bufs->{sym_swap},1, $sp*$blocksize,$blocksize,$swap_sym);

Reading from buffers seems to be a lot more expensive than writing to
them, as the following two writes only take 192ms and 161ms.

While this bit of code only takes a few seconds, it still makes sense
to optimise it. It seems that reading the whole buffer and unpacking
it into a local Perl array should be a lot quicker than doing a
read_buffer for each element.

It should also be possible to write another kernel that handles
writing swapped values back into the coding and symbol arrays, though
I'm not sure if the calling overhead would be worth it, and I'd lose
the ability to turn on checking of symbols if I need to debug that
again (unless I keep both the OpenCL and Perl versions in the code).

I can't profile the OpenCL code directly, so it's hard to know what's
taking the most time. However, I have an alternative implementation of
the field multiplication operations. I could plug that in and see what
difference it makes. Also, profiling of the C version of the code can
give a good sense of instruction counts, even though the OpenCL code
is different in a few places.

I could also try tuning some OpenCL parameters, for example using
fewer work units and having each work unit do more work. This would
relieve some memory access pressure (redundant writes to new_code
vector), but probably not enough to offset the extra maths work done
in each thread.

I should also check to make sure that I'm actually running the kernels
on the GPU. I think that I am, but I might be mistaken. OK. I think
that's checked for in the code now.

I've implemented the change to swapped rows, which knocked a couple of
seconds off the run time.

### DO_SWAP

Turning this off brings run time up from 18.4s to 28.1s.

### Alternative Maths Implementation

I think that I have an inversion routine somewhere, but it's a
complicated algorithm, so besides implementing that, my options are:

* use log/exp functions (however they're implemented)
* send a pointer to an inv table

This is only called once for each row that we pivot into, though, so
it's not worth bothering with it.

For log/exp, there are three ways to try:

* look up values using switch statement (the current implementation)
* look up in global table
* don't use (apart for inverse), but do long multiply

These shouldn't take long to implement. I might need to normalise the
macro names a bit though.

First test is good! Enabling LONG_MULTIPLY brought the run time down
to 5.4 seconds.

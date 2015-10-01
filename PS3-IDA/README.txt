Demo of programming for Cell Broadband Engine 

OR

Re-implementation of Perl-based Crypt::IDA::ShareFile on Cell


There are two ways of explaining the contents of these directories.
The first is to look at them as a series of experiments/demos for
learning to program for the Cell Broadband Engine (Cell/CBE) platform.
In that way, each of the seven directories explores a different
concept needed for efficient programming on this platform. The
alternative way of looking at them is by reference to the desired end
result, namely to port or re-implement my existing IDA ShareFile
functionality to run more effectively on the Cell platform.

If you're interested in learning Cell programming, you should probably
work your way through each directory in turn and examine the code
there before moving on to next. With the exception of the last demo,
each directory is self-contained and can be read independently,
though. It might still be useful to you if you compile the code in the
final directory first and run the included Perl script, though, to
see where all the effort is building up to.

If you're more interested in using your Cell machine for creating or
combining ShareFiles, go straight to the final directory (07-shebang)
and just run a 'make install'. This will install a Perl script and a
"helper" C program.  Together they implement the same IDA split and
combine transforms as used in my Crypt::IDA::ShareFile module,
although without the same application interface. Files created with
the included Perl script are compatible with those created and read by
the Crypt::IDA::ShareFile module.

For a more complete rundown, the directories are as follows:

01-malloc/     Allocating memory on SPE side. Dealing with the lack of
	       a native aligned memory allocator routine.
02-mailbox/    Message passing between SPE and PPE via mailboxes.
03-runargs/    Using SPE_RUN_USER_REGS to pass 48 bytes of SPE
               initialisation data.
04-events/     Simple event handling on PPE side to respond to mailbox 
               interrupt events.
05-semaphore/  Using semaphores (and a queue based on the sempahore
               primitive) to co-ordinate PPE-side threads.
06-dma/        DMA transfers in a scaled-down version of the IDA code
               (demonstrates transferring sections of a large matrix).
07-shebang/    The whole shebang. A complete PPE/SPE application
               incorporating all of the above plus SPE
               double-buffering and a fully-featured IDA codec and
               command-and-control mini language. Also a Perl script
               to do high-level, non-compute-intensive code and call
               the PPE/SPE code for the critical sections.

All these files are licensed under version 2 (or, at your discretion,
any later version) of the GPL. Share and Enjoy!

Declan Malone (aka Ida Black), September 2009.

Addendum

I've also added a 08-fastmatrix directory here. This implements an
optimised matrix multiplication routine of my own design. I noted that
the standard way of doing matrix multiplication one dot product at a
time is a very inefficient use of SIMD. In any implementation that I've
seen, if the length of the vectors being multiplied together aren't
the same as the SIMD width, then we waste calculations by needing to
"wrap around" at the end of the vector. To illustrate, consider a
dot product that is 5 items long, but we have a 16-wide SIMD architecture.
The usual algorithms would involve doing 5 multiplications at once and
wasting the other 16-5 = 11 multiplications.

The algorithm implemented here is designed to make use of any/all
multiplications by (a) exploiting organisation of the matrices in
memory, (b) detecting when wrapping around at the end of the current dot
product has taken place, (c) apportioning some of the calculated values
to the current dot product (and summing them along with any accumulated
sum) and some to the next dot product.

The net effect is that the full SIMD pipeline is always 100% busy. I've
also taken care to eliminate some conditional branches, but have left
some in for clarity. The changes are rounded off by the addition of a
SIMD version of GF(2^8) multplication that has unrolling and conditional
branches eliminated.

This code is also licensed under GPL 2, or any later version if you wish
it.



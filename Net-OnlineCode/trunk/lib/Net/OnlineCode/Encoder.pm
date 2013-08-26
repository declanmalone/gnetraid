package Net::OnlineCode::Encoder;

use strict;
use warnings;

use Carp;

use Net::OnlineCode;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

# Inherit from base class
our @ISA = qw(Net::OnlineCode Exporter);
our @EXPORT_OK = qw();

sub new {

  my $class = shift;

  my %opts = (
	      # include any encoder-specific arguments here
	      initial_rng      => undef,
	      @_
	     );

  my $self = $class->SUPER::new(@_);

  croak "Failed to create superclass\n" unless ref($self);

  $self->{aux_mapping} = $self->auxiliary_mapping($opts{initial_rng});

  return $self;
}


# to create check blocks, call the parent's checkblock_mapping method
# to find the mapping, then optionally expand any auxiliary block
# numbers with the message blocks they're composed of.

sub create_check_block {

  my ($self, $rng) = @_;

  # already tested by parent method:
  # croak "rng parameter must be an object ref" unless ref($rng);

  my $xor_list  = $self->checkblock_mapping($rng);

  # Optionally replace auxiliary indices with a list of message
  # indices.  Message blocks may appear multiple times in the
  # expansion: once for an explicit mention in the checkblock, and
  # potentially several times in the expansion of auxiliary blocks. We
  # eliminate any message blocks that appear an even number of times
  # in the expansion since xoring by "A xor A" is a null operation.
  #
  # Note that although we use the same option name (expand_aux) in the
  # encoder and decoder, the implementations are different. Here we
  # expand aux blocks indices into message indexes, whereas in the
  # decoder, we expand them into check block indices.
  if ($self->{expand_aux}) {
    my %blocks;
    while (@$xor_list) {
      my $entry = shift(@$xor_list);
      if ($entry < $self->{mblocks}) { # is it a message block index?
	# toggle entry in the hash
	if (exists($blocks{$entry})) {
	  delete $blocks{$entry};
	} else {
	  $blocks{$entry}=1;
	}
      } else {
	# aux block : push all message blocks it's composed of
	push @xor_list, @{$self->{aux_mapping}->[$_ - $self->{mblocks}]};
      }
    }
    $xor_list = [ keys %blocks ];
  }

  return $xor_list;
}

1;


__END__

=head1 NAME

Net::OnlineCode::Encoder - Rateless Forward Error Correction Encoder

=head1 SYNOPSIS

  use Net::OnlineCode::Encoder;
  use strict;

  my ($message,$msg_size,$blocksize);

  my $blocks = int(0.5 + ($msg_size / $blocksize));
  my @blocks = map { substr $message, $_ * $blocksize, $blocksize }
                 (0.. $blocks -1);

  my $initial_rng = Net::OnlineCode::RNG->new;
  my $msg_id      = $initial_rng->seed_random;
  my $encoder     = Net::OnlineCode::Encoder->new(
    mblocks     => $blocks,
    initial_rng => $initial_rng,
    # ...
  );

  # Send initial parameters and $msg_id (rng seed) to receiver
  # ...

  # Send an infinite stream of packets to receiver
  while (1) {
    my $rng      = Net::OnlineCode::RNG->new;
    my $block_id = Net::OnlineCode::RNG->seed_random;
    my @xor_list = $encoder->create_check_block($rng);

    # XOR all blocks in xor_list together
    my $block = $blocks[shift @xor_list];
    foreach my $xor_block (@xor_list) {
      map { substr($block, $_, 1) ^= substr($blocks[$xor_block], $_, 1) }
        (0 .. $blocksize-1);
    }

    # Send $msg_id, $block_id and (xored) $block to receiver
    # ...
  }

=head1 DESCRIPTION

This module implements the "encoder" side of the Online Code algorithm
for rateless forward error correction. Refer to the L<the
Net::OnlineCode documentation|Net::OnlineCode> for more technical
details.

The basic outline for how the encoder works is follows:

=over

=item * The user breaks the input message into a number of blocks

=item * The user seeds a random number generator ("rng") and saves the seed value (as the "message ID")

=item * The constructor uses the random number generator to compute some number of "auxiliary" blocks. Auxiliary blocks are the XOR of some number of message blocks

=item * The user sends details such as file size, number of blocks and the random seed to the receiver

=item * (using the same seed value and random number generator algorithm, the receiver can calculate which message blocks each auxiliary block is comprised of)

=back

Once the initial stage is complete, the sender sends a number of check
blocks to the receiver. Check blocks are the XOR of some number of
message blocks and/or auxiliary blocks. The above example shows the
sender sending an infinite stream of check blocks, but in practice
only a finite number will be sent. Schemes for deciding how many check
blocks to send can be based on:

=over

=item * the probability that the complete message can be decoded based on encoder parameters, assumed network packet loss rate and number of packets already sent;

=item * the use of positive acknowledgements from the receiver; or

=item * the use of negative acknowledgements from the receiver

=back

Practical implementations will also have to account for the receiving
host or network link going down as well as problems with ACK/NAK
messages becoming lost, as well as dealing with network congestion.
They may also have to enforce timeouts and methods for fixing the
sending rate or for flow control in general. The implementation will
also depend to a great degree on the nature of the transmission, such
as whether it is over a TCP or UDP channel, whether it is unicast or
multicast, the expected latency for acknowledgement packets and, in
the case of multicast, the number of receivers. As a result, a
complete protocol description is beyond the scope of this document.

The procedure for sending a single check block is as follows:

=over

=item * the user generates a new random number generator seed which will become the check block's block ID

=item * the call to create_check_block uses the rng to create a random check block

=item * the check block is comprised of the XOR of various randomly-selected message or auxiliary blocks

=item * (using the same seed value and random number generator algorithm, the receiver can calculate which message and auxiliary blocks comprise the received check block)

=item * the return value of create_check_block is a list of message blocks (auxiliary blocks being expanded into their component message blocks automatically)

=item * the user XORs each of the message blocks returned to create the check block

=item * the user sends the message ID (if multiple messages may be sent at once), the block ID and the check block contents

=head2 EXPORT


=head1 TECHNICAL INFORMATION

=head2 BACKGROUND

=head2 ALGORITHMS


=head2 FUTURE DIRECTIONS


=head2 APPLICATIONS

=head1 KNOWN BUGS


=head1 SEE ALSO

I<http://en.wikipedia.org/wiki/Finite_field_arithmetic>

A (mostly) readable description of arithmetic operations in Galois
Fields.

I<http://point-at-infinity.org/ssss/>

B. Poettering's implementation of Shamir's secret sharing scheme. This
uses Galois Fields, and my own implementation of C<gf2_inv> is based
on this code.

I<"Efficient dispersal of information for security, load balancing,
and fault tolerance">, by Michael O. Rabin. JACM Volume 36, Issue 2
(1989).

The initial motivation for writing this module.

I<Introduction to the new AES Standard: Rijndael>, by Paul Donis,
I<http://islab.oregonstate.edu/koc/ece575/aes/intro.pdf>

Besides the AES info, this is also a very good introduction to
arithmetic in GF(2^m).

I<"Optimizing Galois Field Arithmetic for Diverse Processor
Architectures and Applications">, by Kevin M. Greenan, Ethan L. Miller
and Thomas J. E. Schwarz, S.J. (MASCOTS 2008)

Paper giving an overview of several optimisation techniques for
calculations in Galois Fields. I have used the optimised log/exp
technique described therein, and a modified version of the l-r tables
described (called "high-nibble" and "low-nibble" above) . Comments in
the paper that optimisations may need to be tailored to the particular
hardware architecture have been borne out in my testing.

I<http://www.cs.utk.edu/~plank/plank/papers/CS-07-593/>

James S. Plank's C/C++ implementation of optimised Galois Field
calculations. Although I haven't explored the code in great detail, I
have used it as a source of benchmarks. In fact, my benchmarking code
is modelled on this code. Plank's code is much more fully-featured
than mine, so if that is what you want, I would recommend using it
instead. If, on the other hand, you want something that's simple,
doesn't use much memory and is usable from Perl, I recommend this
module of course.

I<Studies on hardware-assisted implementation of arithmetic operations in
Galois Field GF(2^m)>, by Katsuki Kobayashi.

Despite being aimed at hardware, this paper also contains a wealth of
information on software algorithms including several field inversion
algorithms.

I<http://charles.karney.info/misc/secret.html> Original implementation
of Shamir's secret sharing algorithm, on which C<shamir-split.pl> and
C<shamir-combine.pl> are based. These new versions replace the integer
modulo a prime fields with Galois fields implemented with
Math::FastGF2.

The L<Math::FastGF2::Matrix> module has a range of Matrix functions to
operate more efficiently on large blocks of data.

This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

The C code at the core of this Perl module can additionally be
redistributed and/or modified under the terms of the "GNU Library
General Public License" ("LGPL"). For the purpose of that license, the
"library" is defined as the unmodified C code in the clib/ directory
of this distribution. You are permitted to change the typedefs and
function prototypes to match the word sizes on your machine, but any
further modification (such as removing the static modifier for
non-exported function or data structure names) are not permitted under
the LGPL, so the library will revert to being covered by the full
version of the GPL.

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


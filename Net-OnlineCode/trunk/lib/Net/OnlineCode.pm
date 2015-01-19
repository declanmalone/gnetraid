#!/usr/bin/perl

package Net::OnlineCode;

# play nicely as a CPAN module

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);

our @export_xor = qw (xor_strings safe_xor_strings fast_xor_strings);
our @export_default = qw();

%EXPORT_TAGS = ( all => [ @export_default, @export_xor ],
		 xor => [ @export_xor ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = ();
$VERSION = '0.02';

# Use XS for fast xors (TODO: make this optional)
require XSLoader;
XSLoader::load('Net::OnlineCode', $VERSION);

# on to our stuff ...

use constant DEBUG => 0;


# Codec parameters
# q    is the number of message blocks that each auxiliary block will
#      link to
# e    epsilon, the degree of "suboptimality". Unlike Reed-Solomon or
#      Rabin's Information Dispersal Algorithm, Online Codes are not
#      optimal. This means that slightly more data needs to be generated
#      than either of these two codes. Also, whereas optimal codes
#      guarantee that a certain fraction of the "check" blocks/digits
#      suffice to reconstruct the original message, online codes only
#      guarantee that it can be reconstructed with a certain
#      probability
#
# Together with the number of blocks, n, these two variables define
# the online code such that (1+qe)n check blocks are sufficient to
# reconstruct the original message with a probability of 1 - (e/2) **
# (q+1).
#

use Carp;
use POSIX qw(ceil floor);
use Digest::SHA qw(sha1 sha1_hex);
use Fcntl;


# Constructor for the base class
#
# This takes the three parameters that define the Online Code scheme,
# corrects the value of epsilon if needed (see below) and then derives
# the following:
#
# * max degree variable (F)
# * number of auxiliary blocks (0.55 *qen)
# * probability distribution p_1, p2, ... , p_F
#
# All these are purely deterministic.

sub new {

  my $class = shift;
  # The default parameters used here for q and e (epsilon) are as
  # suggested in the paper "Rateless Codes and Big Downloads" by Petar
  # Maymounkov and David Maziere. Note that the value of e may be
  # overridden with a higher value if the lower value doesn't satisfy
  # max_degree(epsilon) > ceil(0.55 * q.e.mblocks)
  my %args = (
	      e           => 0.01,
	      q           => 3,
	      mblocks     => undef,
	      expand_aux  => 0,
	      e_warning   => 0,

	      # We don't use or store any RNG parameter that's been
	      # passed into the constructor.
	      @_
	     );


  my ($q,$e,$mblocks) = @args{qw(q e mblocks)};

  unless (defined $args{mblocks}) {
    carp __PACKAGE__ . ": mblocks => (# message blocks) must be set\n";
    return undef;
  }

  print "Net::OnlineCode mblocks = $mblocks\n" if DEBUG;

  my $P = undef;
  my $e_changed = 0;

  # how many auxiliary blocks would this scheme need?
  my $ablocks =  _count_auxiliary($q,$e,$mblocks);

  # does epsilon value need updating?
  my $f = _max_degree($e);

  # try an alternative way of calculating F:
  #  $f = $mblocks + $ablocks if $f > $mblocks + $ablocks;

  if ($f > $mblocks + $ablocks) {

    $e_changed = 1;

    if ($args{e_warning}) {
      print "E CHANGED!!\nWas: $e\n";
      print "Gave F value of $f\n";
    }

    # use a binary search to find a new epsilon such that
    # get_max_degree($epsilon) <= mblocks + ablocks (ie, n)
    my $epsilon = $e;

    local *eval_f = sub {
      my $t = shift;
      return _max_degree(1/(1 + exp(-$t)));
    };

    my $l = -log(1/$e - 1);
    my $r = $l + 1;

    # expand right side of search until we get F <= n'
    while (eval_f($r) > $mblocks + $ablocks) {
      # $r = $l + ($r - $l) * 2;
      $r = 2 * $r - $l;
    }

    # binary search between left and right to find a suitable lower
    # value of epsilon still satisfying F <= n'
    while ($r - $l > 0.01) {
      my $m = ($l + $r) / 2;
      if (eval_f($m) > $mblocks + $ablocks) {
	$l = $m;
      } else {
	$r = $m;
      }
    }

    # update e and ablocks
    $epsilon = 1/(1 + exp(-$r));
    $f       = eval_f($r);
    #$f=_max_degree($epsilon);
    carp __PACKAGE__ . ": increased epsilon value from $e to $epsilon\n"
      if $args{e_warning};
    $e = $epsilon;
    $ablocks =  _count_auxiliary($q,$e,$mblocks);

    if ($args{e_warning}) {

      print "Is now: $e\n";
      print "New F: $f\n";
    }

  }

  # how many auxiliary blocks would this scheme need?

  # calculate the probability distribution
  print "new: mblocks=$mblocks, ablocks=$ablocks, q=$q\n" if DEBUG;
  $P = _probability_distribution($mblocks + $ablocks,$e);

  die "Wrong number of elements in probability distribution (got "
    . scalar(@$P) . ", expecting $f)\n"
      unless @$P == $f;

  my $self = { q => $q, e => $e, f => $f, P => $P,
	       mblocks => $mblocks, ablocks => $ablocks,
	       coblocks => $mblocks + $ablocks,
               chblocks => 0, expand_aux=> $args{expand_aux},
	       e_changed => $e_changed, unique => {},
	       fisher_string => pack("L*", (0 .. $mblocks + $ablocks -1)),
	     };

  print "expand_aux => $self->{expand_aux}\n" if DEBUG;

  bless $self, $class;

}

# while it probably doesn't matter too much to the encoder whether the
# supplied e value needed to be changed, if the receiver plugs the
# received value of e into the constructor and it ends up changing,
# there will be a problem with receiving the file.
sub e_changed {
  return shift ->{e_changed};
}

# convenience accessor functions
sub get_mblocks {		# count message blocks; passed into new
  return shift -> {mblocks};
}

sub get_ablocks {		# count auxiliary blocks; set in new
  return shift -> {ablocks};
}

sub get_coblocks {		# count composite blocks
  my $self = shift;
  return $self->{mblocks} + $self->{ablocks};
}

# count checkblocks
sub get_chblocks {
  return shift->{chblocks}
}

sub get_q {			# q == reliability factor
  return shift -> {q};
}

sub get_e {			# e == suboptimality factor
  return shift -> {e};
}

sub get_epsilon {		# epsilon == e, as above
  return shift -> {e};
}

sub get_f {			# f == max (check block) degree
  return shift -> {f};
}

sub get_P {			# P == probability distribution
  return shift -> {P};		# (array ref)
}


# "Private" routines

# calculate how many auxiliary blocks need to be generated for a given
# code setup
sub _count_auxiliary {
  my ($q, $e, $n) = @_;

  my $count = int(ceil(0.55 * $q * $e * $n));
  my $delta = 0.55 * $e;

  warn "failure probability " . ($delta ** $q) . "\n" if DEBUG;
  #$count = int(ceil($q * $delta * $n));

  if ($count < $q) {
    #$count = $q;		# ???
    #warn "updated _count_auxiliary output value to $q\n";
  }
  return $count;
}

# The max degree specifies the maximum number of blocks to be XORed
# together. This parameter is named F.
sub _max_degree {

  my $epsilon = shift;

  my $quotient = (2 * log ($epsilon / 2)) /
    (log (1 - $epsilon / 2));

  my $delta = 0.55 * $epsilon;
  #$quotient = (log ($epsilon) + log($delta)) / (log (1 - $epsilon));

  return int(ceil($quotient));
}

# Functions relating to probability distribution
#
# From the wikipedia page:
#
# http://en.wikipedia.org/wiki/Online_codes
#
# During the inner coding step the algorithm selects some number of
# composite messages at random and XORs them together to form a check
# block. In order for the algorithm to work correctly, both the number
# of blocks to be XORed together and their distribution over composite
# blocks must follow a particular probability distribution.
#
# Consult the references for the implementation details.
#
# The probability distribution is designed to map a random number in
# the range [0,1) and return a degree i between 1 and F. The
# probability distribution depends on a single input, n, which is the
# number of blocks in the original message. The fixed values for q and
# epsilon are also used.
#
# This code includes two changes from that described in the wikipedia
# page.
#
# 1) Rather than returning an array of individual probabilities p_i,
#    the array includes the cumulative probabilities. For example, if
#    the p_i probabilities were:
#      (0.1, 0.2, 0.3, 0.2, 0.1, 0.1)
#    then the returned array would be:
#      (0.1, 0.3, 0.6, 0.8, 0.9, 1)  (last element always has value 1)
#    This is done simply to make selecting a value based on the random
#    number more efficient, but the underlying probability distribution
#    is the same.
# 2) Handling edge cases. These are:
#    a) the case where n = 1; and
#    b) the case where F > n
#    In both cases, the default value for epsilon cannot be used, so a
#    more suitable value is calculated.
#
# The return value is an array containing:
#
# * the max degree F
# * a possibly updated value of epsilon
# * the F values of the (cumulative) probability distribution

sub _probability_distribution {

  my ($nblocks,$epsilon) = @_;	# nblocks = number of *composite* blocks!

  # after code reorganisation, this shouldn't happen:
  if ($nblocks == 1) {
    croak "BUG: " .  __PACKAGE__ ." - number of composite blocks = 1\n";
    return (1, 0, 1);
  }

  print "generating probability distribution from nblocks $nblocks, e $epsilon\n"
    if DEBUG;

  my  $f = _max_degree($epsilon);

  # after code reorganisation, this shouldn't happen:
  if ($f > $nblocks) {
    croak "BUG: " .__PACKAGE__ . " - epsilon still too small!\n";
  }

  # probability distribution

  # Calculate the sum of the sequence:
  #
  #                1 + 1/F
  # p_1  =  1  -  ---------
  #                 1 + e
  #
  #
  #             F . (1 - p_1)
  # p_i  =  ---------------------
  #          (F - 1) . (i^2 - i)
  #
  # Since the i term is the only thing that changes for each p_i, I
  # optimise the calculation by keeping a fixed term involving only p
  # and f with a variable one involving i, then dividing as
  # appropriate.

  my $p1     = 1 - (1 + 1/$f)/(1 + $epsilon);
  my $pfterm = (1-$p1) * $f / ($f - 1);

  die "p1 is negative\n" if $p1 < 0;

  # hard-code simple cases where f = 1 or 2
  if ($f == 1) {
    return [1];
  } elsif ($f == 2) {
    return [$p1, 1];
  }

  # calculate sum(p_i) for 2 <= i < F.
  # p_i=F is simply set to 1 to avoid rounding errors in the sum
  my $sum   = $p1;
  my @P     = ($sum);

  my $i = 2;
  while ($i < $f) {
    my $iterm = $i * ($i - 1);
    my $p_i   = $pfterm / $iterm;

    $sum += $p_i;

    die "p_$i is negative\n" if $p_i < 0;

    push @P, $sum;
    $i++;
  }

  if (DEBUG) {
    # Make sure of the assumption that the sum of terms approaches 1.
    # If the "rounding error" below is not a very small number, we
    # know there is a problem with the assumption!
    my $p_last = $sum + $pfterm / ($f * $f - $f);
    my $absdiff = abs (1 - $p_last);
    warn "Absolute difference of 1,sum to p_F = $absdiff\n" if $absdiff >1e-8;
  }

  return [@P,1];
}


# Fisher-Yates shuffle algorithm, based on recipe 4.17 from the Perl
# Cookbook. Takes an input array it randomises the order (ie,
# shuffles) and then truncates the array to "picks" elements.
#
# This is much more efficient than the usual approach of "keep picking
# new elements until we get k distinct ones" particularly as k
# approaches the size of the array. That algorithm could make
# exponentially many calls to rand, whereas this just makes one call
# per item to be picked.

sub fisher_yates_shuffle {

  my ($rng, $array, $picks) = @_;

  die "fisher_yates_shuffle: 1st arg not an RNG object\n"
    unless ref($rng);

  # length in 32-bit words
  my $len = length($array) >> 2;

  # Change recipe to pick subset of list
  $picks=$len unless
    defined($picks) and $picks >= 0;

  # algorithm fills picks into the end of the array
  my $i=$len;
  while (--$i >= $len - $picks) {
    my $j=int($rng->rand($i + 1)); # range [0,$i]
    #next if $i==$j;	           # not worth checking, probably
    #    @$array[$i,$j]=@$array[$j,$i]
    my $tmp1 = substr $array, $i << 2, 4;
    my $tmp2 = substr $array, $j << 2, 4;
    substr $array, $i << 2, 4, $tmp2;
    substr $array, $j << 2, 4, $tmp1;
  }

  return (unpack "L*", substr $array, ($len - $picks) << 2);
}

#
# Routine to calculate the auxiliary block -> message block* mapping.
# The passed rng object must already have been seeded, and both sender
# and receiver should use the same seed.  Returns [[..],[..],..]
# representing which message blocks each of the auxiliary block is
# composed of.
#

sub auxiliary_mapping {

  my $self = shift;
  my $rng  = shift;

  croak "auxiliary_mapping: rng is not a reference\n" unless ref($rng);

  #print "auxiliary_mapping: entering RNG value: " . ($rng->as_hex). "\n";

  # hash slices: powerful, but syntax is sometimes confusing
  my ($mblocks,$ablocks,$q) = @{$self}{"mblocks","ablocks","q"};

  # make sure hash(ref) slice above actually did something sensible:
  # die "weird mblocks/ablocks" unless $nblocks + $aux_blocks >= 2;

  # I made a big mistake when reading the description for creating aux
  # blocks. What I implemented first (in the commented-out section
  # below) was to link each of the auxiliary blocks to q message
  # blocks. What I should have done was to link each *message block*
  # to q auxiliary blocks. As a result, it was taking much more than
  # the expected number of check blocks to decode the message.

  # as a result of the new algorithm, it makes sense to work out
  # reciprocal links between message blocks and auxiliary blocks
  # within the base class. Storing them here won't work out very well,
  # though: the encoder doesn't care about the message block to aux
  # block mapping, so it would be a waste of memory, but more
  # importantly, the decoder object stores all mappings in a private
  # GraphDecoder object (so duplicating the structure here would be a
  # waste).

  # I will make one change to the output, though: instead of just
  # returning the mappings for the 0.55qen auxiliary blocks, I will
  # return a list of message block *and* auxiliary block mappings. The
  # encoder and decoder will have to be changed: encoder immediately
  # splices the array to remove unwanted message block mappings, while
  # the decoder will be simplified by only having to pass the full
  # list to the graph decoder (which will have to be modified
  # appropriately).

  my $aux_mapping = [];

  my $ab_string = pack "L*", ($mblocks .. $mblocks + $ablocks -1);

  # list of empty hashes
  my @hashes;
  for (0 .. $mblocks + $ablocks -1) { $hashes[$_] = {}; }

  for my $msg (0 .. $mblocks - 1) {
    # list of all aux block indices

    foreach my $aux (fisher_yates_shuffle($rng, $ab_string, $q)) {
      $hashes[$aux]->{$msg}=undef;
      $hashes[$msg]->{$aux}=undef;
    }
  }

  # convert list of hashes into a list of lists
  for my $i (0 .. $mblocks + $ablocks -1) {
    print "map $i: " . (join " ", keys %{$hashes[$i]}) . "\n" if DEBUG;
    push @$aux_mapping, [ keys %{$hashes[$i]} ];
  }

  # save and return aux_mapping
  $self->{aux_mapping} = $aux_mapping;
}

# Until I get the auto expand_aux working, this will have to do
sub blklist_to_msglist {

  my ($self,@xor_list) = @_;

  my $mblocks = $self->{mblocks};

  my %blocks;
  while (@xor_list) {
    my $entry = shift(@xor_list);
    if ($entry < $mblocks) { # is it a message block index?
      # toggle entry in the hash
      if (exists($blocks{$entry})) {
	delete $blocks{$entry};
      } else {
	$blocks{$entry}= undef;
      }
    } else {
      # aux block : push all message blocks it's composed of
      push @xor_list, @{$self->{aux_mapping}->[$entry]};
    }
  }
  return keys %blocks;
}

sub blklist_to_chklist  {

  my $self = shift;
  croak "This method only makes sense when called on a Decoder object!\n";
}


# non-method sub to toggle a key in a hash
sub toggle_key {
  my $href = shift;
  my $key  = shift;

  if (exists($href->{$key})) {
    delete $href->{$key};
  } else {
    # apparently, using key => undef is more space-efficient than
    # using key => 1 (similar changes made throughout this file)
    $href->{$key}=undef;
  }
}

# Calculate the composition of a single check block based on the
# supplied RNG. Returns a reference to a list of composite blocks
# indices.

sub checkblock_mapping {

  my $self = shift;
  my $rng  = shift;

  croak "rng is not an object reference\n" unless ref($rng);

  my $coblocks = $self->get_coblocks;
  my $P        = $self->{P};

  #  die "Probability distribution has wrong number of terms\n"
  #    unless scalar(@$P) <= $coblocks;

  my $check_mapping;

  # It's possible to generate a check block that is empty. If it only
  # includes message blocks, then there's no problem. However, if the
  # expansion of all the auxiliary blocks is equal to the list of
  # message blocks then two two cancel out. Besides being inefficient
  # to transmit effectively empty check blocks, it can also cause a
  # bug in the decoder where it assumes that the expanded list of
  # blocks is not empty. The solution is the same for both encoder and
  # decoder (loop until expansion is not empty), so I'm implementing
  # it here in the base class.
  #
  # Note that although this involves expanding auxiliary blocks, for
  # the moment, I'm ignoring "expand_aux" option and will just return
  # the unexpanded list. This may change in future once I've had a
  # chance to look at the problem more closely.

  my $mblocks = $self->{mblocks}; # quicker than calling is_message
  my %expanded=();
  my @unpacked;
  my $tries = 0;
  my $key;			# used for uniqueness-checking
  until (keys %expanded) {

    ++$tries;

    # use weighted distribution to find how many blocks to link
    my $i = 0;
    my $r = $rng->rand;
    ++$i while($r > $P->[$i]);	# terminates since r < P[last]
    ++$i;

    #die "went past end of probability list\n" if $i > @$P;

    #warn "picked $i values for checkblock (from $coblocks)\n";

    # select i composite blocks uniformly
#    $check_mapping = [ (0 .. $coblocks-1) ];
#    print "Calling fisher 2\n";
    my $string = $self->{fisher_string};
    @unpacked = fisher_yates_shuffle($rng, $string , $i);

    # check block for uniqueness before expansion
    $key = join " ", sort { $a <=> $b } @unpacked;
    if (exists $self->{unique}->{$key}) {
      warn "quashed duplicate check block\n" if DEBUG;
      next;
    }

    # print "check_mapping: raw composite block list: ", 
    #  (join " ", @$check_mapping), "\n";

    # check expanded list
    my @xor_list = @unpacked;
    while (@xor_list) {
      my $entry = shift @xor_list;
      if ($entry < $mblocks) { # is it a message block index?
	# toggle entry
	toggle_key (\%expanded, $entry);
      } else {

	# aux block : push all message blocks it's composed of. Since
	# we're sharing the aux_mapping structure with the decoder, we
	# have to filter out any entries it's putting in (ie,
	# composite blocks) or we can get into an infinite loop

	foreach (grep { $_ < $mblocks } @{$self->{aux_mapping}->[$entry]}) {
	  toggle_key (\%expanded, $_);
	}

	#my @expanded = grep { $_ < $mblocks } @{$self->{aux_mapping}->[$entry]};
	#print "check_mapping: expanding aux block $entry to ", 
	#  (join " ", @expanded), "\n";
	#push @xor_list, @expanded;
      }
    }
  }

  # prevent generating this block again
  $self->{unique}->{$key}=undef;

  #warn "Created unique, non-empty checkblock on try $tries\n" if $tries>1;

  die "fisher_yates_shuffle: created empty check block\n!" unless @unpacked;

#  ++($self->{chblocks});

  print "CHECKblock mapping: " . (join " ", @unpacked) . "\n" if DEBUG;

  return [@unpacked];

}

# non-method sub for xoring a source string (passed by reference) with
# one or more target strings. I may reimplement this using XS later to
# make it more efficient, but will keep a pure-perl version with this
# name.
sub safe_xor_strings {

  my $source = shift;

  # die if user forgot to pass in a reference (to allow updating) or
  # called $self->safe_xor_strings by mistake
  croak "xor_strings: arg 1 should be a reference to a SCALAR!\n"
    unless ref($source) eq "SCALAR";

  my $len = length ($$source);

  croak "xor_strings: source string can't have zero length!\n"
    unless $len;

  foreach my $target (@_) {
    croak "xor_strings: targets not all same size as source\n"
      unless length($target) == $len;
    map { substr ($$source, $_, 1) ^= substr ($target, $_, 1) }
      (0 .. $len-1);
  }

  return $$source;
}

# Later, xor_strings could be replaced with an C version with reduced
# error checking, so make a backward-compatible version and an
# explicit fast/unsafe version.
sub xor_strings      { safe_xor_strings(@_) }
#sub fast_xor_strings { safe_xor_strings(@_) } # implemented in OnlineCode.xs.


1;

__END__



=head1 NAME

Net::OnlineCode - A rateless forward error correction scheme

=head1 SYNOPSIS

  use strict;

  # Base class only exports routines for doing xor
  use Net::OnlineCode ':xor';

  my @strings = ("abcde", "     ", "ABCDE", "\0\0\0\0\0");

  # xor routines take a reference to a destination string, which is
  # modified by xoring it with all the other strings passed in. The
  # calculated value is also returned.

  # "safe" xor routine is a pure Perl implementation
  my $result1 = safe_xor_strings(\$strings[0], @strings[1..3]);

  # "fast" xor routine is implemented in C
  my $result2 = fast_xor_strings(\$strings[0], @strings[1..3]);

=head1 DESCRIPTION

This module implements the common functions required for the
L<Net::OnlineCode::Encoder> and L<Net::OnlineCode::Decoder> modules.
Apart from the two xor library routines shown above, there are no
other user-callable methods or functions.

The remainder of this document will give a brief overview of the
Online Code algorithms. For a programmer's view of how to use this
collection of modules, refer to the man pages for the
L<Encoder|Net::OnlineCode::Encoder> and
L<Decoder|Net::OnlineCode::Decoder> modules.

=head1 ONLINE CODES

Briefly, Online Codes are a scheme that allows a sender to break up a
message (eg, a file) into a series of "check blocks" for transmission
over a lossy network. When the receiver has received and decoded
enough check blocks, they will ultimately be able to recover the
original message in its entirety.

Online Codes differ from traditional "forward error correcting"
schemes in two important respects:

=over

=item * they are fast to calculate (on both sending and receiving end); and

=item * they are "rateless", meaning that the sender can send out a (practically) infinite stream of check blocks. The receiver typically only has to correctly receive a certain number of them (usually a only small percentage more than the number of original message blocks) in order to decode the full message.

=back

When using a traditional error-correction scheme, the sender usually
has to set up the encoder parameters to take account of the expected
packet loss rate. In contrast, with Online Codes, the sender
effectively doesn't care about what the packet loss rate: it just
keeps sending new check blocks until either the receiver(s)
acknowledge the message as having been decoded, or until it has a
reasonable expectation that the message should have been decoded.


=head1 ONLINE CODES IN MORE DETAIL

The fundamental idea used in Online Codes is to xor some number of
message blocks together to form either auxiliary blocks (which are
internal to the algorithm) or check blocks (which are sent across the
network). Each check block is sent along with a block ID, which
encodes information about which message blocks (or auxiliary blocks)
comprise that check block. Initially, the only check blocks that a
receiver can use are those that are comprised of only a single message
block, but as more message blocks are decoded, they can be xored (or,
in algebraic terms, "substituted") into each pending (unsolved) check
block. Eventually, given enough check blocks, the receiver will be
able to solve each of the message blocks.

=head2 ENCODING/DECODING STEPS

Encoding consists of two parts:

=over

=item * Before transmission begins, some number of auxiliary blocks are created by xoring a random selection of message blocks together.

=item * For each check block that is to be transmitted, a random selection of auxiliary and/or message blocks (collectively referred to as "composite blocks") are xored together.

=back

Decoding follows the same steps as in the Encoder, except in
reverse. Each received check block can potentially solve one unknown
auxiliary or message block directly. Further, every time an auxiliary or
message block becomes solved, that value can be "substituted in" to
any check block that has not yet been fully decoded. Those check
blocks may then be able to solve more message or auxiliary blocks.

=head2 PSEUDO-RANDOM NUMBER GENERATORS AND BLOCK IDS

When the receiver receives a check block, it needs to know which
message and/or auxiliary blocks it is composed of. Likewise, it needs
to know which message blocks each auxiliary block is composed of. This
is achieved by having both the sender and receiver side use an
identical pseudo-random number generator algorithm. Since both sides
are using an identical PRNG, they can both use it to randomly select
which message blocks comprise each auxiliary block, and which
composite blocks comprise each check block.

Naturally, for this to work, not only should the sender and receiver
both be using the same PRNG algorithm, but they also need to be using
the same PRNG I<seeds>. This is where I<Block IDs> (and also, for the
auxiliary block mapping, I<File IDs>) come in. For check blocks, the
sender picks a (truly) random Block ID and uses it to seed the
PRNG. Then, using the PRNG, it pseudo-randomly selects some number of
composite blocks. It then sends the Block ID along with the xor of all
the selected composite blocks. The sender then uses the Block ID to
seed its own PRNG, so when it pseudo-randomly selects the list of
composite blocks, it should be the same as that selected by the
sender.

A similar scheme is used at the start of the transmission to determine
which message blocks are xored to create the auxiliary blocks.

The upshot of this is that Block (and File) IDs only need to be a
fixed size, regardless of how many message blocks there are, how many
composite blocks are included in a check block, and so on. This makes
it much easier to design a packet format and process it at the
sending and receiving sides.

=head1 IMPLEMENTATION DETAILS

The module is a fairly faithful implementation of Maymounkov and
Maziere's paper describing the scheme. There are some slight
variations:

=over

=item * in the case where the epsilon value would produce a max degree (F) value greater than the number of message blocks, it (ie, epsilon) is increased until F <= # of message blocks. The code to do this is based on Python code by Gwylim Ashley.

=item * duplicate check blocks are quashed (since they provide no new information)

=item * the graph decoding algorithm is replaced with a functionally equivalent one

=item * message blocks need not decoded immediately: rather, the calling application makes the choice about when to do the xors (this I<may> be more time-efficient, particularly if the application is storing check blocks to secondary storage)

=back

Apart from that, the original paper does not specify a PRNG algorithm.
This module implements one using SHA-1, since it is portable across
platforms and readily available.


=head1 IMPORTANT NOTE

This is the initial software release. It should be free of serious
bugs, however it has a few shortcomings:

=over

=item * Memory usage is particularly high, especially if the number of check blocks runs into the thousands; and

=item * The Decoder must see more check blocks than the original paper suggests should be the case

=item * Although intended to be used with POE, the Decoder is currently not very suitable for use in a POE callback because it does not yield until it has done as much graph decoding as possible. If POE is being used to handle incoming network packets, the delay can cause it to drop packets. A future version will correct this by reducing the amount of work done per callback (so that control is returned to the POE event loop sooner, with the possibility to queue the remaining outstanding work with more calls to the Decoder object)

=back

As a result, it is likely that any future version that tries to
address these two points may result in changes to the calling
interfaces. See the TODO file that came in this distribution for more
details.

=head1 SEE ALSO

L<Wikipedia page describing Online Codes|http://en.wikipedia.org/wiki/Online_codes>

PDF/PostScript links:

=over

=item * L<"Online Codes": by Petar Maymounkov|http://cs.nyu.edu/web/Research/TechReports/TR2002-833/TR2002-833.pdf>

=item * L<"Rateless Codes and Big Downloads" by Petar Maymounkov and David Maziere|http://pdos.csail.mit.edu/~petar/papers/maymounkov-bigdown-lncs.ps>

=back

L<Github repository for Gwylim Ashley's Online Code implementation|https://github.com/gwylim/online-code> (various parts of my code are based on this)

This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Declan Malone

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


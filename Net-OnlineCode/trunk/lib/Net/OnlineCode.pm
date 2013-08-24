#!/usr/bin/perl

package Net::OnlineCode;

use constant DEBUG => 1;

our %do_tests = (
#		'encoder' => 1,
	       );

use strict;
use warnings;

# Implementation of "Online Codes" -- a "rateless" erasure code

#
# Phase 0: Overview
#
# The way Online Codes work is an extension of the basic ideas of
# Gallagher and, later, Tornado Codes. The fundamental idea is that
# some number of input blocks are XOR'd together to form a check
# block, and given enough check blocks it should be possible to solve
# the mapping between check blocks and original input blocks. This is
# possible by (a) careful selection of which and how many input blocks
# are XOR'd to form the check blocks, and (b) an algorithm to analyse
# the mappings to determine when a newly-arrived check block
# contributes enough new information to allow one or more message
# blocks to be recovered.
#
# Phase 1: skeletal encoder and PRNG
#
# In this phase, I want to lay the groundwork for being able to write
# a decoder algorithm. This involves the basic structure of an
# encoder, which is divided between a first phase that breaks the
# input into blocks and creates some number of "auxiliary" blocks that
# is the XOR of some number of random message blocks, and a second
# pass that implements a similar algorithm, creating "check" blocks
# that XOR some number of random blocks selected from among the
# original message blocks and the auxiliary blocks (which, combined,
# are referred to as "composite" blocks).
#
# In both passes, a pseudo-random number generator ("PRNG") is used to
# determine which message or composite blocks are to be XOR'd to
# produce, respectively, new auxiliary and check blocks. The method of
# seeding this PRNG needs to be passed to the decoder program in order
# for it to know which message blocks each auxiliary block is
# comprised of, and which, and how many composite blocks each "check"
# block is comprised of. For this reason, this phase implements a PRNG
# that can be initialised with a fixed seed value.
#
# The output of this phase will be a set of check blocks constructed
# using a particular probability distribution such that with a high
# degree of probability only a small number of additional blocks
# beyond the number in the original file will be needed at the
# decoding end to decode it.
#
# Since the purpose of this phase is merely to provide the groundwork
# for writing a decoder, no files are read in and, consequently, no
# XOR'ing is done.  The output is merely a set of block IDs which are
# equivalent to PRNG seeds.
#
# Phase 2: test decoding algorithm
#
# Together with the global information on the encoding/decoding that
# is being simulated (such as file size, block size and other erasure
# code parameters), the PRNG seed values produced by the encoder
# should be sufficient to simulate the arrival of check blocks at the
# decoder.
#
# Although no actual data is included in the data received from then
# encoder, it does include enough metadata to allow for testing of the
# basic decoding algorithms. Recall that there were two phases
# involved in encoding. In the first, the original message was
# expanded to include some number of auxiliary blocks, with the whole
# (original plus auxiliary) being called the "composite" message. In
# the second, "check" blocks were generated, with each check block
# containing one or more composite blocks. To decode these, we work in
# reverse.
#
# The basic algorithm involves building a bipartite graph for each of
# the two phases. There's a basic "is composed of" relation between
# each of the three layers of the graph. On the left, incoming "check"
# blocks are composed of one or more "composite" blocks, while on the
# right "auxiliary" blocks (themselves a subset of composite blocks)
# are composed of one or more original message blocks.
#
# As check blocks arrive, we add them to the left of the graph and
# then try to reconcile the graph to see if the new block gives any
# new information that can be used to decode either an auxiliary block
# or an original message block. As blocks are fully decoded, they are
# removed from the graph, and any blocks that reference them have
# their reference count (from other blocks in neighbouring levels)
# decremented by one. Any block that has a reference count of 0 as a
# result is likewise removed, with the algorithm cascading until the
# entire bigraph is updated.
#
# Phase 3: use the skeletal encode and decode parts on real data
#
# Up until now, the encoder and decoder have been simply working with
# abstractions of real files. The encoder takes a simulated file,
# described only by its length, broken it into a number of blocks and
# used the erasure code parameters to generate a set of metadata
# describing what the actual check blocks would contain (conveniently
# represented as a 160-bit PRNG seed value). The skeletal decoder then
# uses the metadata included in the check blocks to drive the decoder
# algorithm that incrementally solves the bipartite graph problem and
# exits when it as determined that the input check blocks are
# sufficient to reconstruct the original message.
#
# This phase simply adds the functionality required for the encoder
# and decoder to work with real data as opposed to just metadata. The
# main changes are to make the encoder and decoder read and write,
# respectively, input/output files and to implement the "is composed
# of" relation in terms of XORs of each of the appropriate message
# block types.
#
# Phase 4: efficiency/optimisation
#
# The major source of inefficiency seems to be related to memory
# usage. The decoder may need to keep a lot of check blocks active
# before it can delete them. It also has no way of knowing in advance
# which check blocks will resolve before which others. As a result of
# the large size/number of blocks, we will probably need to use
# secondary storage. Even then, it can be inefficient on some
# platforms to randomly access and update blocks on disk. As a result,
# this step will be focused on improving caching and access patterns.
#
# Phase 5: Profit!
#
# The code should be in a fit enough state to allow callers to use it.
#


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
use POSIX qw(ceil);
use Digest::SHA qw(sha1 sha1_hex);
use Fcntl;

# "Private" routines

# calculate how many auxiliary blocks need to be generated for a given
# code setup
sub _count_auxiliary {
  my ($q, $e, $n) = @_;

  return int(ceil(0.55 * $q * $e * $n));
}

# The max degree specifies the maximum number of blocks to be XORed
# together. This parameter is named F.
sub _max_degree {

  my $epsilon = shift;
  my $quotient = (2 * log ($epsilon / 2) /
		  (log (1 - $epsilon / 2)));

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

  my ($nblocks,$epsilon) = @_;

  # after code reorganisation, this shouldn't happen:
  if ($nblocks == 1) {
    croak "BUG: " .  __PACKAGE__ ." - number of composite blocks = 1\n";
    return (1, 0, 1);
  }

  my $f       = _max_degree($epsilon);

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
  my $ptterm = (1-$p1) * $f / ($f - 1);

  # hard-code simple cases where f = 1 or 2
  if ($f == 1) {
    return [1];
    #return ($f, $epsilon, 1);
  } elsif ($f == 2) {
    return [$p1, 1];
    # return ($f, $epsilon, $p1, 1);
  }

  # calculate sum(p_i) for 2 <= i < F.
  # p_i=F is simply set to 1 to avoid rounding errors in the sum
  my $sum   = $p1;
  my @P     = ($sum);

  my $i = 2;
  while ($i < $f) {		
    my $iterm = $i * $i - $i;
    my $p_i   = $ptterm / $iterm;

    $sum += $p_i;

    push @P, $sum;
    $i++;
  }

  if (DEBUG) {
    # make sure that the assumption that the sum of terms approaches 1
    # if the "rounding error" below is not a very small number, we
    # know there is a problem with the assumption!
    my $p_last = $sum + $ptterm / ($f * $f - $f);
    my $absdiff = abs (1 - $p_last);
    warn "Absolute difference of 1,sum to p_F = $absdiff\n";
  }

  return [(@P),1];

  # old return:
  # return ($f, $epsilon, @P, 1);
}

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
	      e_warning   => 0,
	      initial_rng => undef,
	      @_
	     );


  my ($q,$e,$mblocks) = @args{qw(q e mblocks)};

  unless (defined $args{mblocks}) {
    carp __PACKAGE__ . ": mblocks => (# message blocks) must be set\n";
    return undef;
  }

  my $P = undef;

  # how many auxiliary blocks would this scheme need?
  my $ablocks =  _count_auxiliary($q,$e,$mblocks);

  # does epsilon value need updating?
  my $f = _max_degree($e);
  if ($f > $mblocks + $ablocks) {

    # use a binary search to find a new epsilon such that
    # get_max_degree($epsilon) <= mblocks + ablocks (ie, n)
    my $epsilon = $e;

    local *eval_f = sub {
      my $t = shift;
      return _max_degree(1/(1 + exp(-$t)));
    };

    my $l = -log(1/$e - 1);
    my $r = $l + 1;

    # expand right side of search until we get F > n
    while (eval_f($r) > $mblocks + $ablocks) {
      # $r = $l + ($r - $l) * 2;
      $r = 2 * $r - $l;
    }

    # binary search between left and right to find a suitable lower
    # value for epsilon
    while ($r - $l > 0.01) {
      my $m = ($l + $r) / 2;
      if (eval_f($m) > $mblocks + $ablocks) {
	$l = $m;
      } else {
	$r = $m;
      }
    }

    $epsilon = 1/(1 + exp(-$r));
    $f       = eval_f($r);
    carp __PACKAGE__ . ": increased epsilon value from $e to $epsilon\n"
      if $args{e_warning};
    $e = $epsilon;
  }

  # calculate the probability distribution
  $P = _probability_distribution($mblocks + $ablocks,$e);

  my $self = { q => $q, e => $e, f => $f, P => $P,
	       mblocks => $mblocks, ablocks => $ablocks };

  bless $self, $class;

  # Use the probability distribution with the initial RNG to create
  # auxiliary blocks
  # ...

  return $self;

}

# convenience accessor functions
sub get_mblocks {		# count message blocks; passed into new
  return shift -> {mblocks};
}

sub get_ablocks {		# count auxiliary blocks; set in new
  return shift -> {ablocks};
}

sub get_q {			# q == reliability factor
  return shift -> {q};
}

sub get_e {			# e == suboptimality factor
  return shift -> {e};
}

sub get_epsilon {		# epsilon == e, as above
  return shift -> get_e();
}

sub get_f {			# f == max (check block) degree
  return shift -> {f};
}

sub get_P {			# P == probability distribution
  return shift -> {P};		# (array ref)
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

  die "fisher_yates_shuffle: 1st arg not a hashref (rng object)\n"
    unless ref($array) eq "HASH";

  die "fisher_yates_shuffle: 2nd arg not an array ref\n" 
    unless ref($array) eq "ARRAY";

  # Change recipe to pick subset of list
  $picks=scalar(@$array) unless
    defined($picks) and $picks >=0 and $picks<scalar(@$array);

  # algorithm fills picks into the end of the array
  my $i=scalar(@$array);
  while (--$i > $picks - scalar(@$array)) {
    my $j=int($rng->{rand}($i + 1)); # range [0,$i]
    next if $i==$j;
    @$array[$i,$j]=@$array[$j,$i]
  }

  # delete unpicked elements from the front of the array
  # (does nothing if picks == length of the array)
  splice @$array, 0, scalar @$array - $picks
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
  my ($nblocks, $rng) = $self->{"mblocks","rng"};

  my $aux_blocks = $self->{ablocks};

  my @message_blocks = (0 .. $nblocks -1);
  my $aux_mapping = [];

  for (1 .. $aux_blocks) {

    # My Fisher-Yates shuffle truncates the input array, so initialise
    # it with the full list of message blocks each iteration.
    my $mb = [@message_blocks];

    # uniformly select q message blocks for this auxiliary block
    fisher_yates_shuffle($rng, $mb, $self->{q});
    push @$aux_mapping, $mb;
  }

  return $aux_mapping;
}

#
# Routine to calculate the composition of a single check block based
# on the supplied RNG. Note that the nblocks parameter passed in is
# the number of composite blocks (not message blocks).

sub checkblock_mapping {

  my ($nblocks, $rng) = @_;

  my ($f, $epsilon, @P) = _probability_distribution($nblocks);

  my @composite_blocks = (0 .. $nblocks -1);

  # use weighted distribution to find how many blocks to link
  my $i = 0;
  my $r = $rng->{rand}();
  $i++ while ($r > $P[$i]);	# terminates since r < P[last]

  # select i composite blocks uniformly
  my $check_mapping = [ @composite_blocks ];
  fisher_yates_shuffle($rng, $check_mapping, $i);

  return $check_mapping;

}

### Tidy up
#
# The code that recalculates epsilon and F in
# get_probability_distribution should be bubbled up to a higher level.
#
# Likewise, we should only need to call the
# get_probability_distribution routine once since it is fixed for
# particular values of e, q and nblocks.
#
# As a result of these two points, checkblock_mapping should be
# changed to accept the probability distribution array as a parameter
# (passed by reference, since it can be so large).
#


if (exists($do_tests{encoder})) {

  print "Testing: ENCODER\n";

  # 41 characters:
  my $test = "The quick brown fox jumps over a lazy dog";

  print "Test string: $test\n";

  for my $blksiz (9,10) {

    my $string  = $test;
    $string .= "x" x ($blksiz - (length($string) % $blksiz));
    my $nblocks = length($string) / $blksiz;

    my ($mnum,$mblk,$mdeg,$mlinks);

    my $obj = new Net::OnlineCode(mblocks => $nblocks);

    

    $mnum = join "\n", (0..$nblocks -1);
    $mblk = join "'\n'", map { substr $string, $_ * $blksiz, $blksiz } (0..$nblocks -1);
    $mdeg = join "\n", (1, 1, 3, 4);
    $mlinks = join ",", (1,2,3,4);

    print "'$mblk'\n";

  }

}

sub accept_checkblock {

  my ($self, $blockid, $dataref) = @_;

  


}

1;


__END__

check block processing:

  pre-existing situation is a set of nodes and edges.
  nodes correspond to message, auxiliary or check blocks.
  edges denote messages (check, auxiliary) comprising other typs of
  blocks (auxiliary, message)

  edges are deleted by "substituting" known (solved) values into
  compound blocks.

  message blocks are initially unknown and become known by solving
  auxiliary and/or check blocks

  message blocks (and auxiliary blocks) are trivially solved by
  receiving a check block that contains only that message block.

  there must be some number of check blocks that contain only a single
  auxiliary or message block, or else we cannot guarantee that the
  message stream can be decoded.

  when a message block is newly solved, its value is substituted back
  into all other auxiliary and check blocks that include it.

  substitution can happen in either direction. The trivial case is
  where a check block contains only one message, so we propagate the
  value from that check block. The other case is where a node moves
  from being unsolved to solved. We then trigger propagation in the
  opposite direction.

  check         aux         message

  A x y                     x?

  B x z                     y?

  C z           z x

  In this example, assume we have just added the check block C. Since
  it only contains a single message z, we trivially substitute in and
  delete C:

  check         aux         message

  A x y                     x?

  B x z                     y?

                z=C x

  Since z has been newly solved, we need to follow the
  implications. Since this is an auxiliary block, we need to feed
  forwards (right) and backwards (left). It doesn't matter which we do
  first. Going right, we would see that z only comprises a single
  message block, so we can substitute x=C. We don't delete solved
  auxiliary blocks until the end of the algorithm since future check
  blocks might need to know the value.


  check         aux         message

  A x y                     x=C (done)

  B x z                     y?

                z=C x


  Or we can feed back to the left and substitute z wherever it appears:


  check         aux         message

  A x y                     x?

  B x z=C                   y?

                z=C x



  Combining the feed-forward and feed-backward effects of solving z:

  check         aux         message

  A x y                     x=C (done)

  B x z=C                   y?

                z=C x(done)

  When z is solved, we still have to deal with the implications of
  having solved x. Substituting in:


  check         aux         message

  A x=C y                   x=C (done)

  B x=C z=C                 y?

                z=C x(done)


  After updating B, we see that it is completely solved, so it could
  be deleted. We also see that A only has one unsolved link, so we can
  deduce that A = C xor y, or moving the unknown to one side of the
  equation: y = C xor A. We propagate the value across and finish
  with:

  check         aux         message

  A x=C y=AC                x=C (done)

  B x=C z=C                 y=AC (done)

                z=C x(done)

  Thus all message blocks have been decoded since they can be
  expressed in terms of XOR operations involving some number of check
  blocks.


  Note that it doesn't matter which order we do the substitution. In
  the above example when we discovered z, we had a choice of feeding
  forwards or backwards. It didn't matter which we did first so long
  as we also went in the opposite direction at some point. We should
  pick a scheme and stick with it, though. The best way of doing that
  seems to be to check each node that we've done a substitution on to
  see if this brings the number of unknowns in that node down to 1. If
  it is, we can simply push that node onto a stack of "newly
  discovered" nodes. Then when we're finished with our current
  feed-forward or feed-backward step and we don't uncover any new
  discoveries, we can pop any pending substitutions.


  The whole idea of tracking feed-forward and feed-backward scans
  separately is a bit awkward, though. On the other hand, we can have
  two sets of tests on a node. We can check:

    node # < mblocks + ablocks (identify a message/auxnode)
    node # >= mblocks (identify an aux/check node)

  Inside each if statement we'd check the left/right neighbour
  properties. Since auxiliary blocks have both left and right
  neighbours, those nodes would match both if statements.


Pseudocode as derived from python code:

Decoder setup:

 pass in filename, file size, block size and seed

 calculate block count from file size, block size

 self.blocks = (check?) blocks file
 aux_blocks  = auxiliary block mapping ({aux -> msg*}* derived from seed)
 aux = [-1] for each aux block
 left = list of (empty) lists. One entry for each composite block
 right = empty list
 recovered[0..#composite blocks -1] = 0
 recovered = 0

 I see that there is one "left" entry for each composite block, so
 based on this I deduce that check blocks are to the left, message
 blocks to the right.

Decode on receiving a new check block:

 pass in block ID (seed) and block contents

 return true if recovered == number of message blocks
 new_index = length of right array (ie, start counting after composite blocks)
 save block contents to file/array

 source_blocks = []
 list = Get list of associated composite blocks for this check block
 foreach item of list:
   push item into source_blocks list
 foreach item of source_blocks:
   set left[item]=new_index  (save links from composite blocks to check blocks)
 push "right" array onto source_blocks (ie, save check block mapping)


 pending = [new_index]   (ie, list with new aux block)
 while pending has elements:

  start = pop pending
  count elements in right[start] that are not recovered
  next unless count == 1

  we have a right (composite) neighbour that has not been recovered yet:
  newly_recovered = -1
  for x in right[start]:
    if x is recovered:
      if x is a message block:
         source = read message block
      else (x is an auxiliary block):
         source = read auxiliary block
      xor start check block with source
    else
      newly_recovered = x

  recovered[newly_recovered] = true

  if newly_recovered is a message block:

    write block to file
    increment recovered

  else

    store recovered aux block:

    create a new index new_index at the top of right array
    write block contents to new index
    aux[new_recovered-#message blocks ] = new_index
    source_blocks = aux_blocks[new_recovered-#message blocks ]

    # store mapping for this aux block:
    # right mapping: aux block to message block
    append source_blocks (ie, message blocks) to right[]
    # left mapping: message block to aux block
    for message block x in source_blocks:
      push new_index onto left[x]

    push new_index onto pending list

  push all left nodes of the new_recovered onto the pending list

  return true if all message blocks have been recovered, false otherwise.


#!/usr/bin/perl

package Net::OnlineCode;

# play nicely as a CPAN module

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);

require Exporter;

our @export_xor = qw (xor_strings safe_xor_strings fast_xor_strings);
our @export_default = qw();

%EXPORT_TAGS = ( 'all' => [ @export_default, @export_xor ],
		 'xor' => [ @export_xor ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = ();
$VERSION = '0.01';

# on to our stuff ...

use constant DEBUG => 1;


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
	      e_warning   => 1,

	      # We don't use or store any RNG parameter that's been
	      # passed into the constructor.
	      @_
	     );


  my ($q,$e,$mblocks) = @args{qw(q e mblocks)};

  unless (defined $args{mblocks}) {
    carp __PACKAGE__ . ": mblocks => (# message blocks) must be set\n";
    return undef;
  }

  my $P = undef;
  my $e_changed = 0;

  # how many auxiliary blocks would this scheme need?
  my $ablocks =  _count_auxiliary($q,$e,$mblocks);

  # does epsilon value need updating?
  my $f = _max_degree($e);
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

    if ($args{e_warning}) {

      print "Is now: $e\n";
      print "New F: $f\n";
    }

  }

  # calculate the probability distribution
  $P = _probability_distribution($mblocks + $ablocks,$e);

  my $self = { q => $q, e => $e, f => $f, P => $P,
	       mblocks => $mblocks, ablocks => $ablocks,
	       e_changed => $e_changed };

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
  #  my $quotient = (log ($epsilon * $epsilon / 4)) /
  #		  (log (1 - $epsilon / 2));

  my $quotient = (2 * log ($epsilon / 2)) /
		  (log (1 - $epsilon / 2));


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

  print "generating probability distribution from nblocks $nblocks, e $epsilon\n";

  my  $f = _max_degree($epsilon);
#  my  $f = shift;

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
    my $p_i   = $pfterm / $iterm;

    $sum += $p_i;

    push @P, $sum;
    $i++;
  }

  if (DEBUG) {
    # Make sure of the assumption that the sum of terms approaches 1.
    # If the "rounding error" below is not a very small number, we
    # know there is a problem with the assumption!
    my $p_last = $sum + $pfterm / ($f * $f - $f);
    my $absdiff = abs (1 - $p_last);
    warn "Absolute difference of 1,sum to p_F = $absdiff\n";
  }

  return [(@P),1];

  # old return:
  # return ($f, $epsilon, @P, 1);
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
    unless ref($array);

  die "fisher_yates_shuffle: 2nd arg not an array ref\n" 
    unless ref($array) eq "ARRAY";

  # Change recipe to pick subset of list
  $picks=scalar(@$array) unless
    defined($picks) and $picks >=0 and $picks<scalar(@$array);

  # algorithm fills picks into the end of the array
  my $i=scalar(@$array);
  while (--$i > $picks - scalar(@$array)) {
    my $j=int($rng->rand($i + 1)); # range [0,$i]
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
  my $rng  = shift;

  croak "auxiliary_mapping: rng is not a reference\n" unless ref($rng);

  # hash slices: powerful, but syntax is sometimes confusing
  my ($nblocks,$aux_blocks) = @{$self}{"mblocks","ablocks"};

  # make sure hash(ref) slice above actually did something sensible:
  # die "weird mblocks/ablocks" unless $nblocks + $aux_blocks >= 2;

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

# Calculate the composition of a single check block based on the
# supplied RNG. Returns a reference to a list of composite blocks
# indices.

sub checkblock_mapping {

  my $self = shift;
  my $rng  = shift;

  croak "rng is not an object reference\n" unless ref($rng);

  my $coblocks = $self->get_coblocks;
  my $P        = $self->{P};

  # use weighted distribution to find how many blocks to link
  my $i = 0;
  my $r = $rng->rand;
  ++$i while($r > $P->[$i]);	# terminates since r < P[last]
  ++$i;

  print "picked $i values for checkblock (from $coblocks)\n";

  # select i composite blocks uniformly
  my $check_mapping = [ (0 .. $coblocks-1) ];
  fisher_yates_shuffle($rng, $check_mapping, $i);

  die "fisher_yates_shuffle problem" unless @$check_mapping == $i;

  return $check_mapping;

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
sub fast_xor_strings { safe_xor_strings(@_) }


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

1;

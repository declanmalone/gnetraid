package Net::OnlineCode::Bones;

use strict;
use warnings;

# "Bones" (or "bundles of node elements") are one of the building
# blocks of the Online Codes decoding algorithm.
#
# First Interpretation: solving a system of algebraic equations
#
# The decoding part of OC algorithm can be explained in terms of
# solving a system of equations. The encoder effectively sends a set
# of equations of the form:
# 
# auxiliary block <- sum of some message blocks
#
# or
#
# check block <- sum of some message blocks and/or aux blocks
#
# The encoder also sends the value of each check block along with the
# equation that it's contained in.
#
# The decoder starts off knowing only the value of the received check
# blocks and the above sets of equations. From these, its task is to
# solve the set of equations and end up with a solution for each
# message block:
#
# message block <- some sum of known check/aux/message blocks
#
# 

# are an encapsulation of two
# data structures that were previously treated as separate. The two
# structures are a list of down edges and an "xor list".
#
# 


# 
sub new {
  my ($class, $graph, $top, $nodes) = @_;
  my $bone = $nodes;
  my $unknowns = scalar(@$nodes);

  die "Bones: refusing to create a bone with empty node list\n"
    unless $unknowns;

  print "new bone $top with list @$nodes\n";

  unshift @$bone, $unknowns;	# count unknowns
  push    @$bone, $top;		# add "top" node to knowns

  print "bone after unshift/push: @$nodes\n";

  my $index = 1;

  while ($index <= $unknowns) {
    if ($graph->{solved}->[$bone->[$index]]) {
#      print "swapping bone known bone index $index with $unknowns\n";
      @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
      --$unknowns;
    } else {
#      print "bone index $index is not known\n";
      ++$index;
    }
  }    

  $bone->[0] = $unknowns;	# save updated count

  bless $bone, $class;
}

# Throw the caller a bone (ahem) if they want to construct the object
# themself (useful in GraphDecoder constructor)
sub bless {
  my ($class, $object) = @_;

  die "Bones: bless is a class method (call with ...::Bones->bless())\n"
    if ref($class);

  die "Net::OnlineCode::Bones::bless can only bless an ARRAY reference\n"
    unless ref($object) eq "ARRAY";

#  warn "Bones got ARRAY to bless: " . (join ", ", @$object) . "\n";

  die "Net::OnlineCode::Bones::bless was given an incorrectly constructed array\n"
    if scalar(@$object) == 0 or $object->[0] > scalar(@$object);

  bless $object, $class;
}


# "Firm up" a bone by turning an unknown node from the left side of
# the equation into a known one on the right side
sub firm {
  my ($bone, $index) = @_;
  my $unknowns = $bone->[0]--;

  @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
}

# The "top" and "bottom" methods only make sense at certain stages in
# the graph evolution, and only if elements are shuffled in the
# correct order with firm() above.
#
# To explain, first note the general evolution of bones. They start with:
#
# [list of unknown nodes] <- [zero or one known node(s)]
#
# In the case of check nodes, there will be one node on the right,
# whereas aux nodes are initially unknown so the list on the right is
# empty.
#
# We want to evolve the lists into the form:
#
# [one unknown node] <- [list of known nodes]
#
# For check nodes that undergo the propagation rule, there is no
# problem: we go from the first form into a final form:
#
# [one "bottom" aux/msg node] <- [ known nodes ... "top" check node ]
#
# This is guaranteed because:
#
# * the check node was always at the end of the list and can never
#   be shuffled elsewhere (firm() only shuffles the left side)
# * the propagation rule always ends with just a single node on the
#   left, which is the "bottom" of the edge
# 
# In the case of bones leading down from auxiliary nodes, however,
# there are two complications:
#
# * the aux node itself starts as being unknown
# * we can still apply the propagation rule even if the aux node is
#   unknown
#
# To preserve the [bottom ... top] format, it is essential that during
# the propagation rule, the auxiliary node is the first element that
# is moved from the unknown side to the known side.
# 

# The "top" node is the number of the check or aux block where the
# bone was first created. It's always the last value of the list
sub top {
  my $bone = shift;

  return $bone->[scalar(@$bone)];  
}

# The "bottom" node will shuffle to the start of the list of unknown
# blocks (call only when there is just a single unknown left)
sub bottom {
  my $bone = shift;

  die "Bones: multiple bottom nodes exist\n" if $bone->[0] > 1;
  return $bone->[1];
}

# how many unknowns on left side?
sub unknowns {
  my $bone = shift;
  return $bone->[0];
}

# how many knowns on right side?
sub knowns {
  my $bone = shift;
  return @$bone - $bone->[0];
}


# For extracting the actual known or unknown elements, rather than
# return a list or spliced part of it, return the range of the knowns
# part of the array for the caller to iterate over. (more efficient)
#
# Both the following subs return an inclusive range [first, last]
# that's suitable for iterating over with for ($first .. $last)
#

sub knowns_range {
  my $bone = shift;
  return ($bone->[0] + 1, scalar(@$bone) - 1); 
}

# unknowns_range can return [1, 0] if there are no unknowns. Beware!
sub unknowns_range {
  my $bone = shift;
  return (1, $bone->[0]); 
}

# Find a single unknown, shift it to the start of the array and mark
# all other nodes as known (used in propagation rule)
sub one_unknown {

  my ($bone, $graph) = @_;

  for (1 .. $bone->[0]) {
    if (!$graph->{solved}->[$_]) {
      @{$bone}[$_,1] = @{$bone}[1,$_] if $_ != 1;
      $bone->[0] = 1;
      return $bone->[1];
    }
  }
  die "Bones: bone has no unknown node\n";
}

# We can use the propagation rule from an aux block to a message
# block, but if the aux block itself is not solved, we end up with two
# unknown values in the list. This routine takes the aux block number
# and the single unknown down edge, marks both of them as unknown and
# the rest as known.
sub two_unknowns {
  my ($bone, $graph)   = @_;
  my ($index, $kindex) = (1,1);
  my $unknowns         = $bone->[0];

  while ($index <= $unknowns) {
    if (!$graph->{solved}->[$_]) {
      @{$bone}[$index,$kindex] = @{$bone}[$kindex,$index]
	if $index != $kindex;
      --$unknowns;
      last if (++$kindex > 2);
    }
  }
  die "Bones: didn't find two unknowns\n" unless $unknowns == 2;

  # swap elments if needed so that message node is first
  @{$bone}[1,2] = @{$bone}[2,1] if $bone->[1] > $bone->[2];
 
  $bone->[0] = 2;
  return $bone->[1];
}

# "pretty printer": output in the form "[unknowns] <- [knowns]"
sub pp {

  my $bone = shift;
  my ($s, $min, $max) = ("[");

#  print "raw bone is ". (join ",", @$bone) . "\n";

  ($min, $max) = $bone->unknowns_range;
#  print "unknown range: [$min,$max]\n";
  $s.= join ", ", map { $bone->[$_] } ($min .. $max) if $min <= $max;

  $s.= "] <- [";

  ($min, $max) = $bone->knowns_range;
#  print "known range: [$min,$max]\n";
  $s.= join ", ", map { $bone->[$_] } ($min .. $max) if $min <= $max;

  return $s . "]";

}

1;

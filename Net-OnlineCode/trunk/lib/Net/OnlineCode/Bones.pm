package Net::OnlineCode::Bones;

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
sub new_bone {
  my ($class, $graph, $top, $nodes) = @_;
  my $bone = $nodes;
  my $unknowns = scalar(@$right_nodes);

  die "Bones: refusing to create a bone with empty node list\n"
    unless $unknowns;

  unshift @$bone, $unknowns;	# count unknowns
  push    @$bone, $top;		# add "top" node to knowns

  my $index = 1;

  while ($index <= $unknowns) {
    if ($graph->{unknowns}->[$bone->[$index]] == 0) {
      @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
      --$unknowns;
    } else {
      ++$index;
    }
  }    

  $bone->[0] = $unknowns;	# save updated count

  bless $bone, $class;
}

# The "top" node is the number of the check or aux block where the
# bone was first created. It's always the last value of the list
sub top_node {
  my $bone = shift;

  return $bone->[$#bone];  
}

# how many unknowns on left side?
sub unknowns {
  my $bone = shift;
  return $bone->[0];
}

# For extracting the actual known or unknown elements, rather than
# return a list or spliced part of it, return the range of the knowns
# part of the array for the caller to iterate over.
#
# Both the following subs return an inclusive range [first, last]
# that's suitable for iterating over with for ($first .. $last)
#

sub knowns_range {
  my $bone = shift;
  return ($bone->[0] + 1, $#bone); 
}

# unknowns_range can return [1, 0] if there are no unknowns. Beware!
sub unknowns_range {
  my $bone = shift;
  return (1, $bone->[0]); 
}


# "Firm up" a bone by turning a node from the left side of the
# equation into a newly-known one on the right side
sub firm_bone {
  my ($bone, $index) = @_;
  my $unknowns = $bone->[0]--;

  @{$bone}[$index,$unknowns] = @{$bone}[$unknowns,$index];
}

# scan the list of unknowns on the left hand side to see if one is
# known
sub find_known {
  my ($bone, $graph) = @_;

  for (1 .. $bone->[0]) {
    return $_ if $graph->{unknowns}->[$_] == 0;
  }
  return undef;
}

1;

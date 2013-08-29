package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use constant DEBUG => 1;

# Implements a data structure for decoding the bipartite graph (not
# needed for encoding). Note that this does not store Block IDs or any
# actual block data and, consequently, does not do any XORs. Those
# tasks are left to the calling object/programs. The reason for this
# separation is to allow us to focus here on the graph algorithm
# itself and leave the implementation details (ie, synchronising the
# random number generator and storing and XORing blocks) to the user.

# Rather than referring to left and right neighbours, I used the
# ordering of the array and higher/lower to indicate the relative
# positions of check, auxiliary and message blocks, respectively. The
# ordering is:
#
#   message < auxiliary < check	

sub new {
  my $class = shift;

  # constructor starts off knowing only about auxiliary block mappings
  my ($mblocks, $ablocks, $auxlist, $expand_aux) = @_;

  unless ($mblocks >= 1) {
    carp "$class->new: argument 1 (mblocks) invalid\n";
    return undef;
  }

  unless ($ablocks >= 1) {
    carp "$class->new: argument 2 (ablocks) invalid\n";
    return undef;
  }

  unless (ref($auxlist) eq "ARRAY") {
    carp "$class->new: argument 3 (auxlist) not a list reference\n";
    return undef;
  }

  unless (@$auxlist == $mblocks + $ablocks) {
    carp "$class->new: auxlist does not have $mblocks + $ablocks entries\n";
    return undef;
  }

  $expand_aux = 1 unless defined($expand_aux);

  my $self =
    {
     mblocks    => $mblocks,
     ablocks    => $ablocks,
     coblocks   => $mblocks + $ablocks, # "composite"
     expand_aux => $expand_aux,
     neighbours     => undef,
     edges          => [],
     solved         => [],
     deleted        => [],
     unsolved_count => $mblocks,
     xor_hash       => [],
    };

  # work already done in auxiliary_mapping in Decoder
  $self->{neighbours} = $auxlist;

  # update internal structures
  for my $i (0..$mblocks + $ablocks - 1) {
    # mark blocks as unsolved, and having no XOR expansion
    $self->{solved}   ->[$i] = 0;
    $self->{xor_hash} ->[$i] = {};
    $self->{deleted}  ->[$i] = 0;

    # empty edge structure
    push $self->{edges}, {};
  }

  # set up edge structure (same as neighbours, but using hashes)
  for my $i (0..$mblocks + $ablocks - 1) {
    for my $j (@{$auxlist->[$i]}) {
      $self->{edges}->[$i]->{$j} = 1;
      $self->{edges}->[$j]->{$i} = 1;
    }
  }

  bless $self, $class;
}




# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

sub old_add_check_block {
  my $self = shift;
  my $nodelist = shift;

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  # new node number for this check block
  my $node = scalar @{$self->{neighbours}};
  #warn "add_check_block: adding new node index $node\n";

  # store this check block's neighbours
  $self->{neighbours}->[$node] = $nodelist;

  # store reciprocal links
  foreach my $i (@$nodelist) {
    push $self->{neighbours}->[$i], $node;
  }

  # return index of newly created node
  return $node;
}


# Traverse the graph starting at a given check block node. Returns a
# list with a flag to indicate the graph is fully decoded, followed by
# the list of message nodes that have been solved this call.

sub old_resolve {

  my $self = shift;
  my $node = shift;		# start node

  if ($node < $self->{mblocks}) {
    croak ref($self) . "->resolve: start node '$node' is a message block!\n";
  }

  my $finished = 0;
  my @newly_solved = ();
  my @pending= ($node);
  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};

  return (1) unless $self->{unsolved_count};

  while (@pending) {

    my $start  = shift @pending;
    my $solved = undef;		# we can solve at most one unknown per
                                # iteration

    print "Resolving node $start\n" if DEBUG;

    # check for unsolved lower neighbours
    my @unsolved = grep { $_ < $start and !$self->{solved}->[$_]
		     } @{$self->{neighbours}->[$start]};

    if (@unsolved == 0) {	# bubble up solution for auxiliary block

      next unless $self->is_auxiliary($start);
      next if     $self->{solved}->[$start];

      print "Can bubble up aux block $start\n";
      next;

    } elsif (@unsolved == 1) {

      # if we have exactly one unsolved lower neighbour then we can
      # solve that node

      $solved = shift @unsolved; # newly solved
      my @solved = grep {		# previously solved
	$_ < $start and $_ != $solved
      } @{$self->{neighbours}->[$start]};

      print "Start node $start can solve node $solved\n";

      # $self->{solved}->[$solved] = 1;
      # push @newly_solved, $solved;

      # The solution to the newly solved message or auxiliary block is
      # the XOR of the start node (or its expansion) and the expansion
      # of all the start node's previously solved neighbours

      if ($solved < $mblocks + $ablocks) {	# composite  block
	#print "toggling check node $start into $solved\n" if DEBUG;
	$self->toggle_xor($solved,$start);

        for my $i (@solved) {
	  my $href= $self->{xor_hash}->[$i];
	  $self->merge_xor_hash($solved, $href);
	}

      } else {
	croak "resolve: BUG! check $start can't solve checkblocks\n";
      }

      if ($self->{solved}->[$start]) {
	$self->{solved}->[$solved] = 1;
	push @newly_solved, $solved;
      } else {
	warn "Start node $start is not solved yet\n";
      }


      if ($self->is_message($solved)) {
	unless (--($self->{unsolved_count})) {
	  $finished = 1;
	  @pending = ();	# no need to search any more nodes
	}
      }

      #die "Solved an auxiliary block\n" if $self->is_auxiliary($solved);

      unless ($finished) {
	if (0) {
	  # queue *everything* to debug this part
	  @pending = (0..@{$self->{neighbours}});
	} else {
	  # queue up the newly solved node and all its neighbouring check nodes
	  push @pending, grep { $_ > $solved } @{$self->{neighbours}->[$solved]};
	  push @pending, $solved unless $self->is_message($solved);
	}
      }
    }
  }

  # make sure that all edges that could be solved were

  if (0 and !$finished) {
    for my $left ($mblocks .. scalar($self->{neighbours})) {

      my @unsolved = grep { $_ < $left and !$self->{solved}->[$_]
			  } @{$self->{neighbours}->[$left]};
      if (@unsolved == 1) {
	warn "failed to solve block $left (one unsolved child)\n";
      }
      if (@unsolved == 0) {
	next if $left >= $ablocks;
	next if $self->{solved}->[$left];
	die "failed to solve block $left (no unsolved messages)\n";
      }
    }
  }

  return ($finished, @newly_solved);

}

sub is_message {
  my ($self, $i) = @_;
  return ($i < $self->{mblocks});
}

sub is_auxiliary {
  my ($self, $i) = @_;
  return (($i >= $self->{mblocks}) && ($i < $self->{coblocks}));
}

sub is_composite {
  my ($self, $i) = @_;
  return ($i < $self->{coblocks});
}

sub is_check {
  my ($self, $i) = @_;
  return ($i >= $self->{coblocks});
}


#
sub toggle_xor {
  my ($self, $solved, $i,@junk) = @_;

  # since I don't do the XOR of check or auxiliary blocks immediately,
  # I need a structure to store the deferred operations. This
  # structure has to account for the property of the XOR operation,
  # namely that XORing the same value twice is a null operation.  A
  # simple list would work, but by working with a hash instead (as
  # done here) we can efficiently eliminate pairs of XORs, potentially
  # saving the calling program costly disk accesses.

  # $solved is the block that has been solved, and $i is one term in
  # the expansion.

  croak "toggle_xor got extra junk parameter" if @junk;

  if ($solved >= $self->{coblocks}) {
    carp "Asked to toggle the XOR value of a check block!\n";
  }
  print "Toggling $i into $solved\n" if DEBUG;

  # Profiling indicates that this is a very heavily-used sub, so a
  # simple change to avoid various object dereferences should help:
  my $href=$self->{xor_hash}->[$solved];

  if (exists($href->{$i})) {
    delete $href->{$i};
  } else {
    $href->{$i} = 1;
  }
}

# toggle all keys from a hashref into a solved node
sub merge_xor_hash {
  my ($self, $solved, $href) = @_;

  unless (ref($href) eq 'HASH') {
    carp "merge_xor_hash: need a hashref as second argument\n";
    return;
  }

  print "merging node numbers: " . (join ",", keys %$href) . "\n" if DEBUG;
  foreach (keys %$href) {
    print "toggling term: $_\n" if DEBUG;
    $self->toggle_xor($solved,$_);
  }
}

# return a reference to the hash so that caller may modify values
sub xor_hash {
  my ($self,$i) = @_;
  #print "xor_hash asked to look up $i\n";
  if (defined ($i)) {
    return $self->{xor_hash}->[$i];
  } else {
    return $self->{xor_hash};
  }
}

# return the keys of xor_hash as a list, honouring expand_aux flag
sub xor_list {
  my ($self,$i) = @_;

  croak "xor_list requires a numeric argument (message block index)\n"
    unless defined($i);

  my $href   = $self->{xor_hash}->[$i];

  if ($self->{expand_aux}) {

    my $mblocks  = $self->{mblocks};
    my $coblocks = $self->{coblocks};
    my %xors = ();
    my @queue = keys %$href;

    while (@queue) {
      my $block = shift @queue;
      if ($block >= $coblocks) { # check block -> no expand
	if (exists($xors{$block})) {
	  delete $xors{$block};
	} else {
	  $xors{$block} = 1;
	}
      } elsif ($block >= $mblocks) { # aux block
	push @queue, keys $self->{xor_hash}->[$block];
      } else {
	die "BUG: message block found in xor list!\n";
      }
    }
	
   return keys %xors;

  } else {
    # return unfiltered list
    return (keys %$href);
  }
}


# new approach to graph: use explicit edge structure and remove them
# as we resolve the graph

sub add_check_block {
  my $self = shift;
  my $nodelist = shift;

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  # new node number for this check block
  my $node = scalar @{$self->{neighbours}};
  #warn "add_check_block: adding new node index $node\n";

  print "New check block $node: " . (join " ", @$nodelist) . "\n";

  # continue to use the neighbours structure, but use a parallel
  # "edge" structure that stores node numbers in a hash (also
  # reciprocally)

  my $new_hash = {};		# new edge hash for this check block
  $self->{deleted}->[$node]=0;

  # it simplifies the algorithm if each check block is marked as
  # (trivially) being composed of only itself. (this way we don't have
  # to include separate cases for check and aux blocks)
  push $self->{xor_hash}, { $node => 1};
  # likewise, we mark check blocks as solved (ie, having a known value)
  $self->{solved}->[$node]=1;

  # store this check block's neighbours
  push $self->{neighbours},  $nodelist;

  # store edges, reciprocal links
  foreach my $i (@$nodelist) {
    push $self->{neighbours}->[$i], $node;

    $new_hash->{$i} = 1;
    $self->{edges}->[$i]->{$node} = 1;
  }

  push $self->{edges}, $new_hash;

  # return index of newly created node
  return $node;
}

sub delete_edge {

  my ($self,$from,$to) = @_;

  print "Deleting edge $from, $to\n";

  delete $self->{edges}->[$from]->{$to};
  delete $self->{edges}->[$to]->{$from};

}


# the strategy here will be to simplify the graph on each call by
# deleting edges.
#
# For the sake of this explanation, assume that check nodes are to
# the left of the auxiliary and message blocks. Check nodes have a
# known value, while (initially, at least), auxiliary and message
# blocks have unknown values.
#
# We work our way from known nodes on the left to solve unknowns on
# the right. As nodes on the right become known, we save the list of
# known left nodes that comprise it in the node's xor list, and then
# delete those edges (in fact, each edge becomes an element in the
# xor list). When a node has no more left edges, it is marked as
# solved.
#
# There is one rule for propagating a known value from left to
# right: when the right node has a left neighbour with exactly one
# right edge.
#
# We can also delete edges if both the left and right nodes are
# solved (the edge being superflous in this case)


sub resolve {

  # same boilerplate as before
  my $self = shift;
  my $node = shift;		# start node

  if ($node < $self->{mblocks}) {
    croak ref($self) . "->resolve: start node '$node' is a message block!\n";
  }

  my $finished = 0;
  my @newly_solved = ();
  my @pending= ($node);
  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};

  return (1) unless $self->{unsolved_count};
  while (@pending) {

    # We treat this as a directed graph, with edges coming from check
    # or auxiliary nodes to auxiliary/message nodes (or left to right
    # as above)
    my ($from, $to) = (shift @pending);

    next unless $self->{solved}->[$from];

    my @right_nodes = grep { $_ < $from } keys $self->{edges}->[$from];

    my $right_degree = scalar(@right_nodes);

    print "Starting node: $from has right nodes: " . (join " ", @right_nodes) . "\n";
    print "(right degree $right_degree)\n";

    my @merge_list =($self->{xor_hash}->[$from]);

    while ($right_degree--) {
      my $to = shift @right_nodes;
      if ($self->{solved}->[$to]) {
	push @merge_list, $self->{xor_hash}->[$to];
      } else {
	push @right_nodes, $to;	# put it back in list
      }
    }

    if (@right_nodes == 1) {

      # we have found a node that matches the propagation rule
      $to = shift @right_nodes;

      print "Node $from solves node $to\n";

      $self->delete_edge($from,$to);
      foreach my $i (@merge_list) {
	$self->merge_xor_hash($to, $i);
      }

      # left nodes are to's left nodes
      my @left_nodes = grep { $_ > $to } keys $self->{edges}->[$to];

      # mark node as solved
      $self->{solved}->[$to] = 1;
      push @newly_solved, $to;

      if ($to < $mblocks) {
	print "Solved message block $to completely\n";
	unless (--($self->{unsolved_count})) {
	  $finished = 1;
	  @pending = ();
	  last;			# finish searching
	}

	# solving a message block can also let us eliminate aux blocks
	# by the same propagation rule (going right to left)
	#
	# In this case, the rule is restated as "if a neighbouring
	# unsolved auxiliary neighbour has no unsolved right
	# neighbour, then it can be solved". The actual value is the
	# XOR of all its children.
	#
	# If we don't do this, then it may take longer to decode. It
	# doesn't help us immediately with solving any more message
	# blocks (since by definition the aux block solved in this way
	# has no other message blocks as neighbours), but it can allow
	# check blocks further up to make progress.

	foreach my $back (@left_nodes) {

	  # still slightly buggy
	  next;

	  next unless $self->is_auxiliary($back);
	  next if     $self->{solved}->[$back];

	  @right_nodes = grep { $_ < $back and !$self->{solved}->[$_] }
	    keys $self->{edges}->[$back];

	  if (@right_nodes == 0) {
	    print "Back-propagating from $to to auxiliary $back\n";
	    $self->{xor_hash}->[$back] = {};
	    foreach my $child ($self->{neighbours}->[$back]) {
	      next unless $child < $back;
	      $self->merge_xor_hash($back, $self->{xor_hash}->[$child]);
	    }

	    $self->delete_edge($back,$to);
	    $self->{solved}->[$back] = 1;
	    push @newly_solved, $back;
	    push @pending,  grep { $_ > $back } keys $self->{edges}->[$back];
	  }
	}
      } else {
	print "Solved auxiliary block $to completely\n";
	push @pending, $to;
      }

      if (@left_nodes) {
	print "Solved node $to still has left nodes " . (join " ", @left_nodes) . "\n";
      } else {
	print "Solved node $to has no left nodes\n";
      }
      push @pending, @left_nodes;

    }
  }

  return ($finished, @newly_solved);

}

1;

__END__

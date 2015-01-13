package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use vars qw($VERSION);

$VERSION = '0.02';

use constant DEBUG => 1;
use constant TRACE => 0;
use constant ASSERT => 1;	# Enable extra-paranoid checks

# Implements a data structure for decoding the bipartite graph (not
# needed for encoding). Note that this does not store Block IDs or any
# actual block data and, consequently, does not do any XORs. Those
# tasks are left to the calling object/programs. The reason for this
# separation is to allow us to focus here on the graph algorithm
# itself and leave the implementation details (ie, synchronising the
# random number generator and storing and XORing blocks) to the user.

# Simple low-level operations to improve readability (and allow for
# single debugging points)

sub is_solved {
  my ($self,$node) = @_;

  $self->{solved}->[$node];
}

sub mark_as_unsolved {
  my ($self,$node) = @_;

  print "Marking block $node as unsolved\n" if DEBUG;
  $self->{solved}->[$node] = 0;
}

sub mark_as_solved {
  my ($self,$node) = @_;

  if (0 and DEBUG) {		# wasn't a bug after all
    my ($parent,$line) = (caller(1)) [3,2];
    print "mark_as_solved called from sub $parent, line $line\n";
  }

  print "Marking block $node as solved\n" if DEBUG;

  $self->{solved}->[$node] = 1;
}

sub edge_list {
  my ($self,$node) = @_;
  keys %{$self->{edges}->[$node]};
}

sub add_half_edge {
  my ($self,$from,$to) = @_;

  die "Tried to add half-edge from node $from to itself\n"
    if (ASSERT and $from == $to);

  die "Tried to add existing half-edge from $from to $to\n"
    if (ASSERT and exists($self->{edges}->[$from]->{$to}));

  print "Adding half-edge $from, $to\n" if DEBUG;

  $self->{edges}->[$from]->{$to} = undef;
}


sub add_edge {

  my ($self,$from,$to) = @_;

  $self->add_half_edge($to,$from);
  $self->add_half_edge($from,$to);

}

sub delete_edge {

  my ($self,$from,$to) = @_;

  print "Deleting edge $from, $to\n" if DEBUG;

  delete $self->{edges}->[$from]->{$to};
  delete $self->{edges}->[$to]->{$from};

}

sub xor_hash_list {
  my ($self,$node) = @_;
  keys %{$self->{xor_hash}->[$node]}
}

sub add_to_xor_hash {
  my ($self,$node,$adding) = @_;

  if (DEBUG) {
    print "Adding $adding to node $node\'s xor hash\n";
    print "Previous XOR list: " . (join ", ", sort $self->xor_hash_list($node)) . "\n";
  }

  if (ASSERT and exists($self->{xor_hash}->[$node]->{$adding})) {
    die "ASSERT: asked to add $adding to node $node\'s xor hash, but it already exists\n";
  }

  $self->{xor_hash}->[$node]->{$adding}=undef;
  print "Updated XOR list: " . (join ", ", sort $self->xor_hash_list($node)) . "\n";}


sub free_xor_hash {
  my ($self,$from) = @_;
  $self->{xor_hash}->[$from] = undef;
}

sub incorporate_solved {

  my ($self,$node,$solved) = @_;

  # this routine deletes solved edges and updates the XOR list as appropriate
  # if the solved node is an aux block, we xor the node with its node number
  # if the solved node is a message block, we xor in all of its xor list

  # This means that eventually all solutions will be in terms of
  # auxiliary blocks and check blocks, but never message blocks.

  if (ASSERT and $self->is_message($node)) {
    die "Message blocks can't have other nodes incorporated into them\n";
  }

  #if (ASSERT and $self->is_check($node)) {
  #  die "Check blocks can't be incorporated into other nodes\n";
  #}

  print "Incorporating previously solved node $solved into node $node\n" if DEBUG;

  $self->delete_edge($node,$solved);

  if ($self->is_message($solved)) {

    print "Incorporating expansion of message block $solved into $node\n" 
      if DEBUG;
    map { $self->toggle_xor($node,$_) } $self->xor_hash_list($solved);

  } else {

    print "Incorporating auxiliary block number $solved into $node\n" if DEBUG;
    $self->toggle_xor($node,$solved);
  }

}

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
     neighbours     => undef,	# will only store aux block mappings
     edges          => [],	# stores both check, aux block mappings
     solved         => [],
     unsolved_count => $mblocks,
     nodes          => $mblocks + $ablocks, # running count
     xor_hash       => [],
     iter           => 0,	# debug use
    };

  # work already done in auxiliary_mapping in Decoder
  $self->{neighbours} = $auxlist;

  bless $self, $class;

  # update internal structures
  for my $i (0..$mblocks + $ablocks - 1) {
    # mark blocks as unsolved, and having no XOR expansion
    $self->mark_as_unsolved($i);
    $self->{xor_hash} ->[$i] = {};

    # empty edge structure
    push @{$self->{edges}}, {}; # 5.14
  }

  # set up edge structure (same as neighbours, but using hashes)
  for my $i (0..$mblocks + $ablocks - 1) {
    for my $j (@{$auxlist->[$i]}) {
      $self->add_half_edge($i,$j);
    }
  }

  $self;
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


# Set operator: inverts membership
sub toggle_xor {
  my ($self, $node, $member, @junk) = @_;

  # updates target by xoring value into it

  croak "toggle_xor got extra junk parameter" if @junk;

  print "Toggling $member into $node\n" if DEBUG;

  # Profiling indicates that this is a very heavily-used sub, so a
  # simple change to avoid various object dereferences should help:
  my $href=$self->{xor_hash}->[$node];

  if (exists($href->{$member})) {
    delete $href->{$member};
  } else {
    $href->{$member} = undef;
  }

  print "Updated XOR list: " . (join ", ", sort $self->xor_hash_list($node)) . "\n";

}

# toggle all keys from a hashref into a solved node
sub merge_xor_hash {
  my ($self, $target, $href) = @_;

  unless (ref($href) eq 'HASH') {
    carp "merge_xor_hash: need a hashref as second argument\n";
    return;
  }

  print "merging node numbers: " . (join ",", keys %$href) . "\n" if DEBUG;
  foreach (keys %$href) {
    print "toggling term: $_\n" if DEBUG;
    $self->toggle_xor($target,$_);
  }
}

# return a reference to the hash so that caller may modify values
sub xor_hash {
  my ($self,$i) = @_;
  if (defined ($i)) {
    return $self->{xor_hash}->[$i];
  } else {
    croak "xor_hash: need an index parameter\n";
    # return $self->{xor_hash};
  }
}

# return the keys of xor_hash as a list, honouring expand_aux flag
sub xor_list {
  my ($self,$i) = @_;

  croak "xor_list requires a numeric argument (message block index)\n"
    unless defined($i);

  my $href   = $self->{xor_hash}->[$i];
  return (keys %$href);

  if (0 and $self->{expand_aux}) {

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
	push @queue, $self->xor_hash_list($block);
      } else {
#	die "BUG: message block found in xor list!\n";
	if (exists($xors{$block})) {
	  delete $xors{$block};
	} else {
	  $xors{$block} = 1;
	}
      }
    }
	
   return keys %xors;

  } else {
    # return unfiltered list
    return (keys %$href);
  }
}

# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

# new approach to graph: use explicit edge structure and remove them
# as we resolve the graph

# This routine returns either a node number or zero if it didn't add
# any new information. In the latter case, the calling routine
# (accept_check_block) shouldn't do anything.

sub add_check_block {
  my $self = shift;
  my $nodelist = shift;

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  # we'll check whether this new block provides any new information by
  # incrementing unsolved for each unsolved right neighbour. As we go,
  # we'll populate some temporary structures that will be put into the
  # main data structure only if it turns out that this block adds some
  # new information.

  my $new_hash={};		# our side of the new graph edges

  my $solved = 0;
  my @solved = ();
  foreach my $i (@$nodelist) {
    if ($self->is_solved($i)) {
      ++$solved;
      push @solved, $i;
    }
  }

  if ($solved == scalar(@$nodelist)) {
    print "Discarded check block since contents are solved already : [ " .
      (join (", ", @$nodelist)) . " ]\n" if DEBUG;
    return 0;
  }

  # we're good to go: this new block adds information

  # new node number for this check block
  my $node = $self->{nodes}++;

  print "New check block $node: " . (join " ", @$nodelist) . "\n" if DEBUG;
  print "of which, there are $solved solved node(s): " . (join " ", @solved) . "\n" if DEBUG;

  push @{$self->{xor_hash}}, { };
  $self->mark_as_solved($node);
  push @{$self->{edges}}, {};

  # store edges
  foreach my $i (@$nodelist) {
    $self->add_edge($node,$i);
  }

  # return index of newly created node
  return $node;

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
# right: when the left node has exactly one right neighbour

sub resolve_old {

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

    my ($from, $to) = (shift @pending);

    unless ($self->is_solved($from)) {
      print "skipping unsolved from node $from\n" if DEBUG;
      next;
    }

    my @right_nodes;
    my @merge_list = ($from);

    my $count_right = 0;
    foreach $to ($self->edge_list($from)) {
      next unless $to < $from;
      if ($self->is_solved($to)) {
	push @merge_list, $to;
      } else {
#	last if ++$count_right > 1; # optimisation
	++$count_right;
	push @right_nodes, $to;	# unsolved
      }
    }

    print "Starting node: $from has right nodes: " . (join " ", @right_nodes)
      . "\n" if DEBUG;

    print "Unsolved right degree: " . scalar(@right_nodes) . "\n" if DEBUG;


    if ($count_right == 0) {
      next;

      # if this is a check block with no unsolved right nodes, free
      # any memory it uses
      next if $from < $mblocks + $ablocks;

      $self->{xor_hash}->[$node] = undef;
      foreach my $to (@merge_list) {
	$self->delete_edge($from,$to);
      }

    } elsif ($count_right == 1) {

      # we have found a node that matches the propagation rule
      $to = shift @right_nodes;

      print "Node $from solves node $to\n" if DEBUG;
      print "Node $from has XOR list: " . 
	(join ", ", $self->xor_hash_list($to)) . "\n" if DEBUG;
						   

      $self->delete_edge($from,$to);
      foreach my $i (@merge_list) {
	print "=> Adding $to to XOR list\n" if DEBUG;

	$self->add_to_xor_hash($to,$i);
	$self->delete_edge($from,$i);
      }

      # left nodes are to's left nodes
      my @left_nodes = grep { $_ > $to } $self->edge_list($to);

      $self->mark_as_solved($to);
      push @newly_solved, $to;

      if ($to < $mblocks) {
	print "Solved message block $to completely\n" if DEBUG;
	unless (--($self->{unsolved_count})) {
	  $finished = 1;
	  # comment out next two lines to continue decoding just in
	  # case there's a bug later
	  @pending = ();
	  last;			# finish searching
	}

      } else {
	print "Solved auxiliary block $to completely\n" if DEBUG;
	push @pending, $to;
      }

      # if this is a checkblock, free space reserved for xor_hash
      if ($from > $mblocks + $ablocks) {
	$self->free_xor_hash($from);
      }

      if (@left_nodes) {
	print "Solved node $to still has left nodes " . (join " ", @left_nodes)
	  . "\n" if DEBUG;
      } else {
	print "Solved node $to has no left nodes (no cascade)\n" if DEBUG;
      }
      push @pending, @left_nodes;

    }



  }

  return ($finished, @newly_solved);

}

# start again with resolve

sub resolve {

  # same boilerplate as before
  my $self = shift;
  my $start_node = shift;

  if ($start_node < $self->{mblocks}) {
    croak ref($self) . "->resolve: start node '$start_node' is a message block!\n";
  }

  my $finished = 0;
  my @newly_solved = ();
  my @pending= ($start_node);
  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};

  # exit if all message blocks are already solved
  return (1) unless $self->{unsolved_count};

  while (@pending) {		# list of nodes to check

    my ($from, $to) = (shift @pending);

    unless ($self->is_solved($from)) {
      print "skipping unsolved from node $from\n" if DEBUG;
      next;
    }

    my @unsolved_nodes;		# blocks we might solve with this node
    my $count_unsolved = 0;	# size of above array

    foreach $to ($self->edge_list($from)) {
      next unless $to < $from;
      if ($self->is_solved($to)) {
	$self->incorporate_solved($from, $to);
      } else {
	push @unsolved_nodes, $to;
	++$count_unsolved;
      }
    }

    print "Starting node: $from has right nodes: " . (join " ", @unsolved_nodes)
      . "\n" if DEBUG;

    print "Unsolved right degree: " . scalar(@unsolved_nodes) . "\n" if DEBUG;


    if ($count_unsolved == 0) {
      next;			# we could free this block's memory
                                # here if we wanted
    }

    if ($count_unsolved == 1) {

      # we have found a node that matches the propagation rule
      $to = shift @unsolved_nodes;

      print "Node $from solves node $to\n" if DEBUG;

      $self->mark_as_solved($to);
      push @newly_solved, $to;

      # at this point our node should have all solved blockes already
      # in the xor hash. We need to propagate that list, plus our own
      # node to the newly-solved node.

      print "Node $from has XOR list: " . 
	(join ", ", $self->xor_hash_list($from)) . "\n" if DEBUG;
						   
      $self->delete_edge($from,$to);
      foreach my $i ($from, $self->xor_hash_list($from)) {
	print "=> Adding $to to XOR list\n" if DEBUG;

	if ($self->is_message($i)) {
	  print "Expanding solution of message block $i into $from\n" 
	    if DEBUG;

	  map { $self->toggle_xor($to,$_) } $self->xor_hash_list($i);
	} else {
	  print "Direct insertion of aux/check block $i into $to\n" 
	    if DEBUG;
	  $self->toggle_xor($to,$i);
	}

	$self->delete_edge($from,$i);
      }

      # Update global structure and decide if we're done

      if ($to < $mblocks) {
	print "Solved message block $to completely\n" if DEBUG;
	unless (--($self->{unsolved_count})) {
	  $finished = 1;
	  # comment out next two lines to continue decoding just in
	  # case there's a bug later
	  @pending = ();
	  last;			# finish searching
	}

      } else {
	print "Solved auxiliary block $to completely\n" if DEBUG;
	push @pending, $to;
      }

      # Cascade to potentially find more solvable blocks

      # left nodes are to's left nodes
      my @left_nodes = grep { $_ > $to } $self->edge_list($to);


      # if this is a checkblock, free space reserved for xor_hash
      if ($from > $mblocks + $ablocks) {
#	$self->free_xor_hash($from);
      }

      if (@left_nodes) {
	print "Solved node $to still has left nodes " . (join " ", @left_nodes)
	  . "\n\n" if DEBUG;
      } else {
	print "Solved node $to has no left nodes (no cascade)\n\n" if DEBUG;
      }

      push @pending, @left_nodes;

    }



  }

  return ($finished, @newly_solved);

}


1;

__END__

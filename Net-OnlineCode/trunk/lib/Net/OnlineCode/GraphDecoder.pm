package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use vars qw($VERSION);

$VERSION = '0.03';

use constant DEBUG => 1;
use constant TRACE => 0;
use constant ASSERT => 1;
use constant STEPPING => 1;

use Net::OnlineCode::Bones;

# Implements a data structure for decoding the bipartite graph (not
# needed for encoding). Note that this does not store Block IDs or any
# actual block data and, consequently, does not do any XORs. Those
# tasks are left to the calling object/programs. The reason for this
# separation is to allow us to focus here on the graph algorithm
# itself and leave the implementation details (ie, synchronising the
# random number generator and storing and XORing blocks) to the user.

# Simple low-level operations to improve readability (and allow for
# single debugging points)

sub mark_as_unsolved {
  my ($self,$node) = @_;

  print "Marking block $node as unsolved\n" if DEBUG;
  $self->{solution}->[$node] = 0;
}

sub mark_as_solved {
  my ($self,$node) = @_;

  print "Marking block $node as solved\n" if DEBUG;

  $self->{solution}->[$node] = 1;
}


sub add_edge {

  my ($self,$high,$low) = @_;

  # moving to up and down edges means order is important
  if (ASSERT) {
    die "add_edge: from must be greater than to" unless $high > $low;
  }

  my $mblocks = $self->{mblocks};

  $self->{n_edges}->[$low]->{$high} = undef;
  push @{$self->{v_edges}->[$high-$mblocks]}, $low;
  
}

sub delete_up_edge {

  my ($self,$high,$low) = @_;
  my $mblocks = $self->{mblocks};

  print "Deleting n edge from $low up to $high\n" if DEBUG;

  # I also want to incorporate updates to the count of unsolved edges
  # here, and that would require that $high is greater than $low:
  if (ASSERT and $low >= $high) {
    die "delete_edge: 1st arg $high not greater than 2nd arg $low\n";
  }
  die "Can't cascade from a message block\n" if ASSERT and $high < $mblocks;

  delete $self->{n_edges}->[$low]->{$high};

  # update unsolved edge counts (upper must be ablock or cblock)
  print "Decrementing edge_count for block $high\n" if DEBUG;
  die "Count for node $high went negative\n" unless
      ($self->{edge_count}->[$high - $mblocks])--;
}


# Rather than referring to left and right neighbours, I used the
# ordering of the array and higher/lower to indicate the relative
# positions of check, auxiliary and message blocks, respectively. The
# ordering is:
#
#   message < auxiliary < check	
#
# Using this ordering, message blocks are "lower" than auxiliary and
# check blocks and vice-versa. Equivalently, message blocks have no
# "lower" nodes and check blocks have no "higher" nodes, while
# auxiliary blocks have both.
#
# This can be used as a mnemonic: there is nothing lower than message
# blocks since without them, the sender would not be able to construct
# auxiliary or check blocks and the receiver would not be able to
# receive anything. Equivalently, think of aux and check blocks as
# "higher-level" constructs moving "up" the software stack.

sub new {
  my $class = shift;

  # constructor starts off knowing only about auxiliary block mappings
  # my ($mblocks, $ablocks, $auxlist, $expand_aux) = @_;
  my ($mblocks, $ablocks, $auxlist) = @_;

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

  my $self =
    {
     mblocks    => $mblocks,
     ablocks    => $ablocks,
     coblocks   => $mblocks + $ablocks, # "composite"

     # Replace single edges list with lists of v_edges (down) and
     # n_egdes (up). Up edges will continue to be tracked as a list of
     # hashes, but down edges will move to being a list of lists since
     # we never need to delete single edges from it. These lists will
     # also be indexed differently: the up edge list starts with
     # message blocks (as before) but the down edge list starts with
     # aux blocks (since message blocks have no down edges)
     v_edges        => [],	# down: mnemonic "v" points down
     n_edges        => [],	# up: mnemonic "n" is like upside-down "v"
     xor_list       => [],

     # Edges will be replaced again, this time with "bones", which are
     # a combination of old v_edges and xor_lists. The top and bottom
     # structures store links to the bones objects.
     top            => [],	# from aux/check
     bottom         => [],	# to message/aux
     solution       => [],      # message/aux; will be a bone

     edge_count     => [],	# count unsolved "v" edges (aux, check only)
     edge_count_x   => [],	# "transparent" edge count (check only)
     solved         => [],

     # edge_count and solved arrays will be replaced with a single
     # unknowns array that contains a count of unknown component nodes
     unknowns       => [],
     

     nodes          => $mblocks + $ablocks, # running count
     unresolved     => [],      # queue of nodes needing resolution

     unsolved_count => $mblocks,# count unsolved message blocks
     done           => 0,       # all message nodes decoded?
    };

  bless $self, $class;

  # set up basic structures
  for my $i (0..$mblocks + $ablocks - 1) {
    # mark blocks as unsolved, and having no XOR expansion
    $self->mark_as_unsolved($i);
    $self->{xor_list} ->[$i] = [];
    push @{$self->{n_edges}}, {};
    push @{$self->{v_edges}}, [] if $i >= $mblocks;
    push @{$self->{bottom}}, {}; # hash, like n_edges
  }

  # set up edge structure (convert from auxlist's list of lists)
  for my $i (0..$mblocks -1) {
    for my $j (@{$auxlist->[$i]}) {
      $self->{n_edges}->[$i]->{$j} = undef;
    }
  }
  for my $i ($mblocks .. $mblocks + $ablocks - 1) {
    push @{$self->{v_edges}->[$i-$mblocks]}, @{$auxlist->[$i]}
  }

  # Set up auxiliary mapping in terms of bones
  for my $aux ($mblocks .. $mblocks + $ablocks - 1) {

    # The top end aggregates several down links (like old v_edges)
    my @down = @{$auxlist->[$aux]};
    my $bone = [(1 + @down),  $aux, @down];
    Net::OnlineCode::Bones->bless($bone);
    $self->{top}->[$aux-$mblocks] = $bone;

    # The links fan out at the bottom end
    for my $msg (@down) {
      $self->{bottom}->[$msg]->{$aux} = $bone;
    }

    # Set count of unknown down edges
    push @{$self->{unknowns}}, scalar(@down);
  }

  if (DEBUG) {
    print "Auxiliary mapping expressed as bones:\n";
    for my $aux (0 .. $ablocks - 1) {
      print "  " . ($self->{top}->[$aux]->pp()) . "\n";
    }
  }

  # set up edge counts for aux blocks
  for my $i (0 .. $ablocks - 1) {
    my $count = scalar(@{$auxlist->[$mblocks + $i]});
    push @{$self->{edge_count}}, $count;
    print "Set edge_count for aux block $i to $count\n" if DEBUG;
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




# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

# Decoder object creates a check block and we store it in the graph
# here

sub add_check_block {
  my $self = shift;
  my $nodelist = shift;
  my $mblocks = $self->{mblocks};

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  my $node = $self->{nodes}++;

  # set up new array elements
  push @{$self->{xor_list}}, [$node];
  $self->mark_as_solved($node);
  push @{$self->{v_edges}}, [];

  my $solved = 0;		# just used for debug output
  my @solved = ();		# ditto
  my $unsolved_count = 0;

  # Bones version handles edges and xor list in one list.
  # The constructor also tests whether elements are solved/unsolved
  my $bone = Net::OnlineCode::Bones->new($self, $node, $nodelist);
  die "add_check_block: failed to create bone\n" unless ref($bone);

  $self->{unknowns}->[$node-$mblocks] = $bone->unknowns;
  $self->{top}->     [$node-$mblocks] = $bone;

  print "Created new bone: " . $bone->pp . "\n";

  # Old version sets up v_edges, xor_list, solved and unsolved_count

  # set up graph edges and/or xor list
  foreach my $i (@$nodelist) {
    if ($self->{solution}->[$i]) {
      ++$solved;
      push @solved, $i;
      # solved, so add node $i to our xor list
      push @{$self->{xor_list}->[$node]}, $i;
      
    } else {
      # unsolved, so add edge to $i
      $self->add_edge($node,$i);
      ++$unsolved_count;
    }
  }
  
  print "Set edge_count for check block $node to $unsolved_count\n" 
    if DEBUG;
  push @{$self->{edge_count}}, $unsolved_count;

  # TODO: also expand any aux blocks and create separate edges
  # pointing directly to message blocks

  if (DEBUG) {
    print "New check block $node: " . (join " ", @$nodelist) . "\n";
  }

  # mark node as pending resolution
  push @{$self->{unresolved}}, $node;

  # return index of newly created node
  return $node;

}

# Graph resolution. Resolution of the graph has a "downward" part
# (resolve()) where nodes with one unsolved edge solve a message or
# aux block, and an upward part (cascade()) that works up from a
# newly-solved node.


# an unsolved aux block can be solved if it has no unsolved neighbours
sub aux_rule {
  my ($self, $from, $solved) = @_;

  if (DEBUG) {
    print "Solving aux block $from based on aux rule\n";
    print "XORing expansion of these solved message blocks: " . 
      (join " ", @$solved) . "\n";
  }

  $self->mark_as_solved($from);

  push @{$self->{xor_list}->[$from]}, @$solved;
  for my $to (@$solved) {
    # don't call delete_edge: unsolved counts would be wrong
    delete $self->{n_edges}->[$to]->{$from};
  }
  $self->{v_edges}->[$from - $self->{mblocks}] = [];
}


# Work up from a newly-solved message or auxiliary block

sub cascade {
  my ($self,$node) = @_;

  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};
  my $pending = $self->{unresolved};

  my @higher_nodes = keys %{$self->{n_edges}->[$node]};

  if (DEBUG) {
    if (@higher_nodes) {
      print "Solved node $node cascades to nodes " . (join " ", @higher_nodes)
	. "\n\n";
    } else {
      print "Solved node $node has no cascade\n\n";
    }
  }

  # update the count of unsolved edges.
  for my $to (@higher_nodes) {
    print "Decrementing edge_count for block $to\n" if DEBUG;
    ($self->{edge_count}->[$to - $mblocks])--;
  }
  push @$pending, @higher_nodes;

}

# helper function to delete (solved) edges from a solved node and
# optionally free the XOR list
sub decommission_node {

  my ($self, $node, $solved_list) = @_;

  foreach (@$solved_list) { 
    print "Deleting n edge from $_ up to $node\n" if DEBUG;
    delete $self->{n_edges}->[$_]->{$node};
  }
  $self->{v_edges}->[$node - $self->{mblocks}] = [];

  # we can free XOR list only if this is a check block
  if ($node >= $self->{coblocks}) {
    $self->{xor_list}->[$node] = undef;
  }

}

# Work down from a check or auxiliary block
sub resolve_old {

  # now doesn't take any arguments (uses unresolved queue instead)
  my ($self, @junk) = @_;

  if (ASSERT and scalar(@junk)) {
    die "resolve doesn't take arguments\n";
  }

  my $pending = $self->{unresolved};

  # Indicate to caller that our queue is empty and they need to add
  # another check block (see example code at top of Decoder man page)
  unless (@$pending) {
    return ($self->{done});
  }

  my $start_node = $pending->[0];

  if (ASSERT and $start_node < $self->{mblocks}) {
    croak ref($self) . "->resolve: start node '$start_node' is a message block!\n";
  }

  my @newly_solved = ();
  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};

  # exit if all message blocks are already solved
  unless ($self->{unsolved_count}) {
    $self->{done}=1;
    return (1);
  }

  while (@$pending) {

    my ($from, $to) = (shift @$pending);

    unless ($self->is_auxiliary($from) or $self->{solution}->[$from]) {
      print "skipping unproductive node $from\n" if DEBUG;
      next;
    }

    my @solved_nodes = ();
    my @unsolved_nodes;
    my $count_unsolved = $self->{edge_count}->[$from - $mblocks];

    if (DEBUG and $self->{xor_list}->[$from]) {
      print "\nStarting resolve at $from; XOR list is " . 
	(join ", ", @{$self->{xor_list}->[$from]}) . "\n";
    }

    next unless $count_unsolved < 2;

    my @lower_nodes = @{$self->{v_edges}->[$from-$mblocks]};

    print "Node links to $count_unsolved unsolved nodes\n" if DEBUG;

    if ($count_unsolved == 0) {

      if ($self->is_check($from) or $self->{solution}->[$from]) {

	# This node can't solve anything else: decommission it

	$self->decommission_node($from, \@lower_nodes);
	next;

      }

      # Otherwise it's an unsolved aux node: solve it with aux rule
      $self->aux_rule($from, \@lower_nodes);

      print "Aux rule solved auxiliary block $from completely\n" if DEBUG;

      push @newly_solved, $from;
      $self->cascade($from);

    } elsif ($count_unsolved == 1) {

      next unless $self->{solution}->[$from];

      # Propagation rule matched; separate solved from unsolved

      # TODO: this whole section (up to "Update global structure") can
      # be rewritten to only scan @lower_nodes list once
      for my $i (@lower_nodes) {
	if ($self->{solution}->[$i]) {
	  push @solved_nodes, $i;
	} else {
	  $to = $i; 
	}
      }

      print "Node $from solves node $to\n" if DEBUG;

      $self->mark_as_solved($to);
      push @newly_solved, $to;

      # create XOR list for the newly-solved node, comprising this
      # node's XOR list plus all nodes in the @solved array


      $self->delete_up_edge($from,$to);
      $self->{xor_list}->[$to] = [ @{$self->{xor_list}->[$from]},
				   @solved_nodes ];

      if (DEBUG) {
	print "Node $from (from) has XOR list: " . 
	  (join ", ", @{$self->{xor_list}->[$from]}) . "\n";
	print "Node $to (to) has XOR list: " .
	  (join ", ", @{$self->{xor_list}->[$to]}) . "\n";
      }


      $self->decommission_node($from, \@solved_nodes);

      # Update global structure and decide if we're done
      if ($to < $mblocks) {
	print "Solved message block $to completely\n" if DEBUG;
	unless (--($self->{unsolved_count})) {
	  $self->{done} = 1;
	  # comment out next two lines to continue decoding just in
	  # case there's a bug later
	  @$pending = ();
	  last;			# finish searching
	}
      } else {
	print "Solved auxiliary block $to completely\n" if DEBUG;
	push @$pending, $to;
      }

      # Cascade to potentially find more solvable blocks
      $self->cascade($to);

    }

    return ($self->{done}, @newly_solved)
      if (@newly_solved and STEPPING)
  }

  return ($self->{done}, @newly_solved);

}

sub resolve {

  my ($self, @junk) = @_;

  if (ASSERT and scalar(@junk)) {
    die "resolve doesn't take arguments\n";
  }

  my $pending = $self->{unresolved};
  unless (@$pending) {
    return ($self->{done});
  }

  my $start_node = $pending->[0];
  if (ASSERT and $start_node < $self->{mblocks}) {
    croak ref($self) . "->resolve: start node '$start_node' is a message block!\n";
  }

  my @newly_solved = ();
  my $mblocks  = $self->{mblocks};
  my $ablocks  = $self->{ablocks};
  my $coblocks = $self->{coblocks};

  unless ($self->{unsolved_count}) {
    $self->{done}=1;
    return (1);
  }

  while (@$pending) {

    my ($from, $toindex, $to) = (shift @$pending);

    my @solved_nodes = ();
    my @unsolved_nodes;
    my $bone =  $self->{top}->[$from - $mblocks];
    my $unknowns = $self->{unknowns}->[$from - $mblocks];

    if (DEBUG) {
      print "\nStarting resolve at $from: " . $bone->pp . "\n";
    }

    next unless $unknowns == 1;

    # Propagation rule matched (one unknown down edge)

    # There are two cases to consider:
    #
    # * this is an unsolved aux block (we propagate, but end up with
    #   two unknowns in the bone)
    #
    # * this is a check block or a solved aux block (there will be a
    #   single unknown and we can cascade)

    # We can between distinguish the two cases based on whether this
    # node is solved:

    my $solved = $self->{solution}->[$from];

    # We may need to add to the list of nodes that we need to
    # cascade up from:
    my @cascades = ();
    my @upper    = ();		# upper nodes for first cascade

    if (DEBUG) {
      my ($type, $status) = ("check", "unsolved");
      $type   = "auxiliary" if $from < $coblocks;
      $status = "solved"    if $solved;

      # We don't know the 'to' node yet; just print what we do know
      print "Propagating from $status $type node $from to ";
    }

    # pull out the unknown node
    if ($solved) {
      $to = $bone->one_unknown($self);
    } else {
      $to = $bone->two_unknowns($self);
      die "Second unknown was not this aux block\n" 
	  unless ASSERT and $bone->[2] == $from;
    }

    if (DEBUG) {
      my ($type, $status) = ("auxiliary", "unsolved");
      $type   = "message" if $to < $mblocks;
      $status = "solved"  if $self->{solution}->[$to];

      # Now we know the 'to' node:
      print "$status $type node $to\n";
    }

    # delete reciprocal links for all known edges
    my ($min, $max) = $bone->knowns_range;
    for ($min .. $max) {
      delete $self->{bottom}->[$bone->[$_]]->{$from};
    }

    # Different logic for two cases
    if ($solved) {

      # mark child node as solved
      $self->{solution}->[$to] = $bone;
      push @newly_solved, $bone;

      # Remember which nodes to cascade to
      @upper = keys %{$self->{bottom}->[$to]};

      if (DEBUG) {
	if (@upper > 1) {
	  print "Solved node $to cascades to nodes " . 
	    (join " ", @upper) . "\n";
	} else {
	  print "Solved node $to has no cascade\n";
	}
      }

      # We might be solving an unsolved aux node that has already had
      # the propagation rule applied, or be solving a message node
      # that has such an aux block as a parent. I'll handle both cases
      # here.

      if ($to >= $mblocks) {

	my $lower_bone = $self->{top}->[$to - $mblocks];
	if ($lower_bone->unknowns == 2) {
	
	  # previous propagation rule put unknowns in msg, aux order
	  my $lower_msg = $lower_bone->[1];
	  $lower_bone->[0] = 1;
	  $self->{solution}->[$lower_msg] = $lower_bone;

	  print "Extra cascade from message $lower_msg\n" if DEBUG;
	  push @newly_solved, $lower_bone;
	  delete $self->{bottom}->[$lower_msg]->{$to};
	  push @cascades, $lower_msg;

	  if ($to < $mblocks) {
	    print "Solved message block $to completely\n" if DEBUG;
	    unless (--($self->{unsolved_count})) {
	      $self->{done} = 1;
	      # comment out next two lines to continue decoding just in
	      # case there's a bug later
	      @$pending = ();
	      last;                 # finish searching
	    }
	  }

	} else {
	  # If the aux node didn't already trigger propagation rule,
	  # then maybe it will now?
	  push @$pending, $to;	# ???
	}

      } else {

	if ($to < $mblocks) {
	  print "Solved message block $to completely\n" if DEBUG;
	  unless (--($self->{unsolved_count})) {
	    $self->{done} = 1;
	    # comment out next two lines to continue decoding just in
	    # case there's a bug later
	    @$pending = ();
	    last;                 # finish searching
	  }
	}

	# We already found the parent nodes of this message node;
	# check if any of them is an unsolved aux node that's we've
	# already applied the propagation rule to (we may get multiple
	# hits)

	for (@upper) {
	  next if $_ >= $coblocks or $self->{solution}->[$_];

	  my $lower_bone = $self->{bottom}->[$to]->{$_}; 
	  next unless $lower_bone->unknowns == 2;

	  # Message node $to solves the aux node $_

	  # Fix up order (aux, msg) and unsolved count (1)
	  @{$lower_bone}[0..2] = (1, $_, $to);

	  print "Extra cascade from aux $_\n" if DEBUG;

	  $self->{solution}->[$_] = $lower_bone;
	  delete $self->{bottom}->[$to]->{$_};
	  push @newly_solved, $lower_bone;
	  push @cascades, $_;

	}
      }
      
    } else {


      # 

    }

    


    # Do all the pending cascades to higher nodes
    do {
      foreach (@upper) {
	push @$pending, $_;
	die "Unknown edge count for node $_ went negative\n"
	  if ASSERT and 0 == ($self->{unknowns}->[$_ - $mblocks])--;
      }

      @upper = ();
      if (@cascades) {
	$to = shift @cascades;
	@upper = keys %{$self->{bottom}->[$to]};
      }
    } while (@upper);

    return ($self->{done}, @newly_solved)
      if (@newly_solved and STEPPING)
  }

  return ($self->{done}, @newly_solved);


}


1;

__END__

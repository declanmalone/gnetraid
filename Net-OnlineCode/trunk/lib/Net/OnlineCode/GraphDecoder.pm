package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use vars qw($VERSION);

$VERSION = '0.02';

use constant DEBUG => 0;
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
# "higher-level" constructs.

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
     # expand_aux => $expand_aux,
     neighbours     => undef,	# will only store aux block mappings
     edges          => [],	# stores both check, aux block mappings
     solved         => [],
     unsolved_count => $mblocks,
     nodes          => $mblocks + $ablocks, # running count
     # xor_hash       => [],    # replaced by xor_list below
     xor_list       => [],
     iter           => 0,	# debug use
     unresolved     => [],      # queue of nodes needing resolution
     done           => 0,       # all message nodes decoded?
    };

  # work already done in auxiliary_mapping in Decoder
  $self->{neighbours} = $auxlist;

  bless $self, $class;

  # update internal structures
  for my $i (0..$mblocks + $ablocks - 1) {
    # mark blocks as unsolved, and having no XOR expansion
    $self->mark_as_unsolved($i);
    # $self->{xor_hash} ->[$i] = {};
    $self->{xor_list} ->[$i] = [];
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




# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

# Decoder object creates a check block and we store it in the graph
# here

sub add_check_block {
  my $self = shift;
  my $nodelist = shift;

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  # The original code that I was using here would create a new entry
  # in the graph structure regardless of whether the check block
  # actually added any new information or not. Later, I modified this
  # to only add checkblocks that add new info to the graph.
  # Unfortunately, that led to a (fairly trivial) bug in my codec code
  # where it failed to check the return value of
  # Decoder->accept_check_block and got confused about its check block
  # array.
  #
  # Given the choice of making more work for the calling program (and
  # making them more error-prone) and using slightly more memory, I've
  # decided that the latter option is best. So this routine will now
  # revert to the original method and always add a check block,
  # regardless of whether it adds more information or not.


  my $node = $self->{nodes}++;

  # set up new array elements
  #push @{$self->{xor_hash}}, { $node => undef };
  push @{$self->{xor_list}}, [$node];
  $self->mark_as_solved($node);
  push @{$self->{edges}}, {};

  my $solved = 0;		# just used for debug output
  my @solved = ();		# ditto

  # set up graph edges and/or xor list
  foreach my $i (@$nodelist) {
    if ($self->{solved}->[$i]) {
      ++$solved;
      push @solved, $i;
      # solved, so add node $i to our xor list
      #$self->{xor_hash}->[$node]->{$i} = undef;
      push @{$self->{xor_list}->[$node]}, $i;
      
    } else {
      # unsolved, so add edge to $i
      $self->add_edge($node,$i);
    }
  }

  if (DEBUG) {
    print "New check block $node: " . (join " ", @$nodelist) . "\n";
    print "of which, there are $solved solved node(s): " . 
      (join " ", @solved) . "\n";
  }

  # mark node as pending resolution
  push @{$self->{unresolved}}, $node;

  # return index of newly created node
  return $node;

}

# resolve graph

# Helper function called when a solved node has one unsolved neighbour
sub propagation_rule {
  my ($self, $from, $to, $solved) = @_;

  
}

# an unsolved aux block can be solved if it has no unsolved neighbours
sub aux_rule {
  my ($self, $from, $solved) = @_;

  if ($self->{solved}->[$from]) {
    # was previously solved (by propagation rule), so we don't need to
    # solve again. Delete the graph edges

    map { $self->delete_edge($from, $_) } @$solved;
    return undef;
  } else {
    # otherwise solve it here by expanding message blocks' xor lists
    if (DEBUG) {
      print "Solving aux block $from based on aux rule\n";
      print "XORing expansion of these solved message blocks: " . 
	(join " ", @$solved) . "\n";
    }

    $self->mark_as_solved($from);
    
    push @{$self->{xor_list}->[$from]}, @$solved;
    for my $to (@$solved) {
      # don't do expansion; it takes up too much memory
      #my @expanded = @{$self->{xor_list}->[$to]};
      #push @{$self->{xor_list}->[$from]}, @expanded;
      #if (DEBUG) {
      #	print "Expansion: $to -> " . (join " ", @expanded) . "\n";
      #}
      $self->delete_edge($from,$to);
    }
    return $from;		# newly solved
  }
}


sub resolve {

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

    unless ($self->is_auxiliary($from) or $self->{solved}->[$from]) {
      print "skipping unproductive node $from\n" if DEBUG;
      next;
    }

    my @solved_nodes = ();
    my @unsolved_nodes;
    my $count_unsolved = 0;	# size of above array

    if (DEBUG) {
      print "XOR list for $from is " . 
	(join ", ", @{$self->{xor_list}->[$from]}) . "\n";
    }

    my @lower_nodes = grep { $_ < $from } $self->edge_list($from);

    foreach $to (@lower_nodes) {
      if ($self->{solved}->[$to]) {
	push @solved_nodes, $to;
      } else {
	push @unsolved_nodes, $to;
	++$count_unsolved;
      }
    }

#    print "\nStarting node: $from has lower nodes: " . (join " ", @lower_nodes) . "\n"
#      if DEBUG;

    print "Unsolved lower degree: $count_unsolved\n" if DEBUG;


    if ($count_unsolved == 0) {


      if ($self->is_check($from)) {

	next;			# we could free this node's memory
                                # here if we wanted
      } else {

	my $newly_solved = $self->aux_rule($from, \@solved_nodes);
	
	if (defined($newly_solved)) {
	  print "Aux rule solved auxiliary block $from completely\n" if DEBUG;

	  push @newly_solved, $newly_solved;

	  # Cascade to potentially find more solvable blocks

	  # queue up check blocks
	  my @higher_nodes = grep { $_ > $from } $self->edge_list($from);

	  if (@higher_nodes) {
	    print "Solved node $from still has higher nodes " . (join " ", @higher_nodes)
	      . "\n\n" if DEBUG;
	  } else {
	    print "Solved node $from has no higher nodes (no cascade)\n\n" if DEBUG;
	  }

	  push @$pending, @higher_nodes;
	}
      }

    }

    if ($count_unsolved == 1) {

      next unless $self->{solved}->[$from];

      push @solved_nodes, @{$self->{xor_list}->[$from]}; 

      # Propagation rule matched
      $to = shift @unsolved_nodes;

      print "Node $from solves node $to\n" if DEBUG;

      $self->mark_as_solved($to);
      push @newly_solved, $to;

      # create XOR list for the newly-solved node

      if (DEBUG) {
	print "Node $from has XOR list: " . 
	  (join ", ", @{$self->{xor_list}->[$from]}) . "\n";
      }
						   
      $self->delete_edge($from,$to);

      foreach my $i (@solved_nodes) {
	
	print "=> Adding $i to ${to}'s XOR list\n" if DEBUG;

	if (0 and $self->is_message($i)) { # don't expand message nodes any more
	  my @expanded = @{$self->{xor_list}->[$i]};
	  if (DEBUG) {
	    print "Expansion: $i -> " . (join " ", @expanded) . "\n";
	  }
	  push @{$self->{xor_list}->[$to]}, @expanded;
	} else {
	  #$self->toggle_xor($to,$i);
	  push @{$self->{xor_list}->[$to]}, $i;
	}
	$self->delete_edge($from,$i);

      }

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
      my @higher_nodes = grep { $_ > $to } $self->edge_list($to);


      # if this is a checkblock, free space reserved for xor_hash
      if ($from > $mblocks + $ablocks) {
	#$self->free_xor_hash($from);
      }

      if (@higher_nodes) {
	print "Solved node $to still has higher nodes " . (join " ", @higher_nodes)
	  . "\n\n" if DEBUG;
      } else {
	print "Solved node $to has no higher nodes (no cascade)\n\n" if DEBUG;
      }

      push @$pending, @higher_nodes;

    }



  }

  return ($self->{done}, @newly_solved);

}


1;

__END__

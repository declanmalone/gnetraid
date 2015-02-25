package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use vars qw($VERSION);

$VERSION = '0.03';

use constant DEBUG => 0;
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

     # Edges will be replaced again, this time with "bones", which are
     # a combination of old v_edges and xor_lists. The top and bottom
     # structures store links to the bones objects.
     top            => [],	# from aux/check
     bottom         => [],	# to message/aux
     solution       => [],      # message/aux; will be a bone

     # how many unknown down edges does a node have?
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
    push @{$self->{bottom}}, {}; # hash, like n_edges
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
    print "Set unknowns count for aux block $aux to ".
      ($bone->unknowns - 1) . "\n" if DEBUG;
    push @{$self->{unknowns}}, $bone->unknowns - 1;

  }

  if (DEBUG) {
    print "Auxiliary mapping expressed as bones:\n";
    for my $aux (0 .. $ablocks - 1) {
      print "  " . ($self->{top}->[$aux]->pp()) . "\n";
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
  my $mblocks = $self->{mblocks};

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  my $node = $self->{nodes}++;

  # set up new array elements
  $self->mark_as_solved($node);

  # Bones version handles edges and xor list in one list.
  # The constructor also tests whether elements are solved/unsolved
  my $bone = Net::OnlineCode::Bones->new($self, $node, $nodelist);
  die "add_check_block: failed to create bone\n" unless ref($bone);

  $self->{unknowns}->[$node-$mblocks] = $bone->unknowns;
  $self->{top}->     [$node-$mblocks] = $bone;

  print "Set unknowns count for check block $node to " .
    ($bone->unknowns) . " \n" if DEBUG;

  if (DEBUG) {
    print "New check block $node: " . ($bone->pp) . "\n";
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

# helper function
sub apply_solution {

  my ($self, $node, $bone);



}

# Work up from a newly-solved block, potentially doing up-propagation
# rule
sub cascade {
  my ($self,$node,$newly_solved) = @_;

  my $mblocks = $self->{mblocks};
  my $ablocks = $self->{ablocks};
  my $coblocks = $mblocks + $ablocks;
  my $pending = $self->{unresolved};

  die "Cascade needs a solved array"
    if ASSERT and ref($newly_solved) ne 'ARRAY';

  my @upper = keys %{$self->{bottom}->[$node]};

  if (DEBUG) {
    if (@upper) {
      print "Solved node $node cascades to nodes " . (join " ", @upper)
	. "\n\n";
    } else {
      print "Solved node $node has no cascade\n\n";
    }
  }

  # update the count of unsolved edges and maybe solve aux blocks
  for my $to (@upper) {
    print "Decrementing unknowns count for block $to\n" if DEBUG;
    my $old_count = ($self->{unknowns}->[$to - $mblocks])--;

    # apply upward propagation rule on unsolved aux block?
    if ($old_count == 1 and $to < $coblocks 
	and !$self->{solution}->[$to]) {

      my $bone = $self->{top}->[$to - $mblocks];
      $self->{$node}->[$to - $mblocks] = undef;

      die "Aux node didn't have $node as an unsolved\n"
	if ($to != $bone->one_unknown($to));
      print "Marking block $to as solved\n" if DEBUG;
      $self->{solution}->[$to] = $bone;

      my ($min, $max) = $bone->knowns_range;
      for ($min .. $max) {
	delete $self->{bottom}->[$_]->{$to};
      }
	  
      push @$newly_solved, $bone;

    } else {
      push @$pending, $to;
    }
  }
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
      print "\nStarting resolve at $from: " . $bone->pp .
	" ($unknowns unknowns)\n";
    }

    next unless $unknowns == 1;

    # Propagation rule matched (one unknown down edge)

    # resolve() only solves a node if the upper node itself is solved.
    # cascade() will handle the case of solving an unsolved aux block
    # by solving its last unsolved message block (upward propagation)

    my $solved = $self->{solution}->[$from];

    my @upper    = ();

    if (DEBUG) {
      my ($type, $status) = ("check", "unsolved");
      $type   = "auxiliary" if $from < $coblocks;
      $status = "solved"    if $solved;

      # We don't know the 'to' node yet; just print what we do know
      print "Propagating from $status $type node $from\n";
    }

    # pull out the unknown node
    if ($solved) {
      $to = $bone->one_unknown($self);
    }

    if ($from < $coblocks and !$solved) {
      print "Skipping down propagation rule on unsolved aux\n" if DEBUG;
      next;

    } elsif (DEBUG) {

      my ($type, $status) = ("auxiliary", "an unsolved");
      $type   = "message" if $to < $mblocks;
      $status = "a solved"  if $self->{solution}->[$to];

      # Now we know the 'to' node:
      print "To node $to is $status $type node.\n";
    }

    # delete reciprocal links for all known edges
    my ($min, $max) = $bone->knowns_range;
    for ($min .. $max) {
      delete $self->{bottom}->[$bone->[$_]]->{$from};
    }

    # mark child node as solved
    print "Marking block $to as solved\n" if DEBUG;
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

    if ($to < $mblocks) {
      print "Solved message block $to completely\n" if DEBUG;
      unless (--($self->{unsolved_count})) {
	$self->{done} = 1;
	# comment out next two lines to continue decoding just in
	# case there's a bug later
	@$pending = ();
	last;                 # finish searching
      }
    } else {
      print "Solved auxiliary block $to completely\n" if DEBUG;
      push @$pending, $to;
    }
    cascade($self, $to, \@newly_solved);

    return ($self->{done}, @newly_solved)
      if (@newly_solved and STEPPING)
  }

  return ($self->{done}, @newly_solved);


}


1;

__END__

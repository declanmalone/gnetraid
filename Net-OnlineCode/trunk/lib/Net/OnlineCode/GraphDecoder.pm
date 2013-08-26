package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use constant DEBUG => 0;

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

  unless (@$auxlist ==$ablocks) {
    carp "$class->new: auxlist does not have $ablocks entries\n";
    return undef;
  }

  $expand_aux = 1 unless defined($expand_aux);

  my $self =
    {
     mblocks    => $mblocks,
     ablocks    => $ablocks,
     coblocks   => $mblocks + $ablocks, # "composite"
     expand_aux => $expand_aux,
     neighbours     => [],
     solved         => [],
     unsolved_count => $mblocks,
     xor_hash       => [],
    };

  # set up nodes, edges
  for (1..$mblocks) {
    push $self->{neighbours}, []; # message blocks
  }
  my $aux = $mblocks;		  # first aux node

  for my $msg_list (@$auxlist) {
    unless (ref($msg_list) eq "ARRAY") {
      carp "$class->new: argument 3 not a list of lists!\n";
      return undef;
    }

    $self->{neighbours}->[$aux] = [];
    for my $msg (@$msg_list) {
      # warn "linking aux block $aux to message $msg\n";
      if ($msg >= $mblocks) {
	carp "$class->new: Auxiliary block link '$msg' out of range\n";
	return undef;
      }
      push $self->{neighbours}->[$aux], $msg;
      push $self->{neighbours}->[$msg], $aux; # msg block -> aux block
    }
    ++$aux;
  }

  # mark all message and auxiliary blocks as unsolved and not xored
  for my $i (0..$mblocks + $ablocks - 1) {
    $self->{solved}   ->[$i] = 0;
    $self->{xor_hash} ->[$i] = {};
  }

  bless $self, $class;
}


# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

sub add_check_block {
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

sub resolve {

  my $self = shift;
  my $node = shift;		# start node

  if ($node < $self->{coblocks}) {
    croak ref($self) . "->resolve: node '$node' is not a check block!\n";
  }

  my $finished = 0;
  my @newly_solved = ();
  my @pending = ($node);

  return (1) unless $self->{unsolved_count};

  while (@pending) {

    my $start  = shift @pending;
    my $solved = undef;		# we can solve at most one unknown per
                                # iteration

    print "Resolving node $start\n" if DEBUG;

    # check for unsolved lower neighbours
    my @unsolved = grep { $_ < $start and !$self->{solved}->[$_]
		     } @{$self->{neighbours}->[$start]};

    # if we have exactly one unsolved lower neighbour then we can
    # solve that node
    if (@unsolved == 1) {

      $solved = shift @unsolved; # newly solved
      my @solved = grep {	 # previously solved
	$_ < $start and $_ != $solved
      } @{$self->{neighbours}->[$start]};

      print "Start node $start can solve node $solved\n";

      # If I was doing the XORs here directly, I'd just XOR each
      # previously solved neighbour into the start node and store the
      # result in the newly-solved node. Since I'm deferring XORs, I
      # have to associate a list of blocks that each /message node/
      # needs to be xor'd with instead. Also, since the caller can
      # choose to do the XORs in a random order and they might forget
      # or choose not to XOR auxiliary blocks first, I include the
      # expansion of each auxiliary block instead of just its block
      # number.

      # Note that by expanding each block's derivation in terms only
      # of check blocks, the decoder does not need to allocate any
      # space for storing auxiliary blocks. It does generally require
      # more XORs, though.

      # The solution to the newly solved message or auxiliary block is
      # the XOR of the start node (or its expansion) and the expansion
      # of all the start node's previously solved neighbours
      if ($self->is_check($start)) {
	print "toggling check node $start into $solved\n" if DEBUG;
	$self->toggle_xor($solved,$start);
      } elsif ($self->is_auxiliary($start)) {
	# for auxiliary blocks, we must make sure that it is actually
	# solved before using it to solve component blocks.
	next unless $self->{solved}->[$solved];

	if ($self->{expand_aux}) {
	  my $href= $self->{xor_hash}->[$start];
	  $self->merge_xor_hash($solved, $href);
	} else {
	  croak "resolve: expand_aux of 0 not implemented yet\n";
	  # should be as simple as:
	  # $self->toggle_xor($solved,$start)
	}
      } else {
	croak "resolve: BUG! solved a block at the same level\n";
      }
      for my $i (@solved) {
	my $href= $self->{xor_hash}->[$i];
	$self->merge_xor_hash($solved, $href);
      }

      $self->{solved}->[$solved] = 1;
      push @newly_solved, $solved;

      if ($self->is_message($solved)) {
	unless (--($self->{unsolved_count})) {
	  $finished = 1;
	  @pending = ();	# no need to search any more nodes
	}
      }

      unless ($finished) {
	# queue up the newly solved node and all its higher neighbouring nodes
	push @pending, $solved unless $self->is_message($solved);
	push @pending, grep { $_ > $solved } @{$self->{neighbours}->[$solved]};
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

  if (exists($self->{xor_hash}->[$solved]->{$i})) {
    delete $self->{xor_hash}->[$solved]->{$i};
    #warn "Key $i unset\n";
  } else {
    $self->{xor_hash}->[$solved]->{$i} = 1;
    #warn "Key $i set\n";
  }
}

# toggle all keys from a hashref into a solved node
sub merge_xor_hash {
  my ($self, $solved, $href) = @_;

  unless (ref($href) eq 'HASH') {
    carp "merge_xor_hash: need a hashref as second argument\n";
    return;
  }

  print "expanded terms: " . (join ",", keys %$href) . "\n" if DEBUG;
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

# return the keys of xor_hash as a list
sub xor_list {
  my ($self,$i) = @_;
  croak "xor_list requires a numeric argument (message block index)\n" 
    unless defined($i);
  return keys ($self->{xor_hash}->[$i]);
}

1;

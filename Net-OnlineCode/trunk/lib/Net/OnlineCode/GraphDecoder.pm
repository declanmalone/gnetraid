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

  print "graph: expand_aux => $expand_aux\n";

  my $self =
    {
     mblocks    => $mblocks,
     ablocks    => $ablocks,
     coblocks   => $mblocks + $ablocks, # "composite"
     expand_aux => $expand_aux,
     neighbours     => undef,
     solved         => [],
     unsolved_count => $mblocks,
     xor_hash       => [],
    };

  # work already done in auxiliary_mapping in Decoder
  $self->{neighbours} = $auxlist;

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

      # previously solved message blocks
      my @solved = grep { $_ < $start } @{$self->{neighbours}->[$start]};

      for my $i (@solved) {
	my $href= $self->{xor_hash}->[$i];
	$self->merge_xor_hash($start, $href);
      }

      $self->{solved}->[$start] = 1;

      if (0) {
	# queue *everything* to debug this part
	@pending = (0..@{$self->{neighbours}});
      } else {
	push @pending, grep { $_ > $start } @{$self->{neighbours}->[$start]};
      }

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

      } elsif ($solved < $mblocks + $ablocks) {

	next;
	next unless $self->{solved}->[$start];

        for my $i (@solved, $start) {
	  my $href= $self->{xor_hash}->[$i];
	  $self->merge_xor_hash($solved, $href);
	}

      } else {
	croak "resolve: BUG! check $start can't solve checkblocks\n";
      }

      $self->{solved}->[$solved] = 1;
      push @newly_solved, $solved;

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

1;

__END__

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


package Net::OnlineCode::GraphDecoder;

use strict;
use warnings;

use Carp;

use vars qw($VERSION);

$VERSION = '0.02';

use constant DEBUG => 0;
use constant TRACE => 0;

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

  # update internal structures
  for my $i (0..$mblocks + $ablocks - 1) {
    # mark blocks as unsolved, and having no XOR expansion
    $self->{solved}   ->[$i] = 0;
    $self->{xor_hash} ->[$i] = {};

    # empty edge structure
    push @{$self->{edges}}, {}; # 5.14
  }

  # set up edge structure (same as neighbours, but using hashes)
  for my $i (0..$mblocks + $ablocks - 1) {
    for my $j (@{$auxlist->[$i]}) {
      $self->{edges}->[$i]->{$j} = undef;
      $self->{edges}->[$j]->{$i} = undef;
    }
  }

  bless $self, $class;
}

# use graphviz to figure what's going on/going wrong

sub dump_graph_panel {

  my $self = shift;
  my $panel = shift;		# name of the graph (also used as caption)
  my $current = shift;

  my $graph = "subgraph_cluster$panel";

  my ($mblocks,$ablocks,$edges) = @{$self}{"mblocks","ablocks","edges"};

  # do a bottom-up construction

  my ($chk,$aux,$msg) = ("", "", "");

  $chk = <<EOT;
subgraph cluster_check_$panel {
    label="chk";
    rankdir=LR;
    rank=same
//    rank=min;
EOT

  $aux = <<EOT;
subgraph cluster_aux_$panel {
    label="aux";
    rankdir=LR;
    rank=same
EOT

  $msg = <<EOT;
subgraph cluster_msg_$panel {
    label="msg";
    rankdir=LR;
    rank=same
EOT

    # nodes are described like:
    # $node [label="\N {@keys}" style=bold];
    #   $node  is the node number
    #   @keys  are the keys from xor_hash
    #   bold   if the node is marked as solved

  my $edgelist="";
  foreach my $i (0 .. scalar @{$self->{neighbours}} -1) {

    # don't graph deleted nodes
    next if $self->{deleted}->[$i];

    my $nodedesc = "${panel}_$i [label=\"$i {";
    $nodedesc .= join ",", sort { $a <=> $b } keys(%{$self->{xor_hash}->[$i]});
    $nodedesc .= "}\"";
    $nodedesc .= " color=green" if $self->{solved}->[$i];
    $nodedesc .= " style=filled" if $current == $i;
    $nodedesc .= "];";

    # add invisible links between nodes in this cluster to keep them
    # from being reordered
    unless ($i == 0 or $i == $mblocks or $i == $mblocks + $ablocks) {
      $nodedesc .= "\n    ${panel}_";
      $nodedesc .= $i-1 . " -- ${panel}_$i [style=invis]";
    }

    if ($i < $mblocks) {
      $msg .= "    $nodedesc\n";
    } elsif ($i < $mblocks + $ablocks) {
      $aux .= "    $nodedesc\n";
    } else {
      $chk .= "    $nodedesc\n";
    }

    # add invisible links between subgraphs
    #$edgelist .= "cluster_chk -- cluster_aux;\n";
    #$edgelist .= "cluster_aux -- cluster_msg;\n";

    my $href =$self->{edges}->[$i];
    foreach my $j (sort {$a<=>$b} keys %$href) {
      if ($j < $i) {
	die "graph edge ($j,$i) does not have reciprocal link!\n"
	  unless exists($self->{edges}->[$i]->{$j});
	next;
      }

      my $edgedesc = "${panel}_$i -- ${panel}_$j [dir=";
      if (exists($self->{edges}->[$j]->{$i})) {
	$edgedesc .= "both]";
      } else {
	$edgedesc .= "forward]";
      }

      #warn "adding edge description $edgedesc\n";
      $edgelist .= "  $edgedesc\n";
    }
  }

  my $subgraph =<<EOT;
subgraph cluster_$panel {

  ranksep = 2;
  rankdir=BT;
// rank=same;

  label="$panel";

  $chk  }

  $aux  }

  $msg  }

$edgelist}
EOT

  return $subgraph;
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
  my ($self, $target, $value, @junk) = @_;

  # updates target by xoring value into it

  croak "toggle_xor got extra junk parameter" if @junk;

  print "Toggling $value into $target\n" if DEBUG;

  # Profiling indicates that this is a very heavily-used sub, so a
  # simple change to avoid various object dereferences should help:
  my $href=$self->{xor_hash}->[$target];

  if (exists($href->{$value})) {
    delete $href->{$value};
  } else {
    $href->{$value} = undef;
  }
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
	push @queue, keys %{$self->{xor_hash}->[$block]}; # 5.14
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

# the decoding algorithm is divided into two steps. The first adds a
# new check block to the graph, while the second resolves the graph to
# discover newly solvable auxiliary or message blocks.

# new approach to graph: use explicit edge structure and remove them
# as we resolve the graph

sub add_check_block {
  my $self = shift;
  my $nodelist = shift;

  unless (ref($nodelist) eq "ARRAY") {
    croak ref($self) . "->add_check_block: nodelist should be a listref!\n";
  }

  # new node number for this check block
  my $node = $self->{nodes}++;

  # we'll check whether this new block provides any new information by
  # incrementing unsolved for each unsolved right neighbour
  my $unsolved = 0;
  foreach my $i (@$nodelist) {
    ++$unsolved unless $self->{solved}->[$i];
  }

  unless ($unsolved) {
    push @{$self->{edges}}, undef;
    push @{$self->{xor_hash}}, undef;
    return 0;
  }

  #warn "add_check_block: adding new node index $node\n";
  print "New check block $node: " . (join " ", @$nodelist) . "\n" if DEBUG;

  my $new_hash = {};		# new edge hash for this check block

  # it simplifies the algorithm if each check block is marked as
  # (trivially) being composed of only itself. (this way we don't have
  # to include separate cases for check and aux blocks)
  push @{$self->{xor_hash}}, { $node => undef}; # 5.14

  # also mark check block as solved (ie, value is known)
  $self->{solved}->[$node]=1;

  # store edges, reciprocal links
  foreach my $i (@$nodelist) {
    if ($self->{solved}->[$i]) {
      $self->merge_xor_hash($node,$self->{xor_hash}->[$i]);
    } else {
      $new_hash->{$i} = undef;
      $self->{edges}->[$i]->{$node} = undef;
    }
  }

  # store edges emanating from checkblock (hash form)
  push @{$self->{edges}}, $new_hash; # 5.14

  # return index of newly created node
  return $node;

}

sub delete_edge {

  my ($self,$from,$to) = @_;

  print "Deleting edge $from, $to\n" if DEBUG;

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
# right: when the left node has exactly one right neighbour

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

    my ($from, $to) = (shift @pending);

    my @right_nodes = grep { $_ < $from } keys %{$self->{edges}->[$from]}; # 5.14

    my $right_degree = scalar(@right_nodes);

    print "Starting node: $from has right nodes: " . (join " ", @right_nodes)
      . "\n" if DEBUG;

    unless ($self->{solved}->[$from]) {
      print "skipping unsolved from node $from\n" if DEBUG;
      next;
    }

    my $original;
    my $rule1="";
    my $rule2="";
    my $iter = $self->{iter};
    ++$iter;
    if (TRACE) {
      $original = $self->dump_graph_panel("original",$from);
    }

    my @merge_list =($from);
    while ($right_degree--) {
      my $to = shift @right_nodes;
      if ($self->{solved}->[$to]) {
	push @merge_list, $to;
      } else {
	push @right_nodes, $to;	# unsolved
      }
    }

    print "Unsolved right degree: " . scalar(@right_nodes) . "\n" if DEBUG;

    if (TRACE) {
      $rule1 = $self->dump_graph_panel("rule1",$from);
    }

    if (@right_nodes == 0) {

      # if this is a check block with no unsolved right nodes, free
      # any memory it uses
      next if $from < $mblocks + $ablocks;

      $self->{xor_hash}->[$node] = undef;
      foreach my $to (@merge_list) {
	$self->delete_edge($from,$to);
      }

    } elsif (@right_nodes == 1) {

      # we have found a node that matches the propagation rule
      $to = shift @right_nodes;

      print "Node $from solves node $to\n" if DEBUG;

      $self->delete_edge($from,$to);
      foreach my $i (@merge_list) {
	$self->merge_xor_hash($to, $self->{xor_hash}->[$i]);
	$self->delete_edge($from,$i);
      }

      # left nodes are to's left nodes
      my @left_nodes = grep { $_ > $to } keys %{$self->{edges}->[$to]}; # 5.14

      # mark node as solved
      $self->{solved}->[$to] = 1;
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
	$self->{xor_hash}->[$from] = undef;
      }

      if (@left_nodes) {
	print "Solved node $to still has left nodes " . (join " ", @left_nodes)
	  . "\n" if DEBUG;
      } else {
	print "Solved node $to has no left nodes\n" if DEBUG;
      }
      push @pending, @left_nodes;

      #@pending = sort { $b <=> $a } @pending;

#      for my $back (@left_nodes) {
#	$self->merge_xor_hash($back, $self->{xor_hash}->[$to]);
#	$self->delete_edge($back,$to);
#      }

    }


    if (TRACE) {
      $rule2=$self->dump_graph_panel("rule2",$from);
      my $filename = "dump-" . sprintf("%05d", $iter) . ".txt";
      die "File create? $!\n" unless open DUMP, ">", $filename;
      print DUMP "graph test {\n$original\n$rule1\n$rule2\n}\n";
      close DUMP;
      $self->{iter}=$iter;
    }

  }

  # do a pass over all check, aux blocks to make sure that they can't
  # solve more blocks
  if (0) {
    for my $i ($mblocks .. $self->{nodes} - 1) {

      next unless $self->{solved}->[$i];
      my @right    = grep { $_ < $i &&
			      !$self->{solved}->[$_] }
	keys %{$self->{edges}->[$i]};
      if (@right == 1) {
	my $from = shift @right;
	warn "algorithm failed to reach node $from that could be solved\n";
      }
    }
  }

  return ($finished, @newly_solved);

}


1;

__END__

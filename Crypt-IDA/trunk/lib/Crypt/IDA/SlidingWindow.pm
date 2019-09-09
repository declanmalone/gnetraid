package Crypt::IDA::SlidingWindow;

# Copyright (c) Declan Malone, 2019
#
# See LICENSE

use v5.20;

# Sliding Window algorithm to support cleaner IDA split/combine code

use Class::Tiny qw(bundle yts), {
    # our 5 pointers (not really meant to be passed to new)
    read_head => 0,		# first to be advanced
    read_tail => 0,		# } peri-
    processed => 0,		# } stal-
    write_head => 0,		# } sis 
    write_tail => 0,		# start of window; last to advance
    # substream pointers (could be on read end or write end)
    # bundle => set up in BUILD
    
    # required
    mode => undef,		# 'split' or 'combine'
    rows => undef,		# how many substreams in bundle?
    window => undef,

    # convenience
    splitting => sub { shift->{mode} eq 'split' ? 1 : 0 },
    combining => sub { shift->{mode} eq 'combine' ? 1 : 0 },

    # optional callbacks (not all combinations make sense)
    cb_error => undef,
    cb_read_bundle => undef,
    cb_wrote_bundle => undef,
    cb_processed => undef,
};

sub BUILD {
    my ($self, $args) = @_;
    for my $req ( qw(mode rows window) ) {
	die "$req attribute required" unless defined $self->$req;
    }
    die "Bad mode!" unless
	$self->mode eq 'split' or $self->mode eq 'combine';
    for my $plus ( qw(rows window) ) {
	die "$plus attribute must be > 0" unless $self->$plus > 0;
    }
    for my $zero ( qw(read_head read_tail processed write_head
                      write_tail) ) {
	die "Setting $zero attribute not allowed" unless $self->$zero == 0;
    }

    # Need to set up yts
    $self->{yts} = $self->{rows};

    # Couldn't set up bundle in Class::Tiny call
    my @bundle;
    for (1 .. $self->rows) {
	push @bundle, { head => 0, tail => 0 }
    }
    $self->{bundle} = \@bundle;
}

# 
sub _error {
    my ($self,@msg) = @_;
    my $cb = $self->{cb_error};
    return @msg unless defined $cb;
    $cb->(@msg);
    return undef;
}

# For clarity, I won't combine advance_read and advance_write into a
# single sub. This makes it easier to understand what's happening in
# _advance_rw_substream.

sub advance_read {
    my ($self,$cols) = @_;

    die "Use advance_read_substream instead" if $self->combining;
    my ($head,$tail) = ($self->read_head, $self->read_tail);

    # Note that read_head can be up to two windows ahead of
    # write_tail, but never more than one window from read_tail.
    die "Would exceed read window" if $head + $cols - $tail > $self->window;
    $self->{read_head} += $cols;
}

sub advance_write {
    my ($self,$cols) = @_;

    die "Use advance_write_substream instead" if $self->splitting;
    my ($head,$tail) = ($self->write_head, $self->write_tail);

    # Advance tail, but not past head.
    die "Write tail would overtake head" if $tail + $cols > $head;
    $self->{write_tail} += $cols;
}

# code for advancing read/write substreams is the same, apart from
# error messages, callbacks and overall pointer to possibly update
sub _advance_rw_substream;
sub advance_read_substream  { shift->_advance_rw_substream("read", @_) }
sub advance_write_substream { shift->_advance_rw_substream("write", @_)}


# Returns:
# * undef on error
# * 0 if OK and bundle pointer didn't advance
# * 1 if OK and bundle pointer did advance
sub _advance_rw_substream {
    my ($self,$which,$row,$cols) = @_;
    my ($ptr, $parent, $cb);
    if ($which eq "read") {
	die "No read substreams!" if $self->splitting;
	($ptr, $parent, $cb) = ("head", "read_head", "cb_read_bundle")
    } elsif ($which eq "write") {
	die "No write substreams!" if $self->combining;
	($ptr, $parent, $cb) = ("tail", "write_tail", "cb_wrote_bundle");
    } else {
	die "_advance_some_substream: $which?";
    }
    die "Row out of range" if $row >= $self->rows;

    my $hash    = $self->bundle->[$row];
    my $old_val = $hash->{$ptr};
    if ($which eq "read") {
	die "Read would overflow input buffer"
	    if $old_val + $cols - $hash->{tail} > $self->window;
    } else {
	die "Write tail would overtake head"
	    if $old_val + $cols > $hash->{head};
    }
    my $new_val = $hash->{$ptr} += $cols;

    # possibly advance parent pointer to new minimum
    return 0 unless $old_val == $self->{$parent};
    return 0 if --$self->{yts};

    my $new_yts = 1;
    for my $r (0 .. $self->{rows} - 1) {
	next if $r == $row;
	my $this_val = $self->{bundle}->[$r]->{$ptr};
	next if $this_val > $new_val;
	if ($this_val < $new_val) {
	    ($new_val, $new_yts) = ($this_val, 1);
	} else {
	    ++$new_yts;
	}
    }
    ($self->{$parent}, $self->{yts}) = ($new_val, $new_yts);
    $self->{$cb}->() if defined $self->{$cb};
    return 1;
}

# The names here reflect the names of the related I/O commands as used
# by the caller:
#
# * read_ok: how much should we read to fill input buffer?
# * process_ok: how much input can we process to produce output?
# * write_ok: how much should we write to empty output buffer?
# * bundle_ok: associated with read/write, depending on mode
#
# For multiple substreams, the parent read_ok/write_ok is the maximum
# of all the substream read_ok/write_ok values, so caller should use
# the substream read_ok/write_ok values to decide how much to
# read/write. The parent read_ok/write_ok values track when the bundle
# advances as a whole.
sub can_advance {
    my $self = shift;
    my ($read_ok, $process_ok, $write_ok, @bundle_ok);

    # reads fill and writes empty the buffers
    $read_ok  = $self->window - ($self->read_head - $self->read_tail);
    $write_ok = ($self->write_head - $self->write_tail);

    # processing limited by available input/free output space
    my $read_ready = $self->read_head - $self->read_tail;
    my $write_free = $self->window - $write_ok;
    $process_ok = $read_ready < $write_free ? $read_ready : $write_free;

    # bundled substreams (could be read or write)
    for my $row (0 .. $self->rows - 1) {
	my $rowptr = $self->{bundle}->[$row];
	push @bundle_ok, ($self->combining) ?
	    $self->window - ($rowptr->{head} - $rowptr->{tail}) :
	    $rowptr->{head} - $rowptr->{tail};
    }
    return ($read_ok,$process_ok,$write_ok,\@bundle_ok);
}

sub can_fill {
    my $self = shift;
    die "use can_fill_substream instead" if $self->combining;
    $self->window - ($self->read_head - $self->read_tail);
}

sub can_empty {
    my $self = shift;
    die "use can_empty_substream instead" if $self->splitting;
    $self->write_head - $self->write_tail;
}

sub can_fill_substream {
    my ($self,$row) = @_;
    die "must specify a row" unless defined $row;
    die "use can_fill instead" if $self->splitting;
    my $rowptr = $self->{bundle}->[$row];
    $self->window - ($rowptr->{head} - $rowptr->{tail})
}

sub can_empty_substream {
    my ($self,$row) = @_;
    die "must specify a row" unless defined $row;
    die "use can_empty instead" if $self->combining;
    my $rowptr = $self->{bundle}->[$row];
    $rowptr->{head} - $rowptr->{tail};
}    
    

# advance_process advances all the "middle" pointers (ie, everything
# except read_head and write_tail) in a single operation
sub advance_process {
    my ($self,$cols) = @_;

    die "Not enough data in input buffer"
	if $self->read_tail + $cols > $self->read_head;

    my $written    = ($self->write_head - $self->write_tail);
    my $write_free = $self->window - $written;
    die "Not enough space in output buffer" if $cols > $write_free;

    $self->{read_tail}  += $cols; # actually, all three can be
    $self->{processed}  += $cols; # handled with a single
    $self->{write_head} += $cols; # 'processed' pointer

    # Substreams could be on left/right, so different pointers get
    # advanced within them. Also implications for new "yet to start"?
    my ($new_yts,$new_val) = (0);
    if ($self->combining) {
	$new_val = $self->read_tail; 
	for my $r (0 .. $self->rows -1) {
	    my $new_subtail = $self->{bundle}->[$r]->{tail} += $cols;
	    die "Internal error" unless $new_subtail == $new_val;
	    #$new_yts++ if $self->{bundle}->[$r]->{tail} == $new_val;
	}
    } else {
	$new_val = $self->write_head;
	for my $r (0 .. $self->rows -1) {
	    my $new_subhead = $self->{bundle}->[$r]->{head} += $cols;
	    die "Internal error" unless $new_subhead == $new_val;
	    #$new_yts++ if $self->{bundle}->[$r]->{tail} == $new_val;
	}
    }
    #warn "yts changed from $self->{yts} to $new_yts\n" 
    #	if $self->{yts} != $new_yts;
    #$self->yts($new_yts);
    return 0;
}

# Utility method to split some read/write into two contiguous
# reads/writes if it straddles the end of a buffer
sub destraddle {
    my ($self, $pointer, $cols) = @_;
    my $window    = $self->window;
    my $rel_start = $pointer % $window;
    my $rel_end   = $rel_start + $cols;

    die "columns > window" if $cols > $window;

    # use <= because the point of this routine is to break r/w into
    # contiguous r/w's rather than informing about wrap-around
    return ($cols) if ($rel_end <= $window);

    my $second = $rel_end - $window;
    my $first  = $cols - $second;
    return ($first, $second);
}

1;

__END__

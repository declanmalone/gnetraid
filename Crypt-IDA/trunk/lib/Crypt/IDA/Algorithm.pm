package Crypt::IDA::Algorithm;

use strict;
use warnings;

use v5.20;

use Math::FastGF2::Matrix;
use Crypt::IDA;
use Crypt::IDA::SlidingWindow;

use Class::Tiny qw/sw/,
{
    # I'm getting rid of 'n' because:
    # * It's meaningless when combining
    # * It's either implied or overridden when splitting
    k => undef, w => 1,
    mode => undef, bufsize => 16350,
    inorder => 0, outorder => 0, # passed to getvals_str/setvals_str

    # Simplify transform/key specification. Either provide a transform
    # matrix or a key with optional sharelist. Don't support sharelist
    # with xform matrix or auto-generating a key.

    xform => undef,
    key => undef,		# [@xvals, @yvals]
    sharelist => undef,

    # add some callbacks below...
};

sub BUILD {
    my ($self, $args) = @_;
    for my $req ( qw(k w mode bufsize inorder outorder) ) {
	die "$req attribute required" unless defined $self->$req;
    }
    die "Bad mode!" unless $self->{mode} =~ /^(split|combine)$/;
    for my $plus ( qw(k w bufsize) ) {
	die "$plus attribute strictly positive" unless $self->$plus > 0;
    }
    for my $ints ( qw(k w bufsize) ) {
	die "$ints attribute must be a whole number" 
	    unless int($self->$ints) == $self->$ints;
    }
    die "w must be 1, 2 or 4" unless $self->w =~ /^[124]$/;

    # bump bufsize until it's a multiple of k
    $self->{bufsize}++ while $self->{bufsize} % $self->k;

    # I have eliminated n being passed in as a parameter, but we need
    # to calculate it (or its apparent value) from the other
    # parameters. Why? So we know what the sizes of the input/output
    # matrices should be. I'll call it 'xform_rows', though.
    my $xform_rows = undef;
    my $k = $self->k;

    # The two ways of specifying the transform matrix are mutually
    # exclusive
    if (defined($self->{xform})) {
	die "Cannot use xform with key or sharelist"
	    if defined($self->{key}) or defined($self->{sharelist});
	$xform_rows = $self->{xform}->ROWS; # apparent value
    } else {
	# The new_cauchy and new_inverse_cauchy methods in
	# Math::FastGF2::Matrix can do a lot of parameter checking for
	# us. However, the parameter lists are slightly different for
	# split and combine, and we also want to set a default...
	#
	# It's probably better to check as much as we can here so that
	# the caller gets error messages higher up the call stack
	# (with parameter names/error messages that make more sense).

	if (defined $self->{key}) {
	    # break up list into yvals, xvals
	    my @key   = @{$self->{key}};
	    my @yvals = splice @key, -$k;

	    # apply sharelist, moving to new @xvals list
	    my @xvals;
	    if (defined $self->{sharelist}) {
		push @xvals, $key[$_] foreach @{$self->{sharelist}};
	    } else {
		@xvals = @key;
		# $self->{sharelist} = [ 0 .. $xvals - 1 ];
	    }
	    $xform_rows = scalar(@xvals);

	    # error check and make all matrices
	    if ($self->mode eq 'split') {
		die "key/sharelist needs an xval" unless $xform_rows >= 1;
		$self->{xform} = Math::FastGF2::Matrix->new_cauchy(
		    width => $self->{w}, org => "rowwise",
		    xvals => \@xvals,
		    yvals => \@yvals );
	    } else {		# combine:
		die "key/sharelist needs k xvals" unless $xform_rows == $k;
		$self->{xform} = Math::FastGF2::Matrix->new_inverse_cauchy(
		    width  => $self->{w}, org => "rowwise",
		    xylist => [@xvals,@yvals],
		    xvals  => [0 .. $k -1], # TODO: make this not needed
		    size   => $k);
	    }
	} else {
	    # create a default key? Nah.
	    die "Must supply a key or xform parameter";
	}
    }

    # create input, output matrices
    my ($in,$out);
    if ($self->mode eq 'split') {
	die "key/sharelist needs an xval" unless $xform_rows >= 1;
	$in = Math::FastGF2::Matrix->new(
	    rows  => $k,          cols => $self->{bufsize},
	    width => $self->{w},  org  => "colwise");
	$out = Math::FastGF2::Matrix->new(
	    rows  => $xform_rows, cols => $self->{bufsize},
	    width => $self->{w},  org  => "rowwise");
    } else {
	$in = Math::FastGF2::Matrix->new(
	    rows  => $k,          cols => $self->{bufsize},
	    width => $self->{w},  org  => "rowwise");
	$out = Math::FastGF2::Matrix->new(
	    rows  => $k,          cols => $self->{bufsize},
	    width => $self->{w},  org  => "colwise");
    }
    $self->{imat} = $in;
    $self->{omat} = $out;

    # sliding window
    $self->{sw} = Crypt::IDA::SlidingWindow->new(
	mode => $self->{mode}, window => $self->{bufsize} / $k,
	rows => $self->{mode} eq 'split' ? $xform_rows : $k
    );

    #$self->{sw}->cb_read_bundle(sub {say "Advanced read bundle"});
}

sub splitter { shift->new(mode => 'split', @_) }
sub combiner { shift->new(mode => 'combine', @_) }

sub fill_stream {
    my ($self,$str) = @_;
    my $k    = $self->{k};
    my $w    = $self->{w};
    my $cols = length($str) / ($k * $w);
    my $str2 = '';
    die "fill_stream: input length must be a multiple of $k * $w"
	if $cols != int($cols);

    # add check against read_ok (or just fail later on advance_read)

    my $sw  = $self->{sw};
    my $mat = $self->{imat};

    # need to split string if we straddled matrix boundary
    my ($first,$second) = $sw->destraddle($sw->{read_head},$cols);
    $str2 = substr $str, $first * $k * $w if defined $second;

    my $rel_col = $sw->{read_head} % $sw->{window};
    $mat->setvals_str(0, $rel_col, $str, $self->{inorder});
    $mat->setvals_str(0, 0, $str2, $self->{inorder}) if defined $second;

    $sw->advance_read($cols);
}

sub fill_substream {
    my ($self,$row,$str) = @_;
    my $k    = $self->{k};
    my $w    = $self->{w};
    my $len  = length($str);
    my $cols = $len / $w;
    my $str2 = '';
    die "fill_substream: input doesn't fill a column" if $cols != int($cols);

    my $sw  = $self->{sw};
    my $mat = $self->{imat};

    my $avail = $sw->can_fill_substream($row);

    die "Can't fill $len cols in substream (max $avail)" if $cols > $avail;

    # need to split string if we straddled matrix boundary
    my $hash = $sw->{bundle}->[$row];
    my ($first,$second) = $sw->destraddle($hash->{head},$cols);
    $str2 = substr $str, $first * $w if defined $second;

    my $rel_col = $hash->{head} % $sw->{window};
    $mat->setvals_str($row, $rel_col, $str, $self->{inorder});
    $mat->setvals_str($row, 0, $str2, $self->{inorder}) if defined $second;

    $sw->advance_read_substream($row,$cols);
}

sub split_stream {
    my ($self,$cols) = @_;
    my $sw = $self->{sw};

    my ($rok,$pok,$wok,$bundle) = $sw->can_advance;
    if (defined $cols) {
	die "Can't split $cols columns (max is $pok)" if $cols > $pok;
    } else {
	$cols = $pok;
    }

    # need to split requests if we straddled matrix boundary
    my ($first,$second) = $sw->destraddle($sw->{processed},$cols);

    my $xform = $self->{xform};
    my $in    = $self->{imat};
    my $out   = $self->{omat};
    my $rel_col = $sw->{processed} % $sw->{window};
    my $k     = $self->{k};
    my $w     = $self->{w};

    Math::FastGF2::Matrix::multiply_submatrix_c(
	$xform, $in, $out,
	0, 0, $k,
	$rel_col, $rel_col, $first);
    Math::FastGF2::Matrix::multiply_submatrix_c(
	$xform, $in, $out,
	0, 0, $k,
	0, 0, $second) if defined $second;

    $sw->advance_process($cols);
}

sub combine_streams {
    my ($self,$cols) = @_;
    my $sw = $self->{sw};
    my ($rok,$pok,$wok,@bundle) = $sw->can_advance;
    if (defined $cols) {
	die "Can't split $cols columns (max is $pok)" if $cols > $pok;
    } else {
	$cols = $pok;
    }

    # need to split requests if we straddled matrix boundary
    my ($first,$second) = $sw->destraddle($sw->{processed},$cols);

    my $xform = $self->{xform};
    my $rows  = $sw->{rows};
    my $in    = $self->{imat};
    my $out   = $self->{omat};
    my $rel_col = $sw->{processed} % $sw->{window};

    Math::FastGF2::Matrix::multiply_submatrix_c(
	$xform, $in, $out,
	0, 0, $rows,
	$rel_col, $rel_col, $first);
    Math::FastGF2::Matrix::multiply_submatrix_c(
	$xform, $in, $out,
	0, 0, $rows,
	0, 0, $second) if defined $second;

    $sw->advance_process($cols);
}

sub empty_stream {
    my ($self, $cols) = @_;
    my $sw = $self->{sw};
    my $avail = $sw->can_empty;
    if (defined $cols) {
	die "Can't empty $cols columns (max is $avail)" if $cols > $avail;
    } else {
	$cols = $avail;
    }

    my $w = $self->{w};
    my $k = $self->{k};
    my $str = '';
    my $mat = $self->{omat};
    my $order = $self->{outorder};

    my ($first,$second) = $sw->destraddle($sw->{read_tail},$cols);
    my $rel_col = $sw->{write_tail} % $sw->{window};
    $str = $mat->getvals_str(0,$rel_col,$first  * $w * $k,$order);
    $str.= $mat->getvals_str(0,0,       $second * $w * $k,$order) if defined($second);
    $sw->advance_write($cols);

    $str;
}

sub empty_substream {
    my ($self, $row, $cols) = @_;
    my $sw = $self->{sw};

    my $avail = $sw->can_empty_substream($row);
    if (defined $cols) {
	die "Can't empty $cols columns (max is $avail)" if $cols > $avail;
    } else {
	$cols = $avail;
    }

    my $hash = $sw->{bundle}->[$row];
    my ($head,$tail) = ($hash->{head}, $hash->{tail});

    # need to split requests if we straddled matrix boundary
    my $str = '';
    my $mat = $self->{omat};
    #my $w   = $self->{w};
    my $order = $self->{outorder};
    my ($first,$second) = $sw->destraddle($tail,$cols);
    my $rel_col = $tail % $sw->{window};
    $str = $mat->getvals_str($row,$rel_col,$first,$order);
    $str.= $mat->getvals_str($row,0,$second,$order) if defined($second);

    $sw->advance_write_substream($row,$cols);
    $str;
}

1;

__END__
=pod

=head1 NAME

Crypt::IDA::Algorithm - Expose methods useful for writing custom IDA loops

=head1 SYNOPSIS

 use Crypt::IDA::Algorithm;
 use Digest::HMAC_SHA1 qw/hmac_sha1_hex/;
 
 # Make cryptographically secure ticket for entry to a party
 my $secret = 'Not just any Tom, Dick and Harry';
 my $ticket = 'Admit Tom, Dick /and/ Harry to the party together';
 my $signed = "$ticket:" . hmac_sha1_hex($ticket,$secret);
 
 # Algorithm works on full matrix columns, so must pad the message
 $signed .= "\0" while length($signed) % 3;
 
 # Turn the signed ticket into three shares
 my $s = Crypt::IDA::Algorithm->splitter(k=>3, n=>3, key=>[1..6]);
 $s->fill_stream($signed);
 $s->split_stream;
 my @tickets = map { $s->empty_substream($_) } (0..2);
 
 # At the party, Tom, Dick and Harry present shares to be combined
 my $c = Crypt::IDA::Algorithm->combiner(k=>3, key=>[1..6]);
 $c->fill_substream($_, $tickets[$_]) foreach (0..2); # same order
 $c->combine_streams;
 my $got = $c->empty_stream;
 
 # Check the recovered ticket
 $got =~ /^(.*):(.*)\0*$/;
 my ($msg, $sig) = ($1,$2);
 die "Fake!\n" unless $sig eq hmac_sha1_hex($msg,$secret);

=head1 DESCRIPTION

This module is a rewrite of the original C<ida_split> and
C<ida_combine> methods provided in C<Crypt::IDA>. It provides a
pared-down, simplified interface intended to make it easier to
integrate with an external event loop. It does this by:

=over

=item * Eliminating the use of external empty/fill callbacks to do I/O
(caller handles I/O instead)

=item * Eliminating the inner loop (caller decides when/how to loop, if needed)

=item * Allowing caller to register callback hooks to become notified
when something "interesting" happens within the code (eg, new input
became available or space became available in the output buffer)

=back

The internal organisation of the code is also improved. The main
C<Crypt::IDA> loops (C<ida_split> and C<ida_combine>) both call a
generic internal C<ida_process_streams> loop. It has very complicated
logic to enable it to handle different matrix layouts and circular
buffer reads/writes, as well as dealing with partial matrix columns.

By contrast, this new code:

=over

=item * always deals with full matrix columns

=item * abstracts away the circular buffering into a new, more generic
"Sliding Window" class (C<Crypt::IDA::SlidingWindow>, accessible via
the C<sw> accessor)

=item * treats split and combine separately, providing different
method interfaces appropriate to each

=back

This new code also avoids using `name => value` style
parameter-passing interface, apart from in the constructor methods.

Although my main design goal for this class was to make it work better
with external event loops, the cleaner interface, with less
boilerplate for setting up fillers/emptiers, means that it might be
more comfortable to use in general. Even if you're not using an event
loop.

=head1 GENERAL OPERATION

By way of recap, the IDA split and combine operations are a set of
matrix operations:

 transform x input -> output

The constructor will create a set of input and output matrix buffers
as follows:

   +----------+>---------+      +>---------+----------+
   v          | Output   |      |  Input   v          v
   |  Input   +>---------+      +>---------+ Output   |
   |    =     |   =      |      |   =      |    =     |
   | COLWISE  +>---------+      +>---------+ COLWISE  |
   |          | ROWWISE  |      | ROWWISE  |          |
   +----------+----------+      +----------+----------+

            SPLIT                       COMBINE

In both cases, one full column of input produces one full column of
output. Matrix columns are written to and read circularly, with checks
made to prevent overruns and underruns. To simplify this processing,
the input and output buffers are created with the same number of
columns (the "window size") in each.

Progress is made using the usual input -> process -> output idiom with
the help of a "sliding window" class that tracks three types of pointer:

=over

=item * input on the left advances the read_head pointer

=item * processing advances the read_tail on the left, process pointer
in the middle, and write_head pointer on the right

=item * output on the right advances the write_tail pointer

=back

The class ensures that inputs and outputs cannot advance any further
than their respective input and output windows. That is, it prevents
buffer overflows caused by:

=over

=item * trying to read too much into the input buffer

=item * processing too much, causing an overflow in the output buffer

=back

The sliding window class also handles synchronisation of bundles of
substreams so that the overall bundle can advance when the slowest
substream in the bundle makes progress. A callback can be set up to
monitor for when this happens, allowing handling of asynchronous I/O
in an event-drive fashion. See CALLBACKS and INTEGRATION WITH EVENT
LOOPS for more details.

Note that the C<Crypt::IDA::Algorithm> class is designed from the
point of view of working with infinite-length streams. Or
indefinite-length streams, if you prefer. That is to say, it has no
inbuilt checks for EOF on the input stream(s). EOF checking on input
(as well as I/O errors in general) is left completely up to the
calling program.

=head1 CONSTRUCTORS


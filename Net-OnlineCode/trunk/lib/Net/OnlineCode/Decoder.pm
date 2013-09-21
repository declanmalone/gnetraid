package Net::OnlineCode::Decoder;

use strict;
use warnings;

use Carp;

use Net::OnlineCode;
use Net::OnlineCode::GraphDecoder;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

# Inherit from base class
@ISA = qw(Net::OnlineCode Exporter);
@EXPORT_OK = qw();

$VERSION = '0.01';

sub new {

  my $class = shift;

  my %opts = (
	      # decoder-specific arguments:
	      initial_rng => undef,
	      # user-supplied arguments:
	      @_
	     );
  unless (ref($opts{initial_rng})) {
    carp "$class->new requires an initial_rng => \$rng parameter\n";
    return undef;
  }

  # Send all arguments to the base class. It does basic parameter
  # handling/mangling, calculates the number of auxiliary blocks based
  # on them and generates a probability distribution.

  my $self = $class->SUPER::new(@_);

  # This sub-class needs to use the rng to generate the initial graph

  # print "decoder mblocks: $self->{mblocks}\n";

  my $graph = Net::OnlineCode::GraphDecoder->new
    (
     $self->{mblocks},
     $self->{ablocks},
     $self->auxiliary_mapping($opts{initial_rng}),
     $self->{expand_aux},
    );
  $self->{graph} = $graph;

  # print "Decoder: returning from constructor\n";
  return $self;

}

sub accept_check_block {
  my $self = shift;
  my $rng  = shift;

  # print "Decoder: calling checkblock_mapping\n";
  my $composite_blocks = $self->checkblock_mapping($rng);

  # print "Decoder: Adding check block to graph\n";
  my $check_node = $self->{graph}->add_check_block($composite_blocks);

  # print "Decoder: Resolving graph\n";
  my ($done, @which) = ($self->{graph}->resolve($check_node));

  # print "Decoder: Returning from accept_check_block\n";
  if ($self->{expand_aux}) {
    # user doesn't care about aux blocks if expand_aux is on
    return ($done, grep { $_ < $self->{mblocks} } @which );
  } else {
    return ($done, @which);
  }
}

# expand_aux already handled in graph object
sub xor_list {
  my $self = shift;
  my $i = shift;

  my $coblocks = $self->get_coblocks;

  # the graph object assigns check blocks indexes after the composite
  # blocks, but the user would prefer to count them from zero:

  my @list = map { $_ - $coblocks } ($self->{graph}->xor_list($i));

  foreach (@list) { die "xor_list: $_ is negative!\n" if $_ < 0; }

  return @list;
}

1;

__END__

=head1 NAME

Net::OnlineCode::Decoder - Rateless Forward Error Correction Decoder

=head1 SYNOPSIS

  use Net::OnlineCode::Decoder;
  use strict;

  # variables received from encoder:
  my ($msg_id, $e, $q, $msg_size, $blocksize);

  # calculated/local variables
  my (@check_blocks,$message,$block_id);
  my $mblocks = int(0.5 + ($msg_size / $blocksize));
  my $rng     = Net::OnlineCode::RNG->new($msg_id);

  my $decoder = Net::OnlineCode::Decoder->new(
    mblocks     => $mblocks,
    initial_rng => $rng,
    # ... pass e and q if they differ from defaults
  );

  my ($done,@decoded) = (0);
  until ($done) {
    my ($block_id,$contents) = ...; # receive data from encoder
    push @check_blocks, $contents;

    $rng->seed($block_id);
    ($done,@decoded) = $decoder->accept_check_block($rng);

    # XOR check blocks together to decode each message block
    foreach my $decoded_block (@decoded) {
      my @xor_list = $decoder->xor_list($decoded_block);
      my $block = $check_blocks[shift @xor_list];
      foreach my $xor_block (@xor_list) {
        map { substr($block, $_, 1) ^= substr($check_blocks[$xor_block], $_, 1) }
          (0 .. $blocksize-1);
      }
      # save contents of decoded block
      substr($message, $decoded_block * $blocksize, $blocksize) = $block;
    }
  }
  $message = substr($message, 0, $msg_size);  # truncate to correct size
  print $message;                             # Done!

=head1 DESCRIPTION

This module implements the "decoder" side of the Online Code algorithm
for rateless forward error correction. Refer to the L<the
Net::OnlineCode documentation|Net::OnlineCode> for more technical
details.

The basic outline for how the encoder works is follows:

=over


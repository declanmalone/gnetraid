package Net::OnlineCode::Decoder;

use strict;
use warnings;

use Carp;

use Net::OnlineCode;
use Net::OnlineCode::GraphDecoder;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

# Inherit from base class
our @ISA = qw(Net::OnlineCode Exporter);
our @EXPORT_OK = qw();

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

  my $graph = Net::OnlineCode::GraphDecoder->new
    (
     $self->{mblocks},
     $self->{ablocks},
     $self->auxiliary_mapping($opts{initial_rng})
    );

  $self->{graph} = $graph;
  return $self;

}

sub accept_check_block {
  my $self = shift;
  my $rng  = shift;

  my $composite_blocks = $self->checkblock_mapping($rng);
  my $check_node = $self->{graph}->add_check_block($composite_blocks);

  return ($self->{graph}->resolve($check_node));
}

sub xor_list {
  my $self = shift;
  my $i = shift;

  # the graph object assigns check blocks indexes after the composite
  # blocks, but the user would prefer to count them from zero:
  my $coblocks = $self->coblocks;
  return map { $_ - $coblocks } ($self->{graph}->xor_list);
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
      substr($message, $decoded_block * $blocksize, $decoded_block) = $block;
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


package Net::OnlineCode::Decoder;

use strict;
use warnings;

use Carp;

use Net::OnlineCode;
use Net::OnlineCode::GraphDecoder;

require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);

# Inherit from base class
@ISA = qw(Net::OnlineCode Exporter);
@EXPORT_OK = qw();

$VERSION = '0.02';


use constant DEBUG => 1;

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

  print "Decoder check block: " . (join " ", @$composite_blocks) . "\n" if DEBUG;

  # print "Decoder: Adding check block to graph\n";
  my $check_node = $self->{graph}->add_check_block($composite_blocks);

  # short-circuit check blocks that don't have any unsolved neighbours
  return (0) unless $check_node;

  ++($self->{chblocks});

  # print "Decoder: Resolving graph\n";
  ($self->{graph}->resolve($check_node));

}

# expand_aux already handled in graph object
sub xor_list {
  my $self = shift;
  my $i = shift;

  return ($self->{graph}->xor_list($i));

  # algorithm will no longer return just composite blocks


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
      fast_xor_strings(\$block, map { $check_blocks[$_] } @xor_list);

      # save contents of decoded block
      substr($message, $decoded_block * $blocksize, $blocksize) = $block;
    }
  }
  $message = substr($message, 0, $msg_size);  # truncate to correct size
  print $message;                             # Done!

=head1 DESCRIPTION

This module implements the "decoder" side of the Online Code algorithm
for rateless forward error correction. Refer to the L<the
Net::OnlineCode documentation|Net::OnlineCode> for the technical
background


=head1 SEE ALSO

See L<Net::OnlineCode> for background information on Online Codes.

This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

The C code at the core of this Perl module can additionally be
redistributed and/or modified under the terms of the "GNU Library
General Public License" ("LGPL"). For the purpose of that license, the
"library" is defined as the unmodified C code in the clib/ directory
of this distribution. You are permitted to change the typedefs and
function prototypes to match the word sizes on your machine, but any
further modification (such as removing the static modifier for
non-exported function or data structure names) are not permitted under
the LGPL, so the library will revert to being covered by the full
version of the GPL.

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


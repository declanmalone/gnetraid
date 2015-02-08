// Decoder methods

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#include "structs.h"
#include "decoder.h"

int oc_decoder_init(oc_decoder *dec, int mblocks, oc_rng_sha1 *rng,
		    int flags, ...) { // ... fudge, q, e, f

  // Besides required parameters, we also have optional ones that are
  // the same ones that oc_codec_init takes. The end of the optional
  // list of args must be terminated with 0ll.
  //
  // The flags parameter here is composed of OC_EXPAND_MSG,
  // OC_EXPAND_AUX or a combination (logical or) of the two. I'm
  // making it a required parameter to make sure a null value isn't
  // confused with the end of the optional parameter list.

  // C doesn't let you pass va_args from here into the oc_codec_init
  // function so I'm stuck with various inelegant solutions. The least
  // bad seems to be to duplicate the va_args functionality here (and
  // in the encoder) and keep things consistent by using macros to
  // define the defaults in "online-code.h".

  float  fudge=1.2, new_fudge;	// !!new optional parameter!!
  int    q=OC_DEFAULT_Q, new_q;
  double e=OC_DEFAULT_E, new_e; // demoted back to float in parent
  int    f=OC_DEFAULT_F, new_f;	// f=0 => not supplied (calculated)

  int    super_flag;

  // extract variadic args
  va_list ap;

  va_start(ap, flags);
  do {				// preferable to goto?
    // new "fudge factor" optional parameter (float promoted in ...)
    new_fudge = va_arg(ap, double);
    if (new_fudge == 0.0) break; else fudge = new_fudge;

    new_q = va_arg(ap, double); // float automatically promoted in ...
    if (new_q == 0) break; else q=new_q;

    new_e = va_arg(ap, double); // float automatically promoted in ...
    if (new_e == 0) break; else e=new_e;

    new_f = va_arg(ap, int);
    if (new_f == 0) break; else f=new_f;

  } while(0);
  va_end(ap);

  if (NULL == dec) {
    fprint(stderr, "oc_decoder_init: passed NULL decoder pointer\n");
    return OC_FATAL_ERROR;
  }

  if (NULL == rng) {
    fprint(stderr, "oc_decoder_init: passed NULL rng pointer\n");
    return OC_FATAL_ERROR;
  }
  dec->rng = rng;

  // call "super" with extracted args
  super_flag = oc_codec_init(&(dec->base), mblocks, q, e, f, 0ll);

  if (super_flag & OC_FATAL_ERROR) {
    fprint(stderr, "oc_decoder_init: parent class returned fatal error\n");
    return super_flag;
  }

  if (flags & OC_EXPAND_CHK) {
    fprint(stderr, "oc_decoder_init: OC_EXPAND_CHK not valid here\n");
    return super_flag & OC_FATAL_ERROR;
  }
  dec->flags = flags;		// our flags; parent's is just for errors

  // parent doesn't create auxiliary mapping so we do it
  if (NULL == oc_auxiliary_map(&(dec->base), rng)) { // stashed for us
    fprint(stderr, "oc_decoder_init: failed to make auxiliary mapping\n");
    return super_flag & OC_FATAL_ERROR;
  }

  // Create graph decoder
  if (oc_graph_init(&(dec->graph), &(dec->base), fudge)) {
    fprintf(stderr, "oc_decoder_init: failed to initialise graph\n");
    return super_flag & OC_FATAL_ERROR;
  }

  return super_flag;

}


// Accept a check block (from a sender) and return zero on success
int oc_accept_check_block(oc_decoder *decoder, oc_rng_sha1 *rng) {

  int *p, f;
  oc_codec *codec;
  oc_graph *graph;

  assert(decoder != NULL);
  assert(rng != NULL);

  codec = &(decoder->base);	// could just cast decoder
  graph = &(decoder->graph);

  // call parent class methods to figure out mapping based on RNG
  f = oc_random_degree(codec, rng);
  p = oc_checkblock_map(codec, f, rng);
  if (p == NULL) {
    fprintf(stderr, "oc_accept_check_block: failed to allocate check block\n");
    return -1;
  }

  // register the new check block in the graph
  if (-1 == oc_graph_check_block(graph, p)) {
    fprintf(stderr, "oc_accept_check_block: failed to graph check block\n");
    return -1;
  }

  return 0;

}

// pass resolve calls onto graph decoder resolve method
int oc_resolve(oc_decoder *decoder, oc_block_list **solved) {

  assert(decoder != NULL);
  assert(solved  != NULL);

  return oc_graph_resolve(&(decoder->graph), solved);
}

#if 0

# new routine to replace xor_list; does "lazy" expansion of node lists
# from graph object, honouring the expand_aux and (new) expand_msg
# flags.
sub expansion {

  my ($self, $node) = @_;

  # pull out frequently-used variables (using hash slice)
  my ($expand_aux,$expand_msg) = @{$self}{"expand_aux","expand_msg"};
  my ($mblocks,$coblocks)      = @{$self}{"mblocks","coblocks"};

  # Stage 1: collect list of nodes in the expansion, honouring flags
  my ($in,$out,$expanded,$done) =
    ($self->{graph}->{xor_list}->[$node],[],0,0);

  if (DEBUG) {
    print "Expansion: node ${node}'s input list is " . (join " ", @$in) . "\n";
  }

  until ($done) {
    # we may need several loops to expand everything since aux blocks
    # may appear in the expansion of message blocks and vice-versa.
    # It's possible to do the expansion with just one loop, but the
    # code is more messy/complicated.

    for my $i (@$in) {
      if ($expand_msg and $i < $mblocks) {
        ++$expanded;
        push @$out, @{$self->{graph}->{xor_list}->[$i]};
      } elsif ($expand_aux and $i >= $mblocks and $i < $coblocks) {
        ++$expanded;
        push @$out, @{$self->{graph}->{xor_list}->[$i]};
      } else {
        push @$out, $i;
      }
    }
    $done = 1 unless $expanded;
  } continue {
    ($in,$out) = ($out,[]);
    $expanded = 0;
  }

  # test expansion after stage 1
  if (0) {
    for my $i (@$in) {
      if ($expand_aux) {
	die "raw expanded list had aux blocks after stage 1\n" 
	  if $i >= $mblocks and $i < $coblocks;
      }
      if ($expand_msg) {
	die "raw expanded list had msg blocks after stage 1\n" 
	  if $i < $mblocks;
      }
    }
  }

  if (DEBUG) {
    print "Expansion: list after expand_* is " . (join " ", @$in) . "\n";
  }

  # Stage 2: sort the list
  my @sorted = sort { $a <=> $b } @$in;

  # Stage 3: create output list containing only nodes that appear an
  # odd number of times
  die "expanded list was empty\n" unless @sorted;

  my ($previous, $runlength) = ($sorted[0], 0);
  my @output = ();

  foreach my $i (@sorted) {
    if ($i == $previous) {
      ++$runlength;
    } else {
      push @output, $previous if $runlength & 1;
      $previous = $i;
      $runlength = 1;
    }
  }
  push @output, $previous if $runlength & 1;

  # test expansion after stage 3
  if (0) {
    for my $i (@output) {
      if ($expand_aux) {
	die "raw expanded list had aux blocks after stage 3\n" 
	  if $i >= $mblocks and $i < $coblocks;
      }
      if ($expand_msg) {
	die "raw expanded list had msg blocks after stage 3\n" 
	  if $i < $mblocks;
      }
    }
  }

  # Finish: return list
  return @output;

}

#endif

#!/usr/bin/perl -w

# Copyright notice
#
# File (c) Declan Malone 2009. Licensed under version 3 of the GPL.
#
# For full details of license, see:
#
# http://www.gnu.org/licenses/gpl-3.0.html
#

use Sys::Hostname;
use strict;

my $profile=hostname;
my $header_file="./fast_gf2.h";

my %prototypes=();

my $usage=<<EOT;
fast_gf2_method_chooser

The fast_gf2 library routines includes several methods for optimising
arithmetic operations in Galois Fields. This script takes a list of
preferred methods for each field size (8, 16 and 32 bits) then reads
in the header file for the routines and generates the macro
definitions necessary to call those methods in a way that hides the
underlying calling conventions. These definitions are then output to a
new header file. Note that this only serves to select between
different implementations within a type. It does not attempt to hide
underlying types or allow arbitrary precision numbers to be used
instead of a particular type. Thus if you want to support multiple
word sizes in the application, you will need to write one version for
each type or write some other wrapper code to abstract away type
information.

Usage:

 fast_gf2_method_chooser [options] u8_method u16_method u32_method

Each u*_method is a number between 0 and the number of optimised
methods available for that particular word size. A choice of 0
signifies that the default long operation (currently multiply, invert,
divide and power) should be used instead of any optimised
version. Otherwise, the selected optimised method will be called.

When scanning the header file, if an optimised method for a particular
operation is unavailable, wrapper code for calling the default long
method will be generated.

Options:

 -p  profile

     By default, the name of the generated header file will be based
     on the hostname. This is because there will usually be one set of
     methods which performs best on the particular machine the library
     is being compiled on. This option allows for creating several
     different profiles on the same machine, which may be useful in
     creating several different versions of an application for
     benchmarking purposes.

EOT

my $opts_ok=1;
my $opt_profile=$profile;
my %methods=();

if (exists $ARGV[0] and $ARGV[0]=~/^-h/) { $opts_ok = 0 };
if (exists $ARGV[0] and $ARGV[0]=~/^-p$/) {
  $opt_profile=shift @ARGV;
}
if (scalar (@ARGV) < 3) {
  $opts_ok =0;
} else {
  $methods{"u8"}=shift;
  $opts_ok=0 unless $methods{"u8"}=~/^\d+$/;
  $methods{"u16"}=shift;
  $opts_ok=0 unless $methods{"u16"}=~/^\d+$/;
  $methods{"u32"}=shift;
  $opts_ok=0 unless $methods{"u32"}=~/^\d+$/;
  if (scalar (@ARGV) > 0) {
    warn "Ignoring extra arguments starting with '", (shift @ARGV), "'\n";
  }
}

die "$usage" unless $opts_ok;
die "Value for profile is unset\n" unless defined($profile);

my $boilerplate=<<EOT;
/*
   This file was generated by $0
   DO NOT MAKE ANY EDITS TO THIS FILE OR THEY MAY BE LOST

   File (c) Declan Malone 2009. Licensed under version 3 of the GPL.

   For full details of license, see:

   http://www.gnu.org/licenses/gpl-3.0.html
*/

EOT

my $struct_definition=<<EOT;
/*
  Structure definition. This structure holds details such as table
  pointers and polynomial which the macros need to save and access in
  order to call the optimised routines with the correct arguments.
*/

struct gf2_fast_maths {
  int width;  /* width in bits */
  int rc;     /* return code from init */
  union {
    gf2_u8 u8;
    gf2_u8 u16;
    gf2_u8 u32;
  } polynomial;
  union {
    gf2_u8 u8;
    gf2_u8 u16;
    gf2_u8 u32;
  } generator;
  union {
    gf2_s8  *s8;
    gf2_s16 *s16;
    gf2_s32 *s32;
    gf2_u8  *u8;
    gf2_u16 *u16;
    gf2_u32 *u32;
  } table1;
  union {
    gf2_s8  *s8;
    gf2_s16 *s16;
    gf2_s32 *s32;
    gf2_u8  *u8;
    gf2_u16 *u16;
    gf2_u32 *u32;
  } table2;
  union {
    gf2_s8  *s8;
    gf2_s16 *s16;
    gf2_s32 *s32;
    gf2_u8  *u8;
    gf2_u16 *u16;
    gf2_u32 *u32;
  } table3;
  union {
    gf2_s8  *s8;
    gf2_s16 *s16;
    gf2_s32 *s32;
    gf2_u8  *u8;
    gf2_u16 *u16;
    gf2_u32 *u32;
  } table4;
  union {
    gf2_s8  *s8;
    gf2_s16 *s16;
    gf2_s32 *s32;
    gf2_u8  *u8;
    gf2_u16 *u16;
    gf2_u32 *u32;
  } table5;
};

EOT

sub long_method {
  my $s=shift;			# size
  $s=~s/^[us]//;		# we only care about the number

  "/* initialise u$s to use long multiply, invert, etc. */
#define gf2_fast_u${s}_init(OBJ,POLY,GEN) ( \\
  POLY && (OBJ=(struct gf2_fast_maths *) \\
    malloc(sizeof(struct gf2_fast_maths))) ? ( \\
  OBJ->polynomial.u$s=POLY, OBJ->width=$s, \\
  OBJ->rc=0) : -1 )

#define gf2_fast_u${s}_deinit(OBJ) ( \\
  free(OBJ))

#define gf2_fast_u${s}_mul(OBJ,A,B) ( \\
  gf2_long_mod_multiply_u$s(A,B,OBJ->polynomial.u$s))

#define gf2_fast_u${s}_inv(OBJ,A) ( \\
  gf2_long_mod_inverse_u$s(A, OBJ->polynomial.u$s))

#define gf2_fast_u${s}_div(OBJ,A,B) ( \\
  gf2_long_mod_multiply_u${s}(A, \\
    gf2_long_mod_inverse_u$s(B, OBJ->polynomial.u$s), \\
    OBJ->polynomial.u$s \\
  ))

#define gf2_fast_u${s}_pow(OBJ,A,B) ( \\
  gf2_long_mod_power_u$s(A,B,OBJ->polynomial.u$s))

";
}

# scan input header file to find function prototypes
open IN, "<$header_file" or die "Couldn't read input header file\n";

my ($prototype,$type,$op,$method);
while ($_=<IN>) {

  chomp;

  # pull in the prototype, extracting just type, operation and method
  # for now. Will handle parsing of arguments later.
  if (/^\w+\s+gf2_fast_((u\d+)_(\w+)_(m\d+))\s*\(/) {
    ($prototype,$type,$op,$method)=($_,$2,$3,$4);
    until (/;\s*$/) {
      $_=<IN>;
      die "Parse error: found EOF before terminating ;\n"
	unless defined($_);
      chomp; $prototype.=" $_";
    }
    #warn "Got prototype: ${type}_${op}_${method}\n";
    $prototypes{"${type}_${op}_${method}"}=$prototype;
  }
}
close (IN);

# open output file
open OUT, ">fast_gf2_wrappers-$profile.h" or
  die "Sorry, couldn't create output file: $!\n";

print OUT $boilerplate, $struct_definition;

for my $t ("u8", "u16", "u32") {
  my $chosen_method=$methods{"$t"};
  my $s=$t;
  $s=~s/^[us]//;

  if ($chosen_method == 0) {	# use long method

    print OUT long_method($t);

  } elsif (exists $prototypes{"${t}_init_m$chosen_method"}) {

    my $init_proto=$prototypes{"${t}_init_m$chosen_method"};
    my %table_mappings=();
    my %table_type=();

    # scan through prototype to find a list of table names, then store
    # a mapping between them and the numbered entries in the struct
    my $tableno=1;
    my @chain_args=();
    my $saw_gen_arg=0;

    foreach my $arg (split ",", $init_proto) {
      $arg=~s/^.*\(//;
      $arg=~s/\)\s*;\s*$//;
      if ($arg =~ /\s*gf2_([us]\d+)\s*\*+\s*(\w+)/) {
	$table_type{$2}=$1;
	$table_mappings{$2}="OBJ->table$tableno.$1";
	push @chain_args, "& $table_mappings{$2} /* $2 */";
	++$tableno;
      } elsif ($arg =~ /poly/) {
	push @chain_args, "OBJ->polynomial.$t=POLY";
      } elsif ($arg =~ /g/) {
	if ($saw_gen_arg++) {
	  warn "Unexpectedly got duplicate generator arg\n";
	} else {
	  push @chain_args, "OBJ->generator.$t=GEN";
	}
      } else {
	warn "Don't know what to do with init arg $arg\n";
      }
    }
    print OUT "/* Initialise $t to use optimised method $chosen_method */\n";
    print OUT "#define gf2_fast_${t}_init(OBJ,POLY,GEN) (\\\n";
    print OUT "  POLY && (OBJ=(struct gf2_fast_maths *) \\\n";
    print OUT "  malloc(sizeof(struct gf2_fast_maths))) ? ( \\\n";
    print OUT "  OBJ->width = $s, \\\n";
    print OUT "  OBJ->rc=gf2_fast_${t}_init_m$chosen_method( \\\n";
    print OUT "    ", join ", \\\n    ", @chain_args;
    print OUT " \\\n";
    print OUT "  ) ? (free(OBJ), -1) : 0 ) : -1 )\n\n";

    # De-init also has to be handled somewhat specially
    unless (exists $prototypes{"${t}_deinit_m$chosen_method"}) {
      die "Strange: had no deinit for $t, method $chosen_method\n";
    }
    my $deinit_proto=$prototypes{"${t}_deinit_m$chosen_method"};
    @chain_args=();
    foreach my $arg (split ",", $deinit_proto) {
      $arg=~s/^.*\(//;
      $arg=~s/\)\s*;\s*$//;
      if ($arg =~ /\s*gf2_([us]\d+)\s*\*+\s*(\w+)/) {
	push @chain_args, "$table_mappings{$2} /* $2 */";
      } else {
	warn "Don't know what to do with deinit arg $arg\n";
      }
    }

    print OUT "#define gf2_fast_${t}_deinit(OBJ) (\\\n";
    print OUT "  gf2_fast_${t}_deinit_m$chosen_method( \\\n";
    print OUT "    ", join ", \\\n    ", @chain_args;
    print OUT " \\\n";
    print OUT "  ), free(OBJ) )\n\n";

    # For the remaining functions we have a choice of calling the
    # accelerated function (if the prototype exists) or the "long"
    # form.
    for my $op (qw(mul inv div pow)) {
      unless (exists $prototypes{"${t}_${op}_m$chosen_method"}) {
	if ($op eq "mul") {
	  print OUT "#define gf2_fast_u${s}_mul(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_long_mod_multiply_u$s(A,B,OBJ->polynomial.u$s))\n";
	} elsif ($op eq "inv") {
	  print OUT "#define gf2_fast_u${s}_inv(OBJ,A) ( \\\n";
	  print OUT "   gf2_long_mod_inverse_u$s(A, OBJ->polynomial.u$s))\n";
	} elsif ($op eq "div") {
	  print OUT "#define gf2_fast_u${s}_div(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_long_mod_multiply_u${s}(A, \\\n";
	  print OUT "  gf2_long_mod_inverse_u$s(B, OBJ->polynomial.u$s), \\\n";
	  print OUT "  OBJ->polynomial.u$s)) \\\n";
	} elsif ($op eq "pow") {
	  print OUT "#define gf2_fast_u${s}_pow(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_long_mod_power_u$s(A,B,OBJ->polynomial.u$s))\n";
	}
	print OUT "\n";

      } else {

	my $proto=$prototypes{"${t}_${op}_m$chosen_method"};
	@chain_args=();
	foreach my $arg (split ",", $proto) {
	  $arg=~s/^.*\(//;
	  $arg=~s/\)\s*;\s*$//;
	  if ($arg =~ /\s*gf2_([us]\d+)\s*\*+\s*(\w+)/) {
	    push @chain_args, "$table_mappings{$2} /* $2 */";
	  } elsif ($arg =~ /poly/) {
	    push @chain_args, "OBJ->polynomial.$t";
	  } elsif ($arg =~ /\d+ g/) {
	    push @chain_args, "OBJ->generator.$t";
	  } elsif ($arg =~ /\d+ a/) {
	    push @chain_args, "A";
	  } elsif ($arg =~ /\d+ b/) {
	    push @chain_args, "B";
	  } else {
	    warn "Don't know what to do with $op arg $arg in " .
	      "$t:$chosen_method\n";
	  }
	}
	if ($op eq "mul") {
	  print OUT "#define gf2_fast_u${s}_mul(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_fast_u${s}_mul_m$chosen_method( \\\n";
	  print OUT "    ", join ", \\\n    ", @chain_args;
	  print OUT "  \\\n  ))";
	} elsif ($op eq "inv") {
	  print OUT "#define gf2_fast_u${s}_inv(OBJ,A) ( \\\n";
	  print OUT "   gf2_fast_u${s}_inv_m$chosen_method(\\\n";
	  print OUT "    ", join ", \\\n    ", @chain_args;
	  print OUT "  \\\n  ))";
	} elsif ($op eq "div") {
	  print OUT "#define gf2_fast_u${s}_div(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_fast_u${s}_div_m$chosen_method( \\\n";
	  print OUT "    ", join ", \\\n    ", @chain_args;
	  print OUT "  \\\n  ))";
	} elsif ($op eq "pow") {
	  print OUT "#define gf2_fast_u${s}_pow(OBJ,A,B) ( \\\n";
	  print OUT "  gf2_fast_u${s}_pow_m$chosen_method( \\\n";
	  print OUT "    ", join ", \\\n    ", @chain_args;
	  print OUT "  \\\n  ))";
	}
	print OUT "\n\n";
      }
    }

  } else {			# bad method number

    warn "No optimised $t code matching method #$chosen_method\n";
  }
}
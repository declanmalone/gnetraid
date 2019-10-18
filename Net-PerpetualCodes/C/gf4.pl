#!/usr/bin/env perl

use strict;
use warnings;

# see gf_16.c for construction of these tables
# These don't handle log[0] correctly (should be infinity).
my @gf16_exp = ( 1,2,4,8,3,6,12,11,5,10,7,14,15,13,9, 1  );
my @gf16_log = ( 0,0,1,4,2,8,5, 10,3,14,9,7, 6, 13,11,12 );

sub mul_gf16 ($$) {
    my ($a,$b) = @_;
    my $ind = $gf16_log[$a] + $gf16_log[$b];
    $ind -= 15 if $ind > 15;
    $gf16_exp[$ind];
}

sub inv_gf16 ($) {
    $gf16_exp[ 15 - $gf16_log[shift @_] ];
}

sub div_gf16 ($$) {
    my ($a,$b) = @_;
    my $ind = $gf16_log[$a] - $gf16_log[$b];
    $ind += 15 if $ind < 0;
    $gf16_exp[$ind];
}

# We can make a compressed multiplication table indexed on the fusion
# of two nibble operands into a single byte, eg
# 0 * 0 == table[0x00]
# 0 * 1 == table[0x01]
# 1 * 0 == table[0x10]
# etc.

my @gf16_nibble_mul = ();

sub make_mul_table {
    my ($a,$b,$ab);
    $a = 0;
    $gf16_nibble_mul[0] = 0;
    for $b (1..15) { 
	$gf16_nibble_mul[$b     ] = 0;
	$gf16_nibble_mul[$b << 4] = 0;
    }
    for my $a (1..15) {
	# diagonal
	my $aa = mul_gf16($a,$a);
	$gf16_nibble_mul[$a * 17] = $aa;
	# warn "$a.$a = $aa\n";
	# ab = ba
	for my $b ($a + 1 .. 15) {
	    $ab = mul_gf16($a,$b);
	    # warn "$a.$b = $ab\n";
	    $gf16_nibble_mul[$a + ($b << 4)] = $ab;
	    $gf16_nibble_mul[$b + ($a << 4)] = $ab;
	}
    }
}

# Checks the structure of the table and whether it agrees with mul_gf16
sub check_mul_table {
   my ($a,$b,$ab);
   for my $a (0..15) {
       for my $b (0..15) {
	   $ab = ($a << 4) + $b; # pack the nibbles
	   die "Not defined $a * $b" unless defined $gf16_nibble_mul[$ab];
	   if ($a && $b) {
	       die "Disagreement"
		   unless $gf16_nibble_mul[$ab] = mul_gf16($a,$b);
	   } else {
	       die "expect $a x $b == 0" if $gf16_nibble_mul[$ab];
	   }
       }
   }
}

# output the table as a C array
sub export_mul_table {

    my ($a,$b,$ab);
    
    print "unsigned char gf16_mul_table[256] = {\n";
    for $a (0..15) {
	print " ";
	for $b (0..15) {
	    $ab = ($a << 4) + $b;
	    printf("%2s", $gf16_nibble_mul[$ab]);
	    next if $a * $b == 225;
	    print ", ";
	}
	print "\n";
    }
    print "};\n"
}

make_mul_table;
check_mul_table;
export_mul_table;

my @gf16_inv;
sub make_inv_table {
    my ($a,$inv);
    push @gf16_inv, (0,1);	# 1/0 = infinity, 1/1 = 1
    for $a (2..15) {
	$inv = inv_gf16($a);
	$gf16_inv[$a] = $inv;
    }
}

sub export_inv_table {
    my ($a,$inv);
    print "unsigned char gf16_inv_table[16] = {\n ";
    for $a (0..15) {
	$inv = $gf16_inv[$a];
	printf("%2s", $inv);
	next if $a == 15;
	print ", ";
    }
    print "\n};\n"
}

make_inv_table;
export_inv_table;

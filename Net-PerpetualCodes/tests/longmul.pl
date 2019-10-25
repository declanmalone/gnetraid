# Since the Pi QPUs don't have private constant storage space, and I
# don't know the size of the private memory, I'll probably have to
# calculate gf8 multiplications explicitly. This routine tests the
# algorithm that I'm using, comparing the values with those from
# Math::FastGF2

# Polynomial is 0x11b = 0100011011, so rather than upgrading to shorts,
# shift the poly right = 010001101 + 1 remainder = 0x8d
#
# Now do this XOR before the shift and add in the remainder afterward
#
# I'm not sure if there's anything to be gained by this
# "optimisation", though. It adds an extra 7 additions compared to a
# few type casts.

sub _long_mul_gf8_v1 {
    my ($a,$b,$prod) = @_;
    # Optionally, return immediately if either operand is 0 or 1
    if (0) {
	return $a ? $b : 0 if ($a < 2);
	return $b ? $a : 0 if ($b < 2);
    }

    $prod = ($b & 1) ? $a : 0;
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 2);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 4);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 8);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 16);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 32);
    $a = ($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1;
    $prod ^= $a if ($b & 64);
    # Optimise last bit: don't update a unless we need to
    return ($b & 128) == 0 ? $prod :
	($prod ^ (($a & 128) ? ((($a ^ 0x8d) << 1) + 1) : $a << 1));
}

# This is the original version that uses 0x11b
sub _long_mul_gf8_v2 {
    my ($a,$b,$prod) = @_;
    # Optionally, return immediately if either operand is 0 or 1
    if (0) {
	return $a ? $b : 0 if ($a < 2);
	return $b ? $a : 0 if ($b < 2);
    }

    $prod = ($b & 1) ? $a : 0;
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 2);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 4);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 8);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 16);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 32);
    $a = ($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1);
    $prod ^= $a if ($b & 64);
    # Optimise last bit: don't update a unless we need to
    return ($b & 128) == 0 ? $prod :
	($prod ^ (($a & 128) ? (($a << 1) ^  0x11b) : ($a << 1)));
}

sub test_gf8_maths {
    for my $i (0..255) {
	for my $j (0..255) {
	    my $correct = gf2_mul(8,$i,$j);
	    my $maybe = _long_mul_gf8_v1($i,$j);
	    die "_long_mul_gf8_v1 incorrect with $i x $j\n"
		if $maybe != $correct;
	}
    }
    warn "v1 was fully correct\n";
    for my $i (0..255) {
	for my $j (0..255) {
	    my $correct = gf2_mul(8,$i,$j);
	    my $maybe = _long_mul_gf8_v2($i,$j);
	    die "_long_mul_gf8_v2 incorrect with $i x $j\n"
		if $maybe != $correct;
	}
    }
    warn "v2 was fully correct\n";
}

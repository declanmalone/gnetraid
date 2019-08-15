#!/usr/bin/env perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use Test::More;
BEGIN {
    use_ok('Math::FastGF2::Matrix', ':all');
    use_ok('Crypt::IDA', ':all') 
	or BAIL_OUT "Skipping tests that require Crypt::IDA";	
};

# I'll be adding a new matrix inversion routine that relies on
# knowing the "key" that was used to set up the matrix in the
# first place.

# First, use Crypt::IDA->ida_key_to_matrix() to create a matrix 
my $key = [ 1,2,3,4,5,6,7,8 ];

# This will represent a key for a (3,5) scheme. I'm mixing option
# names for ida_key_to_matrix and the new inverse_cauchy_from_xys
my @opts = (			# we can re-use to get inverse matrix
    quorum => 3,		# 
    size   => 3,		# was "quorum"
    shares => 5,		# n/a for new routine (=@xylist - @xvals)
    sharelist => [0..4],	# 
    xvals   => [0..4],		# was "sharelist"
    width  => 1,		# common
    key    => $key,		# 
    xylist => $key,		# was "key"
);
my $mat_from_key = ida_key_to_matrix(@opts);
my $inv_from_key = ida_key_to_matrix(@opts, 
				     "invert?" => 1,
				     "sharelist" => [0..2]);

# Invert the matrix the other way (manually)
my $top3 = $mat_from_key->copy_rows(0..2);
my $inv3 = $top3->invert;
#warn Dumper $inv_from_key;

# expect these to pass
ok(ref $mat_from_key, "create matrix from key?");
ok(ref $inv_from_key, "create inverse matrix from key?");
ok($inv_from_key->eq($inv3), "both old inverse paths agree?");

# Implement new inverse_cauchy_from_xys; it will take args similar to
# the ida_key_to_matrix call above. (for now)
ok(Math::FastGF2::Matrix->can("inverse_cauchy_from_xys"),
   "has method inverse_cauchy_from_xys?");

my $inv_cauchy;
ok($inv_cauchy = Math::FastGF2::Matrix
   ->inverse_cauchy_from_xys(@opts, "xvals" => [0..2]),
   "method inverse_cauchy_from_xys returns something?");

ok($inv_from_key->eq($inv_cauchy), "New routine gets same result?");

# how about transposing it?
#my $trans = $inv_cauchy->transpose;
#ok($inv_from_key->eq($trans), "New routine gets transposed result?");

# Final sanity check.. invert back using regular Gaussian elimination
my $inv_back = $inv_cauchy->copy->invert;
ok($top3->eq($inv_back), "Inverse of inverse (3x3)?");

print "Expected Inverse:\n";                   $inv_from_key->print;
print "Got Inverse:\n";                        $inv_cauchy->print;
print "Original (uninverted):\n";              $top3->print;
print "Inverse of Inverse Cauchy from Key:\n"; $inv_back->print;

# The following are expected to work... treat the key as a (4,4) scheme
@opts = (			# we can re-use to get inverse matrix
    quorum => 4,		# for ida_key_to_matrix
    size   => 4,
    shares => 4,
    sharelist => [0..3],	# for ida_key_to_matrix
    xvals => [0..3],		# for inverse_cauchy_from_xys
    width  => 1,
    key    => $key,
    xylist => $key,				
);
my $mat4_key = ida_key_to_matrix(@opts);
my $inv4_key = ida_key_to_matrix(@opts, 
				 "invert?" => 1,
				 "sharelist" => [0..3]);

ok(ref $mat4_key, "create matrix from key?");
ok(ref $inv4_key, "create inverse matrix from key?");

my $inv4_cauchy;
ok($inv4_cauchy = Math::FastGF2::Matrix
   ->inverse_cauchy_from_xys(@opts, "xvals" => [0..3]),
   "method inverse_cauchy_from_xys returns something?");

ok($inv4_key->eq($inv4_cauchy), "New routine gets same result?");

# Final sanity check..
my $inv4_back = $inv4_cauchy->copy->invert; # Gaussian
ok($mat4_key->eq($inv4_back), "Inverse of inverse (4x4)?");


print "Expected Inverse:\n"; $inv4_key->print;
print "Got Inverse:\n";      $inv4_cauchy->print;

print "Original (uninverted):\n"; $mat4_key->print;
print "Inverse of Inverse Cauchy from Key:\n"; $inv4_back->print;


# Benchmarking... compare manual inversion using old code with new
# inverse_cauchy_from_xys code. (comment out below lines to enable)

done_testing;
exit;


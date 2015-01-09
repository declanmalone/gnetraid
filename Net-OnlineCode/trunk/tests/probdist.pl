#!/usr/bin/perl -w

# Exercise Net::OnlineCode with different values for e, q and mblocks
# Prints out any changes to epsilon value, as well as the probability
# distribution table (in truncated form)

use lib '../lib';
use Net::OnlineCode;

print "Testing: PROBABILITY\n";

my ($test_eps,$test_q,$blocks);

for $test_eps (0.01) {
  for $test_q (3) {
    for $blocks (5000, 32_000, 100_000) {

      my $online = new
	Net::OnlineCode(
			  e => $test_eps,
			  q => $test_q,
			  mblocks => $blocks,
			  e_warning => 0,
			 );

      # read e value back in case it changed
      my $e = $online->get_e;
      my $q = $test_q;
      my $f = $online->get_f;

      print "e = $e; q = $q; blocks = $blocks; F = $f\n";

      my ($P) =
	eval {
	  local(*STDERR)=*STDOUT; 
	  Net::OnlineCode::_probability_distribution($blocks + 
						       $online->get_ablocks,
						       $e);
	};
      print $@ if $@;

      my $n_elements = scalar(@$P);
      $n_elements = 10 if $n_elements > 10;
      print join "\n", (@$P[0..$n_elements-1]);
      print "\n";

    }
  }
}


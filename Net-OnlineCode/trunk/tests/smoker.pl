#!/usr/bin/perl -w

# Try to find examples of when codec.pl fails

# Basically, just run it a bunch of times and save any seeds that don't
# produce the correct output


my $arg=20; # block size argument to codec.pl
my $expected = "Decoded text: 'The quick brown fox jumps over a lazy dogxxxxxxxxxxxxxxxxxxx'";

my $fails = 0;
my $trials = 100;
for (1..$trials) {

  $op = `./codec.pl $arg 2>/dev/null | perl -nle 'print if eof or /SEED/'`;

  my @lines = split "\n", $op;

  my $seed = shift @lines;
  chomp $seed; 
  $seed =~ s/.*SEED:\w+//;

  my $text = shift @lines; chomp $text;

  if ($text ne $expected) {
    ++$fails;
    print "$seed\n$text\n";
  }
}

print "Failed $fails/$trials times (" . ((100 * $fails / $trials)) . "%)\n";

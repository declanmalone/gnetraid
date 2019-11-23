#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Getopt::Std;
use YAML::XS qw(LoadFile);
use IDA::Validate;
use File::ExtAttr ':all';

my $usage = <<"EOT";
$0 - Do trial split of replicas, checking that sharefile hashes match

Usage:

 \$ cd replica_dir
 \$ $0 [worker options] [report options] validation_list.yaml

Worker options:

 -n  number of workers in work group (ie, stride)
 -m  offset within work group (check n'th + m entries)
 -s  skip this many entries at the start

Suitable for running n processes in parallel. Each should have a
different m value in the range:

 0 <= m < n

Report options:

 -p previous

If the YAML file has an old_status array, will look in it for a key
matching {\$previous} and if found, will use those cached values
instead of re-scanning files.

EOT

# getopts
our ($opt_h, $opt_m, $opt_n,$opt_s,$opt_p) = (0,-1,-1,undef,undef);
getopts("m:n:s:p:h");
die $usage if $opt_h;

# Check options

my $previous = $opt_p;

# If worker options not given, assume single process processing all
# the items (from the zero'th)
if ($opt_n == -1 and $opt_m == -1) {
    ($opt_n, $opt_m) = (1,0);
}

# We allow both m and n to be undefined, but not just one
if (($opt_n == -1) || ($opt_m == -1)) {
    die "Must define both n and m, or define neither\n";
}

die "n must be 1 or greater\n" unless $opt_n >= 1;
die "m must be in the range 0..n-1 (0.." . ($opt_n - 1) . ")\n"
    unless $opt_m >= 0 and $opt_m < $opt_n;

# Check or set up skip option
if (defined $opt_s) {
    die "Invalid skip (-s) value '$opt_s'\n" unless $opt_s =~ /^\d+$/;
    die "Skip value mod n must equal m\n" unless $opt_m == $opt_s % $opt_n;
} else {
    $opt_s = $opt_m;
}


# Remaining options
die "Missing YAML file argument\n" if @ARGV == 0;

my ($yaml_file) = shift @ARGV;
warn "Extra arguments after '$yaml_file' ignored\n" if @ARGV;

die "Failed to load YAML file\n" unless my $yaml = LoadFile($yaml_file);

my ($k,$n,$w,$shares,$silo_names) =
    map {$yaml->{$_}} qw(k n w shares silo_names);

warn "k is $k, n is $n, w is $w\n";

my $nshares = scalar(@$shares);
warn "YAML file has $nshares replicas\n";

# If the YAML file has a 'old_status' array we use the values stashed
# in there to skip the expensive ida_validate operation.
#
# If it doesn't have that section, we create it
my $old_status;
if (exists $yaml->{old_status}) {
    $old_status = $yaml->{old_status};
    die "YAML has old_status, but you didn't give -p option\n"
	unless defined $previous;
} else {
    # old_status is an array of hashes:
    # my (@old_values) = @{ $old_status->[$row]->{$previous} }
    $old_status = [ map {{}} (0 .. $nshares - 1) ];
}

# Make sure that we flush output after every line
$| = 1;

# an all-correct result ("1" for all n shares listed)
my $all_ok =  "1" x $n;
my $no_file = "-" x $n;
for (my $i = $opt_s; $i < $nshares; $i += $opt_n) {

    # Unpack row contents
    my ($replica,$sharefile_size, @tests) = @{$shares->[$i]};
    if (0) {
	warn "Replica name $replica\n";
	warn "Sharefile size $sharefile_size\n";
	warn "Got " . @tests . " tests\n";
    }

    # I have to flatten @tests (was a list of lists in YAML)
    @tests = map { @$_ } @tests;
    warn "Flattened test list has " . @tests . " elements\n" if 0;

    my $infile = "./$replica";

    # Three options with appropriate status output
    # 1. File doesn't exist in current tree ("----")
    # 2. Split succeeded                    ("1111")
    # 3. Split failed                       ("0000", "1010", etc.)

    my $res;
    my $replica_size = 0;
    my $replica_hash = '';
    if (! -f $infile) {
	$res = $no_file;
    } else {

	$replica_size = (stat $infile)[7];
	$replica_hash = getfattr($infile, "shatag.sha256");

	# Check for previously cached results
	my ($old_size, $old_hash, @res);
	if (defined($previous) and exists $old_status->[$i]->{$previous}) {
	    warn "Using cached values for $previous, row $i\n";
	    ($old_size, $old_hash, $res) = 
		@{ $old_status->[$i]->{$previous} };
	    die "Previous size $old_size != $replica_size\n"
		if $old_size != $replica_size;
	    die "Previous hash $old_hash ne $replica_hash\n"
		if $old_hash ne $replica_hash;
	} else {
	    warn "Calling ida_validate for row $i\n";
	    @res = ida_validate(infile => $infile, k => $k, w => $w,
				tests => [@tests]);
	    $res = join "", @res;
	}

	# This is where we will normally report, suppressing reporting
	# for files that don't exist
	print join "\0", ($i, $replica_size, $replica_hash, $res, "\n");

    }

    # Uncomment to report all files checked, even if they don't exist:
    # print join "\0", ($i, $replica_size, $replica_hash, $res, "\n");
}

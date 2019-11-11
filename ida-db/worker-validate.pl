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
 \$ $0 [worker options] validation_list.yaml

Worker options:

 -n  number of workers in work group (ie, stride)
 -m  offset within work group

Manually run n processes, each with a different m value in the range:

 0 <= m < n

EOT

# getopts
our ($opt_h, $opt_m, $opt_n) = (0,-1,-1);
getopts("m:n:h");
die $usage if $opt_h;

# Check options

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

# an all-correct result ("1" for all n shares listed)
my $all_ok =  "1" x $n;
my $no_file = "-" x $n;
for (my $i = $opt_m; $i < $nshares; $i += $opt_n) {

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
	my @res = ida_validate(infile => $infile, k => $k, w => $w,
			       tests => [@tests]);
	$res = join "", @res;

	# This is where we will normally report, suppressing reporting
	# for files that don't exist
    }

    # for now, report all files checked, even if they don't exist
    print join "\0", ($i, $replica_size, $replica_hash, $res, "\n");
}

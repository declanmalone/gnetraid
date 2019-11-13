#!/usr/bin/env perl

use strict;
use warnings;

use YAML::XS qw(LoadFile);
use IO::All;

# Use the same file names that I used in group-validate, but with disk
# names matching those in the YAML file prepended (I renamed the
# report file name manually after validation)
sub report_name {
    # "silo name" is a bit of a misnomer... I'm naming them after
    # the share silos that I copied, but actual replicas are on a
    # different disk on the same machine.
    my $silo_name = shift;
    my $worker = shift;
    return "$silo_name-validate-report-${worker}.log"
}

# worker numbers: matching how I ran group-validate.sh
my @workers = (0..3);

# YAML filename matches that in merge-xform-row-data.pl
my $yaml = LoadFile("merged-share-data.yaml");

my $replicas = @{$yaml->{shares}};
sub empty_hash { { ok => 0, errs => 0 } };
my @coverage = map {empty_hash} (1.. $replicas); 

my ($total_errors, $report_errors) = (0,0);
for my $silo (@{$yaml->{silo_names}}) {
    for my $worker (@workers) {
	$report_errors = 0;
	my $fn = report_name($silo, $worker);
	unless (-f "$fn") {
	    warn "Report '$fn' missing\n";
	    next;
	}

	my $report = io->file($fn)->slurp;
	my @lines = split "\n", $report;
	for my $line (@lines) {
	    my ($row,$replica_size,$replica_hash,$status,$junk)
		= split "\0", $line;
	    my $replica_name = $yaml->{shares}->[$row]->[0];
	    if ($status ne "1111") {
		warn "$silo: $replica_name: share mismatch (status $status)\n";
		$coverage[$row]->{errs}++;
		$report_errors++;
	    } else {
		$coverage[$row]->{ok}++;
	    }
	}
	if ($report_errors) {
	    warn "$silo: worker $worker reported $report_errors errors\n";
	    $total_errors += $report_errors;
	}
    }
}

# Now check coverage
$report_errors = 0;		# different report, same variable
for my $row (0.. $replicas -1) {
    # see if an error with one replica was corrected elsewhere
    my $replica_name = $yaml->{shares}->[$row]->[0];
    if ($coverage[$row]->{errs}) {
	if ($coverage[$row]->{ok}) {
	    warn "Another silo has a good copy of broken replica $replica_name\n";
	}
    }
    unless ($coverage[$row]->{ok}) {
	++$report_errors;
	warn "Not covered: $replica_name\n";
    }
}

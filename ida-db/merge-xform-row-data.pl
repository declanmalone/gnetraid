#!/usr/bin/env perl

use strict;
use warnings;

# It appears that if I don't use IO::All with the -encoding option,
# the YAML output files have mojibake in them. I comment on various
# attempts to get it working below...

# This doesn't seems to have any effect on proper UTF-8 in files
use v5.20;

# It doesn't seem to matter if we include YAML::XS before or after the
# IO::All include below
use YAML::XS qw(DumpFile);

# Attempts at getting UTF-8 YAML output files:

#use IO::All;                     # doesn't work: get mojibake
use IO::All -encoding => "UTF-8"; # works
#use open qw(:utf8);              # doesn't work: get mojibake

sub silo_to_infile_name {
    my $silo = shift;
    "$silo-xform-rows.txt";
}
    
sub open_files {
    my @handles;
    my @silos = @_;

    foreach my $silo (@silos) {
	my $fn = silo_to_infile_name($silo);
	open my $fh, "<", $fn or die "open problem for $silo: $!\n";
	push @handles, $fh;
    }
    \@handles;
}

my @silo_names = qw/Cathy Roisin Megumi Midori/;
my $yaml_ref = {
    k =>  3,
    n =>  4,
    w =>  1,
    silo_names => \@silo_names,

    shares => [],		# no need to sort/index files
    dirs   => {},		# 
};


sub merge_files {
    my $yaml = shift;		# ref to YAML structure
    my $of   = shift;
    # my $fh   = shift;		# ref to list of file handles

    open my $oh, ">", $of or die "create problem for $of: $!\n";

    # Might as well slurp the input files---they're not huge
    my @in_lines;
    my $got_lines = undef;
    foreach my $silo (@silo_names) {
	my $fn = silo_to_infile_name($silo);
	my @lines = split "\n", (io->file($fn)->slurp);
	die "Slurped 0 lines from $fn ($!)\n" unless @lines;

	if (defined $got_lines) {
	    die "Unequal number of lines across files\n"
		unless $got_lines == @lines;
	} else {
	    $got_lines = @lines;
	}

	push @in_lines, \@lines;
    }

    for my $i (0 .. $got_lines - 1) {
	my $silos = @silo_names;

	my (@xform_rows, @hashes, @fields);

	@fields = split "\0", shift @{$in_lines[0]};
	if (0) {
	    warn "Silo: $silo_names[0]\n";
	    warn "File: $fields[0]\n";
	    warn "Size: $fields[1]\n";
	    warn "Hash: $fields[2]\n";
	    warn "Xrow: $fields[3]\n";
	}
	if ('/' eq substr $fields[0], -1, 1) {
	    # ignore directories, but consume from other lists
	    shift @{$in_lines[$_]} for (1..$silos - 1);
	    next;
	}
	
	my ($file,$size,$hash,$xrow) = @fields[0..3];
	die "File $file didn't end with .sf" unless $file =~ s/\.sf$//;
	my @rec = ( $file, $size, [ $xrow, $hash ] );
	my ($file1, $size1) = ($file,$size);

	for my $j (1..$silos - 1) {
	    @fields = split "\0", shift @{$in_lines[$j]};
	    ($file,$size,$hash,$xrow) = @fields[0..3];
	    die "File $file didn't end with .sf\n" if !($file =~ s/\.sf$//);
	    die "Filename mismatch $file1 ne $file\n" if $file1 ne $file;
	    die "Share size mismatch $size1 != $size\n" if $size1 != $size;
	    push @rec, [$xrow, $hash];
	}

	push @{$yaml->{shares}}, \@rec;
    }
    # YAML output doesn't seem to preserve Unicode characters if I
    # just use DumpFile.
    # First try: use IO::All -encoding at top of script
    DumpFile($of,$yaml);
}

merge_files($yaml_ref, "merged-share-data.yaml");

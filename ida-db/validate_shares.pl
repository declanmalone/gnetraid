#!/usr/bin/env perl

use strict;
use warnings;

# Take the output of merge-xform-row-data (a YAML file) and check
# local replicas with matching file names to see if splitting them
# matches the stored hashes.

#
# Designed to be run on multiple cores at once
#
# Each instance checks every n'th + m input line, where n is the
# number of processes and m is the worker number 0 <= m < n
#
# I'm not sure if disk I/O or CPU power is going to be the main
# bottleneck, but it stands to reason that using multiple cores should
# be faster than single core because we're alternating between reading
# from disk and doing some compute work.

use FindBin qw($Bin);

use lib "$Bin/lib";

# refactor code that was in test_split.pl
use IDA::Validate;


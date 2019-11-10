#!/usr/bin/env perl

use FindBin '$Bin';
use lib "$Bin";

# How should I be running collectors remotely?

# Do I want this? Maybe for Mojolicious::Command, remote file access, etc.?
# It would also let us do asynchronous queries using UserAgent.
# The downside is having to set up servers on all remote hosts.
use Mojo::Base 'Mojolicious';

# Or use one of these instead for RPC?
use IPC::PerlSSH;
use GRID::Machine;

# Only GRID::Machine seems to support asynchronous calls, though it
# seems to be better suited to long-running remote jobs since it calls
# fork.

# Perhaps if I just use:
use Mojo::UserAgent;

# This only gives the ability to make web-centric calls (http, https,
# websockets) run asynchronously. Not ssh, so we'd need to run servers
# on the other end.

# use nothing;
#
# Instead of using a form of fine-grained remote RPC (making a
# separate request for each remote file or directory), I could instead
# write a small script that should be run on the remote end.
#
# I could use one of the IPC mechanisms above (particularly
# GRID::Machine) to fire up the script, but it's easier to just ssh
# manually then scp the resulting file back.


# Later on, when I'm validating the existing share structures, I will
# want to do an RPC that instructs the remote site to do an in-memory
# split of a file, creating a hash of particular output shares.
#
# Again, that could be handled by shipping over a script and a
# configuration file telling it what needs to be done, or we could use
# GRID::Machine to do it on a file-by-file bases.
#

my $usage = <<"EOT";
lmdbtfy - let me database that for you

Build a unified database tracking IDA schemes and corresponding replicas

EOT

# Makefile-like organisation of tasks
my %task_depends = (
);

# General outline of tasks
#
# "build share database"
#
# I have shasums files that are the most convenient way to capture the
# directory/file layout.
#
# This also includes shasums for each share file
#
# It doesn't include share header information (IDA parameters)
#
# Neither does it include any data about the original replicas (sums,
# timestamps, ownership, permissions, etc.). Only the first two of
# these are necessary.
#
# I can have this as a separate task, or I can include the next task
# too.
#
# Part of the job in this task will be to create unique share IDs.
#
# Have to distinguish between a single replica ID and several share
# IDs.
#
# (replica_id, scheme_id, share_id)  -- share_id unique within a scheme
#
# eg, listing only first IDA scheme that a replica is stored in:
#
# (1,1,1)  replica 1, first share
# (1,1,2)  :
# (1,1,3)  :
# (1,1,4)  replica 1, last share
# (2,1,5)  replica 2, first share
# (2,1,6)  :
#
# I think that we need an ordering of silos, too. 
#
# (scheme_id, row_index, store_spec)
#
# (1, 0, "Janice")
# (1, 1, "Megumi")
#
# By sorting the share_id values in the above table numerically, we
# should be able to map (implicit) ordering onto the correct table
# row:
#
# (1,1,1)  replica 1, first share x (1, 0, "Janice") -> row_index 0
#
# This implicit ordering will also allow us to increase the n value
# later without messing up the existing row ordering, eg:
#
# (1,1,101)  replica 1, first new share
# (2,1,102)  replica 2, first new share
# (3,1,103)  replica 3, first new share
# (25,1,125) replica 25, first new share


# "collect IDA parameters"
#
# (share_id, share_hash, share_xform_row)
#
# We have unique share ids corresponding to a single share file. This
# stores the two most important attributes. We could also store the
# size of the sharefile, but it's not as important, except for
# checking.
#
# This has to be done remotely, with results collected and collated
# locally.
#
# The database has to be updated, adding the IDA parameters for each
# silo, sharefile pair.
#
# 

# A simple database for IDA schemes

## Background

The main way that I use IDA is for storing backups of my media
collection (CD and DVD rips, as well as things recorded from TV). Up
until now, I've kept both a set of shares, and copies/backups of
replicas for safety's sake, and to have replicas for
watching/listening to. The collection of shares is well organised,
with matching directory structures storing shares distributed over
several disks. The collection of replicas is not at all well
organised, though. Due to the size of the collection, I've had to
split up the collection over several disks.

I do have a way of organising replicas to some degree, however, by
using a full-disk cataloguing script that computes hashes for both
files and directories.

I don't have an equivalent database (or report) of shares, apart from
the share file names and hashes that appear in the full-disk
catalogue.

The way I set up the IDA scheme, I was very much interested in using
it for distributed storage. For example, each share includes only the
single matrix row of the IDA transform matrix corresponding to that
share. I don't store any other information in the share headers such
as:

* original filename
* any other matrix information
* hash of the original file
* mtime or similar information about the original file

This has worked fine for me when it comes to having an IDA-based
backup, but it's kind of limited and hard to manage files if:

* I want to delete extra replicas
* I want to determine if a particular file is the same as one
  in the IDA scheme
* I want to move the collection to a different IDA scheme (with a
  different k value)

On this last point, the most effective/efficient way of recreating a
new IDA scheme is to identify where the existing replicas are and have
those machines generate the new IDA shares and distribute them to the
new storage silos. This is more efficient than combining the existing
shares and then distributing new shares, since this involves:

* one machine collecting old_k shares (at a cost of copying the full
  file over the network, or perhaps (old_k - 1)/k if that machine has
  one share)

* that machine distributing new_k quorum shares plus a number of
  redundant shares

The cost here is basically going to be at least twice the size of the
collection.

By comparison, if we first identify where the replicas are, we
basically halve the network cost since we don't have to gather shares
at all.

## Validation of existing IDA collection

I never created a master list of shares when I set up my existing IDA
scheme. As I mentioned, I wanted a distributed system, so the idea of
a central database didn't appeal to me.

My first goal for this database, then, will be to gather the matrix
parameters from each share on each drive. I also have hashes stored
for each of the share files. These are stored locally on the disk (in
extended attributes for each share file) and in my full-disk
catalogue. While I don't need to collect the hashes again, I will do
so because it's easy to look up at the time of scanning, and because
it means I don't have to consult the unweildy full-disk catalogues
(which are just compressed lists of all files/dirs on a given disk).

I mentioned that my tracking of replicas was not well organised. While
this is true (with the full collection being spread over various
disks), I can still identify where the parts of the collection (the
replicas) are stored.

With that list, I need to check for coverage, first (whether I have a
replica for each split file), and then check for correctness.

As I mentioned earlier, when talking about creating a new IDA scheme,
it's more efficient to work with replicas than collecting shares and
putting them together. When validating, it's the same thing:

* the machine with the replica is told what the IDA parameters for the
  corresponding share files were

* using those parameters, it recreates the same split command

* instead of writing shares to disk, it pipes them through the sha
  hash algorithm

* I already know the hashes for the existing sharefiles, so I can just
  compare that with the hashes generated above

## Alternative way of generating IDA transform matrix

I mention a few ways of managing IDA "keys" in the Crypt::IDA package.
My existing scheme generated a random "key", then used it to generate
the matrix and threw away the key afterwards. This is fine when
distributing shares, since I also stored the matrix row corresponding
to each share in the share file's header.

My database will have to support that mode of operation.

However, since I'm putting together a centralised database, it makes
more sense to simply store the "key" parameter for any new,
centralised IDA scheme that I set up. The "key" can be used to
regenerate the same matrix row for a given (numbered) share. Even
though I will then have a centralised database, I will continue to
store the same information in each share header in order to avoid
having a single point of failure (failure of the central database)
preventing me from recovering files from the IDA scheme later.

## Mapping replicas to shares

I assume a parallel directory layout between shares and replicas. The
only exception is that while an IDA share scheme can't span several
disks (the entire set of files must be small enough to fit into a
silo), the replica collection may be split up over several disks in
order to make it fit the available space. For example, I have
directories like:

* `/video/tv` on disk A
* `/video/movies` on disk B (with subdirectories A-H)
* `/video/movies` on disk C (with subdirectories I-Z)
* `/music/compilation` on disk D
* `/music/artist_albums` on disk E
* etc.

Taken together, there should be a full set of files that should
correspond exactly to the layout of the shares on the share storage
silos, with no overlaps or omissions.

I'll have two different database tables (or sets of related tables):

* for storing file names, file sizes and hashes of the replica files
  (along with which disk to find them on)

* File-specific IDA parameters, indexed on the hash and file size of
  the replica

The first of these should match up with the data in my full-disk
catalogue. In fact, it should end up being a proper subset of that
data. I can use this fact to extract just the parallel directory
structure mentioned above (the main, best-organised replica
collection) at first. I could combine data all the replica subsets
into one database/report, but equally I could keep separate reports,
each tracking a particular disk's contribution to the full, logical
collection.

From the point of view of just validating the shares and making sure
that they agree with the replicas, it's easier to focus on the main
replicas above, although if I generate a cross-reference telling me
where *all* replicas of a particular file are, then I could write a
distributed program (using something like GRID::Machine, Minion or
whatever) to spread the cost of validating a replica across more
machines.

Later on, when I come to creating a new share system (with higher k,
and more storage nodes) I definitely do want to have the option of
doing this kind of heavily-distributed split queue. But for now, I'll
just distribute the processing based on where the "main" replica files
above happen to reside. Although if some disks have a lot more files
than others, I might go looking for other subsets of replicas that are
stored elsewhere and bring that machine into the fold.

I don't want to expand the first set of tables to do full-disk
indexing, though. I don't mind the idea of a "distinguished" logical
replica that may be spread over several disks, so long as its
directory and file naming structure exactly maps to the shares. But in
general, I don't want to be able to track where all replicas of a
given IDA file are if they're outside of the "distinguished"
directories.

The reason for this is that while I probably do have lots of
"uncontrolled" replicas, once I've set up a new IDA scheme, I'll have
enough redundancy built into it that I should be able to delete the
majority of those replicas. In fact, I may even delete the
"distinguished" replicas as well. Thus, there's no point in keeping
the database up to date and trying to track every single copy or
deletion.

Of course, since I do want a highly-distributed split operation when
creating the new IDA scheme, I will want to identify as many replicas
as I can. In this way, I can have a multi-sender model, with the
processing burden shared by many different nodes, and with the minimum
amount of trans-shipment of created shares. For example, with a new
(6,8) scheme, if there are 4 machines that have a replica for a given
file, then each of them can create two shares, saving one locally and
sending the other to a silo that doesn't have a copy of that replica.

I /will/ need to consult the full-disk catalogues to determine the
work plan for each file, but I can live with the overheads in this
case if it saves a lot of CPU time and network bandwidth.



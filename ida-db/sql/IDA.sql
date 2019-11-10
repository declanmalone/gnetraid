-- sql

create table replicas (
  replica_id    INTEGER PRIMARY KEY, -- represents a file that is/will be split
  file_hash     BLOB,		     -- binary representation of checksum
  file_size     INTEGER
);

-- create an index on the above, searching on sum + size
--
-- do it *after* populating the database, though, for speed

create table ida_schemes (
  scheme_id     INTEGER PRIMARY KEY,
  scheme_name   TEXT,
  k             INTEGER,
  w             INTEGER,	-- field width (in bits)
  ida_key       BLOB		-- optional if share_xform explicitly stored
);

create table ida_silos (
  scheme_id     INTEGER,
  silo_ordinal  INTEGER,	-- position within IDA scheme (ordinal)
  machine       TEXT,
  root          TEXT  
);

-- storing file path/name below is wasteful: should be handled better
create table ida_shares
  share_id      INTEGER PRIMARY KEY, -- uniquely map to a sharefile somewhere
  share_hash    BLOB,
  share_xform   BLOB,		-- optional if ida_key and silo_id stored
  share_path    TEXT,
  share_name    TEXT		-- full name of share, including suffix (eg, .sf)
);

-- attempt to shift dir/file names out of ida_shares. Assume that we
-- have a parallel directory structure between replicas and shares,
-- even if the replica collection can be scattered over various disks.
-- Call this parallel collection of replicas the "canonical" replica
-- collection.

-- overview of how the replica collection is split over disks, eg,
-- a (3,4) scheme has a fragment of /videos/tv (=dir) stored at
-- /mnt/Janice (root) on euclid (machine).
--
-- other machines may also have (non-overlapping) fragments of the
-- /videos/tv replica collection, too. Together, all dirs mentioned
-- below should cover the complete replica collection and the parallel
-- share collection.
create table canonical_replica_fragments (
  fragment_id   INTEGER,     -- unique across all schemes, fragments
  scheme_id     INTEGER,     -- a particular IDA scheme (multiples OK)
  machine       TEXT,
  fragment_root TEXT,
  fragment_dir  TEXT,
  -- Later on, want to deal with cases like:
  --
  -- * wanting to validate replica fragments against shares
  -- * wanting to create a new share system (treat fragments as staging areas)
  -- * wanting to delete replicas, after new shares have been created
  --
  -- We'll still keep these "fragment" records here but update our
  -- all-purpose "status" field to track what's going on:
  status        INTEGER		-- should probably make per-scheme!
);

-- with the high-level scattering of the canonical replica collection
-- dealt with above, we can drill down into the fragment_dir
--
-- Even if we've deleted the canonical replica collection, we want our
-- database to keep a record of its structure, as set out in these two
-- tables.
create table canonical_mapping (
  fragment_id   INTEGER,
  scheme_id     INTEGER,	-- thinking of deleting...
  replica_subdir TEXT,
  hash_id       INTEGER,
  scheme_id     INTEGER,
  silo_id       INTEGER,
  share_id      INTEGER
  
)



create table auxiliary_mapping (
);

#!perl -T

use Test::More tests => 14;

BEGIN {
  use_ok('Media::RAID::Store',qw(new_drive_store new_fixed_store))
    || print "Bail out!\n";
  use_ok('Media::RAID') || print "Bail out!\n";

  # File::Temp isn't strictly necessary for using the module, but I'll
  # bail out on testing if it's not available.
  use_ok('File::Temp', qw(tempfile tempdir)) || print "Bail out!";

}

diag("Testing Media::RAID constructors");

#
# constructor tests
#

my ($raid_1,$raid_2,$rc);
my $obj_type = 'Media::RAID';

# set up with combination of new/add_scheme

$raid_1 = Media::RAID->new
  (
   local_mount => "/mnt",	# set to something other than default
  );

# some more variables to keep track of directories
my ($working_1, $mroot_1, $mpath_1, $sroot_1);
my (@spaths_1);

SKIP: {
  ok (defined($raid_1), "Media::RAID->new failed");

  skip "Creating raid_1 with new failed", 10 unless defined($raid_1);

  # check correct type

  ok (ref($raid_1) eq $obj_type, "new didn't return '$obj_type'");

  # check that options are correctly set (including default options)

  ok ($raid_1->option('local_mount') eq "/mnt",
      "new didn't correctly set local_mount option (passed in)");

  ok ($raid_1->option('clobber') == 1,
      "new didn't correctly set clobber option (default)");

  ok ($raid_1->option('verbosity') == 0,
      "new didn't correctly set verbosity option (default)");

  ok ($raid_1->option('dryrun') == 0,
      "new didn't correctly set dryrun option (default)");

  # Now add a simple scheme with minimal arguments. We need some
  # temporary directories before we can use this

  $working_1 = File::Temp->newdir;
  $mroot_1   = File::Temp->newdir;
  $sroot_1   = File::Temp->newdir;
  $mpath_1   = "/master_files";
  @spaths_1  = ('/One','/Two','/Three');

  ok (
      $rc = $raid_1->add_scheme
      (
       "raid_1",
       nshares => 3, quorum => 2, width => 1,
       master_stores =>
       {
	master => new_fixed_store($mroot_1, $mpath_1),
       },
       share_stores =>
       [
	map { new_fixed_store($sroot_1, $spaths_1[$_]) } (0..2)
       ],
       working_dir => $working_1,
      ),
      "failed to add scheme raid_1");

  # skip some more tests if adding the scheme failed

  skip "raid_1->add_scheme failed", 4 unless $rc;

  my @names;
  ok (
      # we should get back exactly one scheme name; this test
      # conflates a number of things that could possibly go wrong, but
      # it's not worth testing each individually
      ((@names = $raid_1->scheme_names) and (@names == 1) and
      ($names[0] eq "raid_1")),
      "anomalous scheme_names result");

  my (@mstores,@rstores);

  ok (
      ((@names = $raid_1->master_names("raid_1")) and (@names == 1) and
       ($names[0] eq "master")),
      "anomalous master_names result"
     );

  my $master_path;
  ok (
      ($master_path = $raid_1->master_store("raid_1","master")),
      "Failed to extract master_path('raid_1','master')"
     );

  ok ($master_path->as_path eq "$mroot_1/master_files",
      "Extracted master store path not as expected");

}


# This next block tries to raise as many errors in new or add_scheme
# as possible
FAIL: {

  # make carps/warnings become fatal during this block so we can trap
  # them eval and $@
  local $SIG{__WARN__} = sub { die $_[0] };



}

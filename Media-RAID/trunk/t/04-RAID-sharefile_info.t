#!perl -T

use strict;
use warnings;

use Test::More tests => 71;

BEGIN {
  use_ok('Media::RAID::Store',qw(new_drive_store new_fixed_store))
    || print "Bail out!\n";
  use_ok('Media::RAID') || print "Bail out!\n";

  # File::Temp isn't strictly necessary for using the module, but I'll
  # bail out on testing if it's not available.
  use_ok('File::Temp', qw(tempfile tempdir)) || print "Bail out!";

  # Will use Testfiles.pm (in this directory) to give us schemes/files
  # to work with. Consult that file for details.
  my $progdir = __FILE__;
  $progdir =~ s|^(.*)/.*|$1|;

  unshift @INC, $progdir;	# prepend to @INC so that we always
                                # use our Testfiles.pm over any other
  use_ok("Testfiles") || print "Bail out!\n";

}

diag("Testing Media::RAID::sharefile_info");

# As well as testing sharefile_info, we also do some extra testing on
# lookup and sharefile_names that needed a more complex set of
# schemes, such as the ones set up in Testfiles.pm

my ($raid,$rc);
my $obj_type = 'Media::RAID';

# set up with combination of new/add_scheme

$raid = Media::RAID->new;
ok(ref($raid) eq $obj_type, "Constructor failed") || BAIL_OUT;

my $tmpdir = File::Temp->newdir;

# The Testfiles module dies if it encounters errors. We wrap calls to
# its functions in eval statements so that if it does die, we can
# provide useful exit messages here before bailing out.
my $errstring;
eval { tf_extract_file_tree($tmpdir,$tf_complete_tree) };

# quick check that at least some files were extracted
my $gozu_file = "$tmpdir/master_drives/drive_1/video/movies/Gozu/gozu.mpeg";
ok (-f $gozu_file,
    "Couldn't find gozu.mpeg after file extraction") || BAIL_OUT;

my $drwhofile="$tmpdir/master_drives/drive_2/video/tv/Doctor Who" .
  "/2009/S04E15.avi";
ok (-f $drwhofile,
    "Couldn't find S04E15.avi after file extraction") || BAIL_OUT;

# add the schemes
$errstring=$@;
ok ($errstring eq "", "Failed to extract test files") || BAIL_OUT ($errstring);

eval { tf_regular_scheme($raid,$tmpdir) };
$errstring=$@;
ok ($errstring eq "", "Failed to add regular scheme") || BAIL_OUT ($errstring);

eval { tf_extra_scheme($raid,$tmpdir) };
$errstring=$@;
ok ($errstring eq "", "Failed to add extra scheme") || BAIL_OUT ($errstring);

#
# We didn't do any testing on lookup involving files that exist in
# multiple schemes yet. Do that testing now.
#
my $lhash;
# files in the movies dir are backed up to two schemes
$lhash = $raid->lookup($gozu_file);
ok (defined($lhash), "lookup didn't find any gozu.mpeg") || BAIL_OUT;
ok (exists($lhash->{regular}),"lookup didn't find file in regular scheme");
ok (exists($lhash->{extra}),"lookup didn't find file in extra scheme");
is ((keys %$lhash),2,"wrong number of schemes reported");

is($lhash->{regular}->{archive},"movies", "wrong archive for gozu.mpeg");
is($lhash->{extra}->{archive},"movies2", "wrong archive for gozu.mpeg");

my $lgozu = $lhash;		# save gozu lookup hash

# files in the tv dir are only backed up in the regular scheme
$lhash = $raid->lookup($drwhofile);
ok (defined($lhash), "lookup didn't find any S04E15.avi") || BAIL_OUT;
ok (exists($lhash->{regular}),"lookup didn't find file in regular scheme");
ok (!exists($lhash->{extra}),"lookup DID find file in extra scheme");
is ((keys %$lhash),1,"wrong number of schemes reported");

is($lhash->{regular}->{archive},"tv", "wrong archive for S04E15.avi");

my $ldrwho = $lhash;		# save Dr. Who lookup hash

# more tests to ensure that lookup doesn't return results for files
# not in an archive.

$lhash = $raid->lookup("$tmpdir/master_drives/drive_1/checksums");
is ($lhash,undef, "checksums FOUND by lookup");

$lhash = $raid->lookup("$tmpdir/master_drives/drive_1/video");
is ($lhash,undef, "/video FOUND by lookup");

# make sure a simple prefix of an archive dirname doesn't fool us
$lhash = $raid->lookup("$tmpdir/master_drives/drive_1/video/moviesteward");
is ($lhash,undef, "/video/moviesteward FOUND by lookup");

$lhash = $raid->lookup
  ("$tmpdir/master_drives/drive_1/video/tv/Doctor Who/2009/S04E15.avi");
is ($lhash,undef, "backup S04E15.avi FOUND by lookup");


#
# Some more testing of sharefile_names that we didn't do in the lookup
# tests.
#

my @sharefile_names;

@sharefile_names = $raid->sharefile_names($gozu_file,"regular",$lgozu);
ok (@sharefile_names == 3, "Wrong number of shares for gozu.mpeg");

@sharefile_names = $raid->sharefile_names($gozu_file,"extra",$lgozu);
ok (@sharefile_names == 8, "Wrong number of shares for gozu.mpeg");

@sharefile_names = $raid->sharefile_names($drwhofile,undef,$ldrwho);
ok (@sharefile_names == 3, "Wrong number of shares for S04E15.avi");

is ($sharefile_names[0],
    "$tmpdir/shares/regular/0/video/tv/Doctor Who/2009/S04E15.avi.sf",
    "Wrong name for share of S04E15.avi");

# expect call to fail for gozu.mpeg if we don't specify a scheme
FAIL: {
  local $SIG{__WARN__} = sub { die $_[0] };

  # it seems that if we die in the sub below, @sharefile_names won't
  # be updated from its previous value, so blank it now. This
  # shouldn't be a problem in practice since users aren't generally
  # going to be using a sighandler and eval like we do here.
  @sharefile_names = ();
  eval { @sharefile_names = $raid->sharefile_names($gozu_file,undef,$lgozu) };

  ok ($@ ne "", "ambiguous scheme should warn us");
  ok (@sharefile_names == 0, "ambiguous scheme shouldn't return list");

  # should also fail if asked to look up shares for unmanaged files
  eval {
    @sharefile_names =
      $raid->sharefile_names("$tmpdir/master_drives/drive_1/checksums") };
  ok ($@ ne "", "unmanaged file should raise warning");
  ok (@sharefile_names == 0, "unmanaged file shouldn't return share names");
}

#
# Now, the testing of sharefile_info proper
#

# Ensure the shares we're going to test for actually exist, so that we
# can sanity-check any later failures along those lines.
map {
  ok(-f "$tmpdir/shares/regular/$_/video/movies/Gozu/gozu.mpeg.sf",
    "Failed sanity check: gozu.mpeg share $_ missing (check Testfiles.pm)")
} (0..2);

my $info = undef;
my $nsharefiles = 0;
my @goodsharefiles =();

SKIP: {

  $info = $raid->sharefile_info($gozu_file,"regular",$lgozu);

  is(ref($info), "HASH", "no sharefile_info for gozu.mpeg") ||
    skip "no tests on undefined return value", 13;

  is ($info->{nshares}, 3, "wrong number of shares reported");
  is ($info->{quorum} , 2, "wrong quorum value reported");

  eq_array(@{$info->{file_names}},
	   $raid->sharefile_names($gozu_file,"regular",$lgozu),
	   "filenames differ between sharefile_names and sharefile_info");

  is ($info->{file_length},(stat $gozu_file)[7],
      "wrong file length reported");

  ok ($info->{viable},  "gozu.mpeg reported as NOT viable");
  ok ($info->{perfect}, "gozu.mpeg reported as NOT perfect");
  is (ref($info->{headers}),"ARRAY", "gozu.mpeg headers not right type");

  map {
    my $not_ok=0;
    # this is a bit paranoid, but it stops us deleting a wrong file by
    # mistake
    ok (-f $info->{file_names}->[$_], "! -f returned gozu.mpeg share $_")
      or ++$not_ok;
    my $match = $info->{file_names}->[$_];
    $match =~ m|^($tmpdir/shares/regular/$_/video/movies/Gozu/gozu.mpeg.sf)|;
    $match = $1;		# also untaints so we can later unlink
    is ($match,
	"$tmpdir/shares/regular/$_/video/movies/Gozu/gozu.mpeg.sf",
	"Wrong name for sharefile $_")
      or ++$not_ok;
    push @goodsharefiles, $match unless $not_ok;
  } (0..2);
}

#
# Now delete sharefiles and see what happens. I will skip one or more
# of the following blocks if the above tests failed to execute or
# found fewer than 3 sharefiles.
#

SKIP: {

  skip "Expected 3 valid shares here", 10 if @goodsharefiles < 3;

  # something is seriously wrong if we can't unlink a tmp file
  BAIL_OUT unless unlink shift @goodsharefiles;
  --$nsharefiles;

  # now that we've delete a file, our cached lookup results are
  # invalid and we have to look them up again.
  $lgozu = $raid->lookup($gozu_file);
  is(ref($lgozu),"HASH","lookup failed after deleting a share") ||
    skip "dubious lookup result", 9;

  $info  = $raid->sharefile_info($gozu_file,"regular",$lgozu);

  is(ref($info), "HASH", "no sharefile_info for gozu.mpeg") ||
    skip "no tests on undefined return value", 8;

  is ($info->{nshares}, 2, "wrong number of shares reported");
  is ($info->{quorum} , 2, "wrong quorum value reported");

  eq_array(@{$info->{file_names}},
	   $raid->sharefile_names($gozu_file,"regular",$lgozu),
	   "filenames differ between sharefile_names and sharefile_info");

  ok ($info->{viable},   "gozu.mpeg reported as NOT viable");
  ok (!$info->{perfect}, "gozu.mpeg reported as PERFECT");
  is (ref($info->{headers}),"ARRAY", "gozu.mpeg headers not right type");

  map {
    ok (-f $info->{file_names}->[$_], "! -f returned gozu.mpeg share $_")
  } (0..1);
}

SKIP: {

  skip "Expected 2 valid shares here", 9 if @goodsharefiles < 2;

  unlink shift @goodsharefiles;
  --$nsharefiles;

  # now that we've delete a file, our cached lookup results are
  # invalid and we have to look them up again.
  $lgozu = $raid->lookup($gozu_file);
  is(ref($lgozu),"HASH","lookup failed after deleting a share") ||
    skip "dubious lookup result", 8;

  $info  = $raid->sharefile_info($gozu_file,"regular",$lgozu);

  is(ref($info), "HASH", "no sharefile_info for gozu.mpeg") ||
    skip "no tests on undefined return value", 7;

  is ($info->{nshares}, 1, "wrong number of shares reported");
  is ($info->{quorum} , 2, "wrong quorum value reported");

  eq_array(@{$info->{file_names}},
	   $raid->sharefile_names($gozu_file,"regular",$lgozu),
	   "filenames differ between sharefile_names and sharefile_info");

  ok (!$info->{viable},   "gozu.mpeg reported as VIABLE");
  ok (!$info->{perfect}, "gozu.mpeg reported as PERFECT");
  is (ref($info->{headers}),"ARRAY", "gozu.mpeg headers not right type");

  map {
    ok (-f $info->{file_names}->[$_], "! -f returned gozu.mpeg share $_")
  } (0);
}

SKIP: {

  ok (@goodsharefiles == 1,"We should have one share left!") ||
    skip "Expected 1 valid share here", 2;

  # delete the last share
  unlink shift @goodsharefiles;
  --$nsharefiles;

  # lookup should still return something even if we have no shares
  $lgozu = $raid->lookup($gozu_file);
  is(ref($lgozu),"HASH","lookup failed after deleting a share") ||
    skip "dubious lookup result", 1;

  $info  = $raid->sharefile_info($gozu_file,"regular",$lgozu);

  is($info,undef, "gozu.mpeg shouldn't have any sharefile_info now");
}




FAIL: {
  local $SIG{__WARN__} = sub { die $_[0] };

  # Calling sharefile_info on a file that is managed, but that has no
  # sharefiles should simply return undef and not emit any warnings.

  my $info;

  eval {$info = $raid->sharefile_info($drwhofile,"regular",$ldrwho)};

  is ($@,"", "sharefile_info too noisy");
  is ($info, undef, "sharefile_info found nonexistent shares");

}


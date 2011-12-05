#!perl -T

use strict;
use warnings;

use Test::More tests => 46;
use Module::Build qw(args get_options);

BEGIN {
  use_ok('Media::RAID::Store',qw(new_drive_store new_fixed_store))
    || print "Bail out!\n";
  use_ok('Media::RAID') || print "Bail out!\n";

  # File::Temp isn't strictly necessary for using the module, but I'll
  # bail out on testing if it's not available.
  use_ok('File::Temp', qw(tempfile tempdir)) || print "Bail out!";

}

diag("Testing Media::RAID::lookup");

#
# This first bit of code is copied from 02-RAID-constructors.t, so we
# just bail out if any of these tests fail.
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


# Now add a simple scheme with minimal arguments. We need some
# temporary directories before we can use this

$working_1 = File::Temp->newdir;
$mroot_1   = File::Temp->newdir;
$sroot_1   = File::Temp->newdir;
$mpath_1   = "/master_files";
@spaths_1  = ('/One','/Two','/Three');

mkdir "$mroot_1$mpath_1" or print "Bail out!\n";

ok (ref($raid_1) eq $obj_type) || print "Bail out!\n";

my $mstore;

ok (
    $rc = $raid_1->add_scheme
    (
     "raid_1",
     nshares => 3, quorum => 2, width => 1,
     master_stores =>
     {
      master => ($mstore= new_fixed_store($mroot_1, $mpath_1)),
     },
     share_stores =>
     [
      map { new_fixed_store($sroot_1, $spaths_1[$_]) } (0..2)
     ],
     working_dir => $working_1,
    ),
    "failed to add scheme raid_1")
  || print "Bail out!\n";


#
# Begin new tests
#

ok(!defined($raid_1->lookup("/")), "lookup should have failed on /");
ok(!defined($raid_1->lookup("$mroot_1")),
   "lookup should have failed on $mroot_1");
ok(!defined($raid_1->lookup("$mroot_1/")),
   "lookup should have failed on $mroot_1/");

my $lookup_info;


# run three sets of lookup tests:
# 1. no scheme specified, and root of archive specified
# 2. as above, but with raid_1 scheme specifically passed in
# 3. with scheme, and dir is root of archive + a subdir

for (0..2) {

  my @lookup_schemes = (!$_) ? () : ('raid_1');
  my $lookup_path = "$mroot_1$mpath_1";
  $lookup_path = "$mroot_1$mpath_1/subdir" if $_ == 2;

 SKIP: {
    ok (defined($lookup_info = $raid_1->lookup("$lookup_path",
					       @lookup_schemes)),
	"lookup should have succeeded on $lookup_path");

    skip "No lookup info to check", 9 unless defined($lookup_info);

    ok (ref($lookup_info) eq "HASH", "expected a hashref back from lookup");

    ok (((keys %$lookup_info)==1),
	"expected exactly one key in lookup result");

    ok (exists($lookup_info->{raid_1}),
	"lookup didn't return raid_1 scheme");

    ok ($lookup_info->{raid_1}->{archive} eq "master",
	"lookup didn't match master archive as expected");
    ok ($lookup_info->{raid_1}->{store} == $mstore,
	"lookup didn't return master store as expected");
    ok ($lookup_info->{raid_1}->{storeid} eq $mroot_1,
	"lookup didn't return master storeid as expected");
    ok ($lookup_info->{raid_1}->{storeroot} eq "$mroot_1",
	"lookup returned incorrect master storeroot: ".
	$lookup_info->{raid_1}->{storeroot});
    ok ($lookup_info->{raid_1}->{path} eq $mpath_1,
	"lookup didn't return master path as expected");
    ok ($lookup_info->{raid_1}->{relative} eq
	($_ < 2 ? "/" : "/subdir"),
	"lookup returned incorrect relative path: ".
	$lookup_info->{raid_1}->{relative});
  }
}

#
# test sharefile_names with and without using cached lookup return
# values
#

SKIP: {
  my $file = "$mroot_1$mpath_1/file";
  my @sharefiles = $raid_1->sharefile_names("$file");
  ok (3 == @sharefiles,
      "Didn't get 3 sharefiles back from sharefile_names");

  skip "Can't test sharefile names", 3 unless 3 == @sharefiles;

  for (0..2) {
    my $expected = "$sroot_1$spaths_1[$_]$mpath_1/file.sf";
    is ($sharefiles[$_], $expected, "wrong sharefile name");
  }
}

SKIP: {
  my $file = "$mroot_1$mpath_1/file";
  my $lhash = $raid_1->lookup($file);
  my @sharefiles = $raid_1->sharefile_names($file,undef,$lhash);
  ok (3 == @sharefiles,
      "Didn't get 3 sharefiles back from sharefile_names");

  skip "Can't test sharefile names", 3 unless 3 == @sharefiles;

  for (0..2) {
    my $expected = "$sroot_1$spaths_1[$_]$mpath_1/file.sf";
    is ($sharefiles[$_], $expected, "wrong sharefile name");
  }
}



exit 0;

# The tests below are conditional on having the build script called
# with drive=some named removable drive

# Why is it so hard to get simple runtime (ARGV) parameters?

# using require on build_params returns an array, whereas
# runtime_params returns a hash...

use File::Spec::Functions qw' updir catfile rel2abs ';
use File::Basename qw' dirname ';

my $thisf = rel2abs(__FILE__);
my $thisd = dirname($thisf);
my $conff = catfile( $thisd, updir, qw! _build build_params ! );

warn "Untainting \$conff = $conff\n";
$conff =~ m/(.*)/; $conff = $1;

my $conf = require $conff;

warn "\$conf is a " . ref($conf) . " and it has contents $conf\n";

my $args = $conf->[0];
my %ARGS = %{$conf->[0] };

warn "drive? $$args{drive}\n";
warn "drive? $ARGS{drive}\n";


use Cwd qw(abs_path);
use Scalar::Util qw(tainted);

my $param_file = abs_path __FILE__;

warn "__FILE__ is tainted\n" if tainted(__FILE__);
warn "param_file is tainted (1)\n" if tainted($param_file);

$param_file =~ s|(.*)/.*|$1|;
$param_file = abs_path("$param_file/../_build/runtime_params");
# have to untaint since abs_path always taints, regardless of whether
# input value (__FILE__ in this case) was or not
$param_file =~ m/(.*)/; $param_file = $1;

warn "param_file is " . (tainted($param_file)?"":"un") . "tainted (2)\n";
warn "Param file is $param_file\n";

$conf = require $param_file;
warn "\$conf is a " . ref($conf) . " and it has contents $conf\n";

%ARGS = %$conf;

diag ("Got drive = " . $ARGS{config}->{drive});




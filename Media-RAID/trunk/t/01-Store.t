#!perl -T

use Test::More tests => 52;

BEGIN {
  use_ok('Media::RAID::Store',qw(new_drive_store new_fixed_store))
    || print "Bail out!\n";
}

diag("Testing Media::RAID::Store $Media::RAID::Store::VERSION, Perl $]" );

#
# constructor tests
#
my ($drive_1,$fixed_1,$drive_2,$fixed_2,$drive_3);

# basic drive/fixed via new()
ok(defined
   ($drive_1 =
    Media::RAID::Store->new(drive => 'Removable', path => '/path')),
   "Create drive store with new");

ok(defined($fixed_1 =
	   Media::RAID::Store->new(fixed => $ENV{HOME},
				   path => '/subdir')),
   "Create fixed store with new");

# basic drive/fixed via exported functions
ok(defined($drive_2 = new_drive_store('Removable','/subdir')),
   "Create drive store with exported function (2 args)");

ok(defined($drive_3 = new_drive_store('Removable','/subdir','/mnt')),
   "Create drive store with exported function (3 args)");

ok(defined($fixed_2 = new_fixed_store($ENV{HOME},'/subdir')),
   "Create fixed store with exported function");

#
# Misc useful/reusable variables
#
my $rc;

#
# Check accessor methods
#
SKIP: {

  # drive_1 = class->new(drive => 'Removable', path => '/path')),

  skip "Creating drive_1 failed", 9 unless defined($drive_1);

  ok ($drive_1->id   eq "Removable", "drive_1->id ne 'Removable'");
  ok ($drive_1->type eq "drive", "drive_1->type ne 'drive'");
  ok ($drive_1->mountable, "\$drive_1->mountable returned false");
  ok ($drive_1->mount_root eq "", "\$drive_1->mount_root not empty");
  ok ($drive_1->mount_root eq "",
      "\$drive_1->mount_root changed on 2nd access");
  ok (!defined($drive_1->as_path),
      "drive_1->as_path defined, but drive not mounted");

  # Now define mount_root and see how mount_root and as_path behave
  ok ($drive_1->mount_root('/mnt') eq '/mnt',
      "Calling drive_1->mount_root didn't return mount_root");
  ok ($drive_1->mount_root eq '/mnt',
      "Calling drive_1->mount_root didn't change mount_root");
  ok ($drive_1->as_path eq "/mnt/Removable/path",
      "drive_1->as_path: wrong value after setting mount_root");
}

SKIP: {

  # fixed_1 = class->new(fixed => $ENV{HOME}, path => '/subdir')),

  skip "Creating fixed_1 failed", 8 unless defined($fixed_1);

  # Set up so that warnings/carps from functions become fatal for this
  # block. Allows us to catch these warnings from eval block in $@ and
  # also not have them sent to stderr.
  local $SIG{__WARN__} = sub { die $_[0] };

  ok ($fixed_1->id   eq $ENV{HOME}, "drive_1->id ne '$ENV{HOME}'");
  ok ($fixed_1->type eq "fixed", "fixed_1->type ne 'fixed'");
  ok (!$fixed_1->mountable, "\$fixed_1->mountable returned true");
  ok ($fixed_1->mount_root eq "", "\$fixed_1->mount_root not empty");
  ok ($fixed_1->mount_root eq "",
      "\$fixed_1->mount_root changed on 2nd access");

  ok ($fixed_1->as_path eq "$ENV{HOME}/subdir",
      "fixed_1->as_path: wrong value:" . $fixed_1->as_path);

  # We want eval to fail by dieing here
  eval { $fixed_1->mount_root("/wrong") };
  ok ($@ ne "", "fixed_1->mount_root should have failed");
  ok ($fixed_1->mount_root eq "",
      "fixed_1->mount_root shouldn't have set mount_root");

}

SKIP: {

  # fixed_2 = new_fixed_store($ENV{HOME},'/subdir')),

  skip "Creating fixed_2 failed", 8 unless defined($fixed_2);

  # Set up so that warnings/carps from functions become fatal for this
  # block. Allows us to catch these warnings from eval block in $@ and
  # also not have them sent to stderr.
  local $SIG{__WARN__} = sub { die $_[0] };

  ok ($fixed_2->id   eq $ENV{HOME}, "drive_1->id ne '$ENV{HOME}'");
  ok ($fixed_2->type eq "fixed", "fixed_2->type ne 'fixed'");
  ok (!$fixed_2->mountable, "\$fixed_2->mountable returned true");
  ok ($fixed_2->mount_root eq "", "\$fixed_2->mount_root not empty");
  ok ($fixed_2->mount_root eq "",
      "\$fixed_2->mount_root changed on 2nd access");

  ok ($fixed_2->as_path eq "$ENV{HOME}/subdir",
      "fixed_2->as_path: wrong value:" . $fixed_2->as_path);

  # We want eval to fail by dieing here
  eval { $fixed_2->mount_root("/wrong") };
  ok ($@ ne "", "fixed_2->mount_root should have failed");
  ok ($fixed_2->mount_root eq "",
      "fixed_2->mount_root shouldn't have set mount_root");

}

SKIP: {

  # drive_2 = new_drive_store('Removable','/subdir')),

  skip "Creating drive_2 failed", 9 unless defined($drive_2);

  ok ($drive_2->id   eq "Removable", "drive_2->id ne 'Removable'");
  ok ($drive_2->type eq "drive", "drive_2->type ne 'drive'");
  ok ($drive_2->mountable, "\$drive_2->mountable returned false");
  ok ($drive_2->mount_root eq "", "\$drive_2->mount_root not empty");
  ok ($drive_2->mount_root eq "",
      "\$drive_2->mount_root changed on 2nd access");
  ok (!defined($drive_2->as_path),
      "drive_2->as_path defined, but drive not mounted");

  # Now define mount_root and see how mount_root and as_path behave
  ok ($drive_2->mount_root('/mnt') eq '/mnt',
      "Calling drive_2->mount_root didn't return mount_root");
  ok ($drive_2->mount_root eq '/mnt',
      "Calling drive_2->mount_root didn't change mount_root");
  ok ($drive_2->as_path eq "/mnt/Removable/subdir",
      "drive_2->as_path: wrong value after setting mount_root");
}


SKIP: {

  # drive_3 = new_drive_store('Removable','/subdir','/mnt')),

  skip "Creating drive_3 failed", 12 unless defined($drive_3);

  ok ($drive_3->id   eq "Removable", "drive_3->id ne 'Removable'");
  ok ($drive_3->type eq "drive", "drive_3->type ne 'drive'");
  ok ($drive_3->mountable, "\$drive_3->mountable returned false");
  ok ($drive_3->mount_root eq "/mnt", "\$drive_3->mount_root wrong");
  ok ($drive_3->mount_root eq "/mnt",
      "\$drive_3->mount_root changed on 2nd access");
  ok ($drive_3->as_path eq "/mnt/Removable/subdir",
      "drive_3->as_path wrong (old mount_root)");

  # Now define mount_root and see how mount_root and as_path behave
  ok ($drive_3->mount_root('/media') eq '/media',
      "Calling drive_3->mount_root didn't return mount_root");
  ok ($drive_3->mount_root eq '/media',
      "Calling drive_3->mount_root didn't change mount_root");
  ok ($drive_3->as_path eq "/media/Removable/subdir",
      "drive_3->as_path: wrong value after setting mount_root");

  # Now unset mount_root (only place this is tested)
  ok ($drive_3->mount_root('') eq '',
      "Calling drive_3->mount_root('') didn't return ''");
  ok ($drive_3->mount_root eq '',
      "Calling drive_3->mount_root('') didn't change mount_root");
  ok (defined($drive_2->as_path),
      "drive_2->as_path defined, but drive shouldn't be mounted now");
}

# For further testing:
#
# * So far I haven't written any routines to actually mount drives or
#   to check that they are mounted. The former is definitely not
#   something that can be tested without having an attached removable
#   drive that this script can be told about. Since that's kind of
#   awkward to fit into the flow of testing, I'm not bothered about
#   that right now.
#
# * Related to the above point, I haven't actually written code to do
#   mounting of drives yet. When I do, I might have some new testable
#   functions.
#
# * I might also want to add some more cases that should fail (ie,
#   checking that certain invalid input data throws warnings and/or
#   returns false values)
#

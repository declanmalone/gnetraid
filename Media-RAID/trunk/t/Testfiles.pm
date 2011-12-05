#
# store a bunch of files that can be used for testing
#

use strict;
use warnings;

package Testfiles;

use Exporter;

use vars qw($tf_master_movies $tf_master_tv $tf_complete_tree
	    $tf_shares_n3_k2_w1 $tf_shares_n8_k5_w1
	    @ISA @EXPORT);

# export everything since I don't care about namespace pollution when
# this script is only used for testing (and all names except x are
# prefixed anyway)
@ISA = qw(Exporter);
@EXPORT = qw($tf_master_movies $tf_master_tv $tf_complete_tree
	     $tf_shares_n3_k2_w1 $tf_shares_n8_k5_w1
	     tf_extract_file_tree tf_extra_scheme tf_regular_scheme);

use Media::RAID::Store qw(new_drive_store new_fixed_store);

# master file structures are named after the archive name and rooted
# after the fixed part of the store name. This allows us to specify
# files outside of the actual archive so that we can test the
# scan_others feature of the scan method.

$tf_master_movies =
  {
   video =>
   {
    movies =>			# main archive
    {
     "A Grand Day Out" =>
     {
      "agdo.avi"  => "Lorem ipsum dolor sit amet, consectetuer",
      "agdo.my"   => "adipiscing elit, sed diam nonummy",
     },
     "The Brain that Wouldn't Die" =>
     {
      "tbtwd.ogv" => "nibh euismod tincidunt ut laoreet dolore",
      "tbtwd.txt" => "magna aliquam erat volutpat.",
     },
     "Dazed and Confused" =>
     {
      "dac.avi"   => "Ut wisi enim ad minim veniam, quis nostrud",
     },
     "The Elephant Man" =>
     {
      "tem.avi"   => "exerci tation ullamcorper suscipit lobortis",
      "tem.my"    => "nisl ut aliquip ex ea commodo consequat."
     },
     "Gozu" =>
     {
      # newline added to EOF since that's what I split accidentally
      # using rabin-split.pl
      "gozu.mpeg" => "Duis autem vel eum iriure\n",
     },
     "La Haine"   =>
     {
      "lh.avi"    => "dolor in hendrerit in vulputate velit",
      "lh.sub"    => "esse molestie consequat, vel",
      "lh.idx"    => "illum dolore eu feugiat nulla facilisis",
     },
     "Idiocracy" =>
     {
      "idiot.avi" => "at vero eros et accumsan et iusto odio"
     },
     "Jean de Florette" =>
     {
      "jdf.mkv"   => "dignissim qui blandit praesent luptatum zzril",
     },
    },
    # all the following files aren't within the store
    "checksums"   => "delenit augue duis dolore te feugait nulla facilisi.",
    # some files are copies of those in the tv archive (and some
    # aren't exact copies)
    tv =>
    {
     "Doctor Who" =>
     {
      2009 =>
      {
       "S04E15.avi" => "Nam liber tempor cum soluta nobis",
       # next one is not an exact copy
       "S04E16.avi" => "broken PVR copy",
      },
     },
     "Samurai Champloo" =>
     {
      "Ep. 01.avi"  => "eleifend option congue nihil imperdiet",
      "Ep. 02.avi"  => "doming id quod mazim placerat facer",
      "Ep. 03.avi"  => "possim assum.",
      "Ep. 04.avi"  => "Typi non habent claritatem insitam; est usus",
      # another non-exact copy
      "Ep. 05.avi"  => "truncated during copy",
     },
    }
   }
};


$tf_master_tv =
  {
   video =>
   {
    tv =>
    {
     "Doctor Who" =>
     {
      2009 =>
      {
       "S04E15.avi" => "Nam liber tempor cum soluta nobis",
       # next one is broken in movies backup
       "S04E16.avi" => "legentis in iis qui facit eorum claritatem",
       # next one is unique to our archive
       "S04E17.avi" => "Investigationes demonstraverunt lectores legere"
      },
     },
     "Samurai Champloo" =>
     {
      # the next four are identical to files in movies backup
      "Ep. 01.avi"  => "eleifend option congue nihil imperdiet",
      "Ep. 02.avi"  => "doming id quod mazim placerat facer",
      "Ep. 03.avi"  => "possim assum.",
      "Ep. 04.avi"  => "Typi non habent claritatem insitam; est usus",
      # this one differs from backup copy in movies archive
      "Ep. 05.avi"  => "me lius quod ii legunt saepius.",
      # these have no backups
      "Ep. 06.avi"  => "Claritas est etiam processus dynamicus,",
      "Ep. 07.avi"  => "qui sequitur mutationem consuetudium lectorum.",
      "Ep. 08.avi"  => "Mirum est notare quam littera gothica,",
      "Ep. 09.avi"  => "quam nunc putamus parum claram, anteposuerit",
      "Ep. 10.avi"  => "litterarum formas humanitatis per seacula quarta",
      "Ep. 11.avi"  => "decima et quinta decima. Eodem modo typi,",
      "Ep. 12.avi"  => "qui nunc nobis videntur parum clari,",
     },
     # next one has not even a corresponding directory in movies backup
     "Sapphire and Steel" =>
     {
      "Ep. 01.avi"  => "fiant sollemnes in futurum."
     },
    },
    # we also have some 100% copies of movies from our movies archive
    movies =>
    {
     "Gozu" =>			# exact copy
     {
      "gozu.mpeg" => "Duis autem vel eum iriure\n",
     },
     "Jean de Florette" =>	# broken copy
     {
      "jdf.mkv"   => "this one is broken",
     },
    },
   }
};

# turn hex string into binary
sub x { pack "H*", shift };

# we don't need many pre-generated shares, just enough to test the
# scan function. Afterwards, when I've written the split function I
# can split as many files as I need. For simplicity, these assume all
# shares will be stored in the same subdir with very simple directory
# names. In reality you would want to store shares in separate
# disks/stores.

# The original file for gozu.mpeg is "Duis autem vel eum iriure\n". I
# had these shares generated before I realised I had an extra newline
# in the file that I split. Being lazy, I just added the newline to
# the original rather than recalculating the shares.
$tf_shares_n3_k2_w1 =
  {
   0 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c020100011a4916d649f496b7eda1ac4b44f7e2d4"
					   } } } },
   1 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c020100011adb076d590290c067c71edf3af482ee"
					   } } } },
   2 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c020100011aabe9e7053947eb8202b0b53040072e"
					   } } } },
};

$tf_shares_n8_k5_w1 =
  {
   0 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a45a6cd58243bfbf42dfd94"
					   } } } },
   1 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a436c12e9f6ff8be5f836a8"
					   } } } },
   2 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a24012aa14552e4c64a6273"
					   } } } },
   3 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a8953ca717d5dcea616aa2d"
					   } } } },
   4 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a01241bc1a6b3c7884b800a"
					   } } } },
   5 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011aeeab6342d0fbd9c26759f6"
					   } } } },
   6 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011ae13e0b5547a8ec7f270a90"
					   } } } },
   7 => { video => { movies => { "Gozu" => {
     "gozu.mpeg.sf" =>
     x "5346010c050100011a9a040578a0eebb8e84dd93"
					   } } } },
};

# complete filesystem with configs, master archives and share storage
$tf_complete_tree =
  {
   "master_drives" =>
   {
    "drive_1" => $tf_master_movies,
    "drive_2" => $tf_master_tv,
   },
   "shares" =>
   {
    "regular" => $tf_shares_n3_k2_w1,
    "extra"   => $tf_shares_n8_k5_w1,
   },
   "config" =>
   {
    "regular" => {},
    "extra"   => {},
   }
};


# Create two schemes that encapsulates info about this collection of
# files. Pass them an initialised Media::RAID object and a base
# directory where the complete tree of test files is stored. The
# functions supply the names "regular" for the n=3,k=2 scheme and
# "extra" for the (extra safe) n=8,k=5 scheme.
sub tf_regular_scheme {
  my ($raid,$dir,@junk) = @_;
  die "Arg1 ($raid) not a Media::RAID object\n"
    unless ref($raid) eq "Media::RAID";
  die "Arg2 ($dir) not an existing dir\n" unless -d $dir;

  my $rc = $raid->add_scheme
    ("regular",
     nshares => 3, quorum => 2, width => 1,
     master_stores =>
     {
      movies => new_fixed_store("$dir/master_drives/drive_1",
				"/video/movies"),
      tv     => new_fixed_store("$dir/master_drives/drive_2",
				"/video/tv"),
     },
     share_stores =>
     [
      map { new_fixed_store("$dir","/shares/regular/$_") } (0..2)
     ],
     working_dir => "$dir/config/regular",
    );
  die "Failed to create \"regular\" scheme\n" unless $rc;
  $rc;
}


sub tf_extra_scheme {
  my ($raid,$dir,@junk) = @_;
  die "Arg1 ($raid) not a Media::RAID object\n"
    unless ref($raid) eq "Media::RAID";
  die "Arg2 ($dir) not an existing dir\n" unless -d $dir;

  my $rc = $raid->add_scheme
    ("extra",
     nshares => 8, quorum => 5, width => 1,
     master_stores =>
     {
      tv2 => new_fixed_store("$dir/master_drives/drive_2",
			     "/video/tv"),
     },
     share_stores =>
     [
      map { new_fixed_store("$dir","/shares/extra/$_") } (0..7)
     ],
     working_dir => "$dir/config/extra",
    );
  die "Failed to create \"extra\" scheme\n" unless $rc;
  $rc;
}


sub tf_extract_file_tree {
  my ($dir,$tree,@junk) = @_;

  die "Arg 1 ($dir) undefined\n" unless defined($dir);
  die "Arg 2 ($tree) should be a hashref\n" unless ref($tree) eq "HASH";

  die "Dir '$dir' doesn't exist\n" unless -d $dir;

  # recursive bit
  while (my ($key,$value) = each %$tree) {
    if (ref ($value) eq "HASH") {
      my $subdir = "$dir/$key";
      unless (-d $subdir) {
	die "mkdir '$subdir' failed\n" unless mkdir $subdir;
      }
      tf_extract_file_tree($subdir,$value);
    } else {
      my $filename = "$dir/$key";
      open FILE, ">", $filename or die "Couldn't creat $filename\n";
      print FILE $value;
      close FILE;
    }
  }
}

1

#
# store a bunch of files that can be used for testing
#


# master file structures are named after the archive name and rooted
# after the fixed part of the store name. This allows us to specify
# files outside of the actual archive so that we can test the
# scan_others feature of the scan method.

my $tf_master_movies =
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
      "gozu.mpeg" => "Duis autem vel eum iriure",
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


my $tf_master_tv =
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
      "gozu.mpeg" => "Duis autem vel eum iriure",
     },
     "Jean de Florette" =>	# broken copy
     {
      "jdf.mkv"   => "this one is broken",
     },
    },
   }
};

my $tf_working =
  {



};

sub x { pack "H*", shift };

# we don't need many pre-generated shares, just enough to test the
# scan function. Afterwards, when I've written the split function I
# can split as many files as I need. For simplicity, these assume all
# shares will be stored in the same subdir with very simple directory
# names. In reality you would want to store shares in separate
# disks/stores.

# The original file for gozu.mpeg is "Duis autem vel eum iriure"
my $tf_shares_n3_k2_w1 =
  {
   0 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c020100011a4916d649f496b7eda1ac4b44f7e2d4"
					   } } } },
   1 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c020100011adb076d590290c067c71edf3af482ee"
					   } } } },
   2 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c020100011aabe9e7053947eb8202b0b53040072e"
					   } } } },
};

my $tf_shares_n8_k5_w1 =
  {
   0 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a45a6cd58243bfbf42dfd94"
					   } } } },
   1 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a436c12e9f6ff8be5f836a8"
					   } } } },
   2 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a24012aa14552e4c64a6273"
					   } } } },
   3 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a8953ca717d5dcea616aa2d"
					   } } } },
   4 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a01241bc1a6b3c7884b800a"
					   } } } },
   5 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011aeeab6342d0fbd9c26759f6"
					   } } } },
   6 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011ae13e0b5547a8ec7f270a90"
					   } } } },
   7 => { video => { movies => { "Gozu" => {
     "gozu.mpeg" =>
     x "5346010c050100011a9a040578a0eebb8e84dd93"
					   } } } },
};


1

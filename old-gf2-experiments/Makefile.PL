use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	      NAME   => 'Crypto::mylib',
	      SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	      clean  => {'FILES' => 'libmylib$(LIB_EXT)'},
	     );

sub MY::top_targets {'
all :: static

pure_all :: static

static ::       librabin-ida$(LIB_EXT)

librabin-ida$(LIB_EXT): $(O_FILES)
	$(AR) cr librabin-ida$(LIB_EXT) $(O_FILES)
	$(RANLIB) librabin-ida$(LIB_EXT)
';
}

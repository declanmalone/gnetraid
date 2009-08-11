use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::FastGF2',
    VERSION_FROM      => 'lib/Math/FastGF2.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/FastGF2.pm', # retrieve abstract from module
       AUTHOR         => 'Declan Malone <idablack@sourceforge.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    MYEXTLIB          => 'clib/libfastgf2$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
#    OBJECT            => 'FastGF2.o', # link all the C files too
#    OBJECT            => '$(O_FILES)', # link all the C files too
    EXE_FILES          => ['script/benchmark-Math-FastGF2.pl',
			   'script/shamir-combine.pl',
			   'script/shamir-split.pl'],
);
sub MY::postamble {
'$(MYEXTLIB): clib/Makefile
	cd clib && $(MAKE) $(PASSTHRU)
';
}

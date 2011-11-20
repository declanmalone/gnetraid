#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Media::RAID' ) || print "Bail out!
";
    use_ok( 'Media::RAID::Config' ) || print "Bail out!
";
    use_ok( 'Media::RAID::FUSE' ) || print "Bail out!
";
}

diag( "Testing Media::RAID $Media::RAID::VERSION, Perl $], $^X" );

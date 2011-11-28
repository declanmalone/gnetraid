#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Media::RAID' ) || print "Bail out!\n";
    use_ok( 'Media::RAID::Config' ) || print "Bail out!\n";
    use_ok( 'Media::RAID::FUSE' ) || print "Bail out!\n";
    use_ok( 'Media::RAID::Store' ) || print "Bail out!\n";
}

diag( "Testing module loading, Perl $]" );

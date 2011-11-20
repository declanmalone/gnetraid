use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Media::RAID',
    license             => 'perl',
    dist_author         => q{Declan Malone <idablack@sourceforge.net>},
    dist_version_from   => 'lib/Media/RAID.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Media-RAID-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::OCD::Mapper',
    license             => 'perl',
    dist_author         => q{Declan Malone <idablack@users.sourceforge.net>},
    dist_version_from   => 'lib/App/OCD/Mapper.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'App-OCD-Mapper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

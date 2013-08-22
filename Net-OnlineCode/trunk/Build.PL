use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::OnlineCode',
    license             => 'gpl',
    dist_author         => q{Declan Malone <idablack@users.sourceforge.net>},
    dist_version_from   => 'lib/Net/OnlineCode.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Net-OnlineCode-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

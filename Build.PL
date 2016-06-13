use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'LIFinder',
    license            => 'gpl_2',
    dist_author        => q{Yuhao Wu <wyhfrank@gmail.com>},
    dist_version_from  => 'lib/LIFinder.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'DBI'                   => '0',
        'DBD::SQLite'           => '0',
        'File::Basename'        => '0',
        'File::Find'            => '0',
        'File::Spec::Functions' => '0',

        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => ['LIFinder-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

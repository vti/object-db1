use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'ObjectDB',
    VERSION_FROM => 'lib/ObjectDB.pm',
    ABSTRACT     => 'Lightweight and powerful ORM',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008001'},
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/object-db'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'Carp'        => 0,
        'DBI'         => 0,
        'Digest::MD5' => 0,
        'Test::More'  => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);

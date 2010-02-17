use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ObjectDB',
    AUTHOR        => 'Viacheslav Tykhanovskyi <vti@cpan.org>',
    VERSION_FROM  => 'lib/ObjectDB.pm',
    ABSTRACT_FROM => 'lib/ObjectDB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'DBI'           => 0
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'ObjectDB-*'}
);

#!perl

use strict;
use warnings;

use Test::More tests => 2;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->source(
    {   name       => 'table',
        join       => 'left',
        as         => 'table',
        constraint => ['alias.id' => 'table.id']
    }
);
$sql->columns(qw/foo/);
is("$sql", "SELECT `foo` FROM `table`");

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->source(
    {   name       => 'table',
        join       => 'left',
        as         => 'alias',
        constraint => ['alias.id' => 'table.id']
    }
);
$sql->source(
    {   name       => 'table',
        join       => 'left',
        as         => 'alias',
        constraint => ['alias.id' => 'table.id']
    }
);
$sql->columns(qw/foo/);
is("$sql",
    "SELECT `alias`.`foo` FROM `table` LEFT JOIN `table` AS `alias` ON `alias`.`id` = `table`.`id`"
);

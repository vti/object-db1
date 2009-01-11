use Test::More tests => 2;

use ObjectDB::SQLBuilder;

my $sql;

$sql = ObjectDB::SQLBuilder->build('begin');
is("$sql", 'BEGIN');

$sql = ObjectDB::SQLBuilder->build('begin')->behavior('immediate');
is("$sql", 'BEGIN IMMEDIATE');

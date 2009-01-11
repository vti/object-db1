use Test::More tests => 1;

use ObjectDB::SQLBuilder;

my $sql;

$sql = ObjectDB::SQLBuilder->build('rollback');
is("$sql", 'ROLLBACK');

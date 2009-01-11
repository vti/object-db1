use Test::More tests => 1;

use ObjectDB::SQLBuilder;

my $sql;

$sql = ObjectDB::SQLBuilder->build('commit');
is("$sql", 'COMMIT');

use Test::More tests => 1;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new(command => 'select', source => 'table');

$sql->where([id => 2, title => 'hello']);
is("$sql", "SELECT * FROM `table` WHERE id = '2' AND title = 'hello'");

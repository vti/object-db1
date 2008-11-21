use Test::More tests => 2;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('insert');
$sql->table('foo');
$sql->columns([qw/ a b /]);
$sql->add_columns('c');
is("$sql", "INSERT INTO foo (a, b, c) VALUES (?, ?, ?)");

$sql->command('insert')->table('bar')->columns([qw/ bo boo /])->add_columns('booo');
is("$sql", "INSERT INTO bar (bo, boo, booo) VALUES (?, ?, ?)");
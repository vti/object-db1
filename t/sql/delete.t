use Test::More tests => 3;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->build('delete');

$sql->table('foo');
is("$sql", "DELETE FROM `foo`");

$sql = ObjectDB::SQL->build('delete');
$sql->table('foo');
$sql->where([id => 2]);
is("$sql", "DELETE FROM `foo` WHERE (`id` = ?)");
is_deeply($sql->bind, [2]);

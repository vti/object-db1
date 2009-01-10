use Test::More tests => 3;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('delete');

$sql->table('foo');
is("$sql", "DELETE FROM `foo`");

$sql = ObjectDB::SQLBuilder->build('delete')->table('foo')->where([id => 2]);
is("$sql", "DELETE FROM `foo` WHERE (`id` = ?)");
is_deeply($sql->bind, [2]);

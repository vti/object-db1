use Test::More tests => 9;

use ObjectDB::SQLBuilder;

my $sql;

$sql = ObjectDB::SQLBuilder->build('update')->table('foo')->columns([qw/ hello boo /])->bind([1, 2]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ?");
is_deeply($sql->bind, [qw/ 1 2 /]);

$sql = ObjectDB::SQLBuilder->build('update')->table('foo')->columns([qw/ hello boo /])->bind([5, 9])->where([id => 3]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ? WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 5 9 3 /]);

$sql = ObjectDB::SQLBuilder->build('update')->table('foo')->columns([qw/ hello boo /])->bind([\'hello + 1', 4])->where([id => 5]);
is("$sql", "UPDATE `foo` SET hello = hello + 1, boo = ? WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 4 5 /]);

$sql = ObjectDB::SQLBuilder->build('update')->table('foo')->columns([qw/ hello boo /])->bind([\'hello + 1', \'boo + 2'])->where([id => 5]);
is("$sql", "UPDATE `foo` SET hello = hello + 1, boo = boo + 2 WHERE (`id` = ?)");
is("$sql", "UPDATE `foo` SET hello = hello + 1, boo = boo + 2 WHERE (`id` = ?)");
is_deeply($sql->bind, [qw/ 5 /]);

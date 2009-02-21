use Test::More tests => 14;

use ObjectDB::SQLBuilder;

my $sql;

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where([id => 2, title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` = ? AND `title` = ?)");
is_deeply($sql->bind, [qw/ 2 hello /]);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where([id => [1, 2, 3]]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` IN (?, ?, ?))");
is_deeply($sql->bind, [qw/ 1 2 3 /]);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where([\'foo.id = 2', title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.id = 2 AND `title` = ?)");
is_deeply($sql->bind, [qw/ hello /]);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` = ?)");
is_deeply($sql->bind, [qw/ 2 /]);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where([-or => ['foo.id' => undef, -and => ['foo.title' => 'boo', 'foo.content' => 'bar']]]);
is("$sql", "SELECT `foo` FROM `table` WHERE ((`foo`.`id` IS NULL OR (`foo`.`title` = ? AND `foo`.`content` = ?)))");
is_deeply($sql->bind, ['boo', 'bar']);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where_logic('OR')->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` = ?)");
is_deeply($sql->bind, [qw/ 2 /]);

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table')->columns('foo')
  ->where(['foo.id' => {'>' => 2}]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` > ?)");
is_deeply($sql->bind, [qw/ 2 /]);

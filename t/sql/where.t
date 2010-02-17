use Test::More tests => 16;

use ObjectDB::SQL;

my $sql;

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where([id => 2, title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` = ? AND `title` = ?)");
is_deeply($sql->bind, [qw/ 2 hello /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where([id => [1, 2, 3]]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` IN (?, ?, ?))");
is_deeply($sql->bind, [qw/ 1 2 3 /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where([\'foo.id = 2', title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.id = 2 AND `title` = ?)");
is_deeply($sql->bind, [qw/ hello /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` = ?)");
is_deeply($sql->bind, [qw/ 2 /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where([-or => ['foo.id' => undef, -and => ['foo.title' => 'boo', 'foo.content' => 'bar']]]);
is("$sql", "SELECT `foo` FROM `table` WHERE ((`foo`.`id` IS NULL OR (`foo`.`title` = ? AND `foo`.`content` = ?)))");
is_deeply($sql->bind, ['boo', 'bar']);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where_logic('OR');
$sql->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` = ?)");
is_deeply($sql->bind, [qw/ 2 /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where(['foo.id' => {'>' => 2}]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` > ?)");
is_deeply($sql->bind, [qw/ 2 /]);

$sql = ObjectDB::SQL->build('select');
$sql->source('table');
$sql->columns('foo');
$sql->where(['foo.id' => 2, \"a = 'b'"]);
is("$sql", "SELECT `foo` FROM `table` WHERE (`foo`.`id` = ? AND a = 'b')");
is_deeply($sql->bind, [qw/ 2 /]);

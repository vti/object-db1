use Test::More tests => 3;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new(command => 'select');
$sql->source('table');

$sql->columns('foo')->where([id => 2, title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` = '2' AND `title` = 'hello')");

$sql->columns('foo')->where([\'foo.id = 2', title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.id = 2 AND `title` = 'hello')");

$sql->columns('foo')->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.`id` = '2')");

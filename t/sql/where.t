use Test::More tests => 3;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new(command => 'select');
$sql->source('table');

$sql->where([id => 2, title => 'hello']);
is("$sql", "SELECT * FROM `table` WHERE (`id` = '2' AND `title` = 'hello')");

$sql->where([\'foo.id = 2', title => 'hello']);
is("$sql", "SELECT * FROM `table` WHERE (foo.id = 2 AND `title` = 'hello')");

$sql->where(['foo.id' => 2]);
is("$sql", "SELECT * FROM `table` WHERE (foo.`id` = '2')");

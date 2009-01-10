use Test::More tests => 6;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('select');
$sql->source('table');

$sql->columns('foo')->where([id => 2, title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (`id` = ? AND `title` = ?)");
is_deeply($sql->bind, [qw/ 2 hello /]);

$sql->bind([]);
$sql->_string(undef);
$sql->columns('foo')->where([\'foo.id = 2', title => 'hello']);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.id = 2 AND `title` = ?)");
is_deeply($sql->bind, [qw/ hello /]);

$sql->_string(undef);
$sql->bind([]);
$sql->columns('foo')->where(['foo.id' => 2]);
is("$sql", "SELECT `foo` FROM `table` WHERE (foo.`id` = ?)");
is_deeply($sql->bind, [qw/ 2 /]);

use Test::More tests => 3;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('insert');

$sql->table('foo');
is("$sql", "INSERT INTO `foo` DEFAULT VALUES");

$sql->table('foo');
$sql->columns([qw/ a b /]);
$sql->add_columns('c');
is("$sql", "INSERT INTO `foo` (`a`, `b`, `c`) VALUES (?, ?, ?)");

$sql->table('bar')->columns([qw/ bo boo /])->add_columns('booo');
is("$sql", "INSERT INTO `bar` (`bo`, `boo`, `booo`) VALUES (?, ?, ?)");

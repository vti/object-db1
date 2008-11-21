use Test::More tests => 11;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

ok(defined $sql);
is("$sql", "");

$sql->command('insert');
$sql->table('foo');
$sql->columns([qw/ a b /]);
$sql->add_columns('c');
is("$sql", "INSERT INTO foo (a, b, c) VALUES (?, ?, ?)");

$sql->command('insert')->table('bar')->columns([qw/ bo boo /])->add_columns('booo');
is("$sql", "INSERT INTO bar (bo, boo, booo) VALUES (?, ?, ?)");

$sql->command('select')->table('foo')->columns(['*'])->where(id => 2);
is("$sql", "SELECT * FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns(['hello'])->where(id => 2);
is("$sql", "SELECT hello FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns([qw/ hello boo /])->where(id => 2);
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2'");

$sql->clear;
$sql->command('update')->table('foo')->columns([qw/ hello boo /]);
is("$sql", "UPDATE foo SET hello = ?, boo = ?");

$sql->command('update')->table('foo')->columns([qw/ hello boo /])->where(id => 2);
is("$sql", "UPDATE foo SET hello = ?, boo = ? WHERE id = '2'");

$sql->clear;
$sql->command('delete')->table('foo');
is("$sql", "DELETE FROM foo");

$sql->command('delete')->table('foo')->where(id => 2);
is("$sql", "DELETE FROM foo WHERE id = '2'");

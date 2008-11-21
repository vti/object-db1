use Test::More tests => 3;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('select')->table('foo')->columns(['*'])->where(id => 2);
is("$sql", "SELECT * FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns(['hello'])->where(id => 2);
is("$sql", "SELECT hello FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns([qw/ hello boo /])->where(id => 2);
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2'");

use Test::More tests => 4;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('select')->table('foo')->columns(['*'])->where({id => 2});
is("$sql", "SELECT * FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns(['hello'])->where({id => 2});
is("$sql", "SELECT hello FROM foo WHERE id = '2'");

$sql->command('select')->table('foo')->columns([qw/ hello boo /])->where({id => 2});
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2'");

$sql->command('select')
    ->table('foo')
    ->columns([qw/ hello boo /])
    ->where({id => 2})
    ->group_by('foo')
    ->having('foo')
    ->order_by('hello DESC')
    ->limit(2)
    ->offset(1);
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2' GROUP BY foo HAVING foo ORDER BY hello DESC LIMIT 2 OFFSET 1");

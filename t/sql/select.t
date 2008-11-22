use Test::More tests => 5;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('select')->source('foo')->where({id => 2});
is("$sql", "SELECT * FROM foo WHERE id = '2'");

$sql->command('select')->source('foo')->columns(['hello'])->where({id => 2});
is("$sql", "SELECT hello FROM foo WHERE id = '2'");

$sql->command('select')->source('foo')->columns([qw/ hello boo /])->where({id => 2});
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2'");

$sql->command('select')
    ->source('foo')
    ->columns([qw/ hello boo /])
    ->where({id => 2})
    ->group_by('foo')
    ->having('foo')
    ->order_by('hello DESC')
    ->limit(2)
    ->offset(1);
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2' GROUP BY foo HAVING foo ORDER BY hello DESC LIMIT 2 OFFSET 1");



$sql->command('select')->columns([qw/ foo bar /])->source({source => 'table1', join => {op => 'inner', source => 'table2', constraint => 'table1.foo=table2.bar'}});
is("$sql", "SELECT foo, bar FROM table1 INNER JOIN table2 ON table1.foo=table2.bar");

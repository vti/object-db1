use Test::More tests => 9;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where([id => 2]);
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = '2')");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where([id => 2])->source('foo');
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = '2')");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('hello')->where([id => 2]);
is("$sql", "SELECT `hello` FROM `foo` WHERE (`id` = '2')");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns(qw/ hello boo /)
  ->where([id => 2]);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = '2')");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns(qw/ hello boo /)
  ->where([id => 2])->group_by('foo')->having('foo')->order_by('hello DESC')
  ->limit(2)->offset(1);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = '2') GROUP BY foo HAVING foo ORDER BY hello DESC LIMIT 2 OFFSET 1");


$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where("1 > 2");
is("$sql", 'SELECT `foo` FROM `foo` WHERE (1 > 2)');

#$sql->command('select')->source('foo')->where({id => {like => '123%'}});
#is("$sql", 'SELECT * FROM foo WHERE id LIKE 123%');

$sql = ObjectDB::SQLBuilder->build('select')->source({name => 'foo', as => 'boo'})->columns(qw/ foo bar /);
is("$sql", 'SELECT `foo`, `bar` FROM `foo` AS `boo`');

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->columns('foo')->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => 'table1.foo=table2.bar'
    }
)->columns(qw/ bar baz/);

is("$sql", "SELECT table1.`foo`, table2.`bar`, table2.`baz` FROM `table1` INNER JOIN `table2` ON table1.foo=table2.bar");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => 'table1.foo=table2.bar'
    }
)->columns(qw/ foo bar /);
is("$sql", "SELECT table3.`foo`, table3.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON table1.foo=table2.bar");

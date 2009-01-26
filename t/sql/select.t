use Test::More tests => 18;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where([id => 2]);
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns({name => 'foo', as => 'bar'})->where([id => 2]);
is("$sql", "SELECT `foo` AS bar FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns({name => \'foo', as => 'bar'})->where([id => 2]);
is("$sql", "SELECT foo AS bar FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where([id => 2])->source('foo');
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('hello')->where([id => 2]);
is("$sql", "SELECT `hello` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns(qw/ hello boo /)
  ->where([id => 2]);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo.hello')->where([id => 2]);
is("$sql", "SELECT `foo`.`hello` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns(qw/ hello boo /)
  ->where([id => 2])->group_by('foo')->having('foo')->order_by('hello DESC')
  ->limit(2)->offset(1);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?) GROUP BY `foo` HAVING `foo` ORDER BY `hello` DESC LIMIT 2 OFFSET 1");

$sql = ObjectDB::SQLBuilder->build('select')->source('foo')->columns('foo')->where("1 > 2");
is("$sql", 'SELECT `foo` FROM `foo` WHERE (1 > 2)');

#$sql->command('select')->source('foo')->where({id => {like => '123%'}});
#is("$sql", 'SELECT * FROM foo WHERE id LIKE 123%');

$sql = ObjectDB::SQLBuilder->build('select')->source({name => 'foo', as => 'boo'})->columns(qw/ foo bar /);
is("$sql", 'SELECT `foo`, `bar` FROM `foo` AS `boo`');

$sql =
  ObjectDB::SQLBuilder->build('select')->source('table1')
  ->columns('bar_2.foo')->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => {'table1.foo' => 'table2.bar'}
    }
  )->columns(qw/ bar baz/);

is("$sql", "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`");
is("$sql", "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->columns('foo')->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ bar baz/);

is("$sql", "SELECT `table1`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ foo bar /);
is("$sql", "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar`");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ foo bar /)->where(['table3.foo' => 1]);
is("$sql", "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (table3.`foo` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ foo bar /)->where(['foo' => 1]);
is("$sql", "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (`table1`.`foo` = ?)");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ foo bar /)->order_by('addtime')->group_by('foo');
is("$sql", "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table1`.`foo` ORDER BY `table1`.`addtime`");

$sql = ObjectDB::SQLBuilder->build('select')->source('table1')->source('table2')->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => {'table1.foo' => 'table2.bar'}
    }
)->columns(qw/ foo bar /)->order_by('table2.addtime')->group_by('table2.foo');
is("$sql", "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table2`.`foo` ORDER BY `table2`.`addtime`");


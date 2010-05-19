use Test::More tests => 35;

use lib 't/lib';

use ObjectDB::SQL;

use Author;

###### SQL with passed schema class

# passed no source, but class and columns
my $sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->columns('name');
$sql->where([id => 2]);
is("$sql", "SELECT `name` FROM `author` WHERE (`id` = ?)");

# passed no source and no columns, but class
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->where([id => 2]);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with undef columns
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->where([id => 2]);
$sql->columns(undef);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with empty columns
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->where([id => 2]);
$sql->columns('');
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with not params in columns
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->where([id => 2]);
$sql->columns();
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with undef source
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source(undef);
$sql->where([id => 2]);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with empty source
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source('');
$sql->where([id => 2]);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# same as before, but with no params in source
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source();
$sql->where([id => 2]);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# passed no columns, but source and class
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source('author');
$sql->where([id => 2]);
is("$sql", "SELECT `id`, `name`, `password` FROM `author` WHERE (`id` = ?)");

# passed no main source and no columns, but an additional source
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source('articles');
$sql->where([id => 2]);
is("$sql", "SELECT `author`.`id`, `author`.`name`, `author`.`password` FROM `author`, `articles` WHERE (`author`.`id` = ?)");

# passed no main source and no columns, but an additional source with columns
$sql = ObjectDB::SQL->build('select', class=>'Author');
$sql->source('articles');
$sql->columns('title');
$sql->where([id => 2]);
is("$sql", "SELECT `author`.`id`, `author`.`name`, `author`.`password`, `articles`.`title` FROM `author`, `articles` WHERE (`author`.`id` = ?)");


###### SQL without passed schema class

# Pass no source
$sql = ObjectDB::SQL->build('select');
$sql->source();
ok ( !@{$sql->_sources} );

# Pass empty source
$sql = ObjectDB::SQL->build('select');
$sql->source('');
ok ( !@{$sql->_sources} );

# Pass undef source
$sql = ObjectDB::SQL->build('select');
$sql->source(undef);
ok ( !@{$sql->_sources} );

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where([id => 2]);
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns({name => 'foo', as => 'bar'});
$sql->where([id => 2]);
is("$sql", "SELECT `foo` AS bar FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns({name => \'foo', as => 'bar'});
$sql->where([id => 2]);
is("$sql", "SELECT foo AS bar FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where([id => 2]);
$sql->source('foo');
is("$sql", "SELECT `foo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('hello');
$sql->where([id => 2]);
is("$sql", "SELECT `hello` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns(qw/ hello boo /);
$sql->where([id => 2]);
is("$sql", "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->where([id => 2]);
is("$sql", "SELECT `foo`.`hello` FROM `foo` WHERE (`id` = ?)");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->order_by('foo, bar DESC');
is("$sql", "SELECT `foo`.`hello` FROM `foo` ORDER BY `foo`, `bar` DESC");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo.hello');
$sql->order_by('foo    ASC   , bar');
is("$sql", "SELECT `foo`.`hello` FROM `foo` ORDER BY `foo` ASC, `bar`");

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns(qw/ hello boo /);
$sql->where([id => 2]);
$sql->group_by('foo');
$sql->having('foo');
$sql->order_by('hello DESC');
$sql->limit(2);
$sql->offset(1);
is("$sql",
    "SELECT `hello`, `boo` FROM `foo` WHERE (`id` = ?) GROUP BY `foo` HAVING `foo` ORDER BY `hello` DESC LIMIT 2 OFFSET 1"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('foo');
$sql->columns('foo');
$sql->where("1 > 2");
is("$sql", 'SELECT `foo` FROM `foo` WHERE (1 > 2)');

#$sql->command('select')->source('foo')->where({id => {like => '123%'}});
#is("$sql", 'SELECT * FROM foo WHERE id LIKE 123%');

$sql = ObjectDB::SQL->build('select');
$sql->source({name => 'foo', as => 'boo'});
$sql->columns(qw/ foo bar /);
is("$sql", 'SELECT `foo`, `bar` FROM `foo` AS `boo`');

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->columns('bar_2.foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);
is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);


$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->columns('bar_2.foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar', 'table1.bar' => 'hello']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `bar_2`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar` AND `table1`.`bar` = 'hello'"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->columns('foo');
$sql->source(
    {   join       => 'inner',
        name       => 'table2',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ bar baz/);

is("$sql",
    "SELECT `table1`.`foo`, `table2`.`bar`, `table2`.`baz` FROM `table1` INNER JOIN `table2` ON `table1`.`foo` = `table2`.`bar`"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar`"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->where(['table3.foo' => 1]);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (`table3`.`foo` = ?)"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->where(['foo' => 1]);
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` WHERE (`table1`.`foo` = ?)"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->order_by('addtime');
$sql->group_by('foo');
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table1`.`foo` ORDER BY `table1`.`addtime`"
);

$sql = ObjectDB::SQL->build('select');
$sql->source('table1');
$sql->source('table2');
$sql->source(
    {   join       => 'inner',
        name       => 'table3',
        constraint => ['table1.foo' => 'table2.bar']
    }
);
$sql->columns(qw/ foo bar /);
$sql->order_by('table2.addtime');
$sql->group_by('table2.foo');
is("$sql",
    "SELECT `table3`.`foo`, `table3`.`bar` FROM `table1`, `table2` INNER JOIN `table3` ON `table1`.`foo` = `table2`.`bar` GROUP BY `table2`.`foo` ORDER BY `table2`.`addtime`"
);


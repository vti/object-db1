use Test::More tests => 8;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('select')->source('foo')->where({id => 2});
is("$sql", "SELECT * FROM foo WHERE id = '2'");

$sql->command('select')->source('foo')->columns(['hello'])->where({id => 2});
is("$sql", "SELECT hello FROM foo WHERE id = '2'");

$sql->command('select')->source('foo')->columns([qw/ hello boo /])
  ->where({id => 2});
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2'");

$sql->command('select')->source('foo')->columns([qw/ hello boo /])
  ->where({id => 2})->group_by('foo')->having('foo')->order_by('hello DESC')
  ->limit(2)->offset(1);
is("$sql", "SELECT hello, boo FROM foo WHERE id = '2' GROUP BY foo HAVING foo ORDER BY hello DESC LIMIT 2 OFFSET 1");


$sql->command('select')->source('foo')->where("1 > 2");
is("$sql", 'SELECT * FROM foo WHERE 1 > 2');

#$sql->command('select')->source('foo')->where({id => {like => '123%'}});
#is("$sql", 'SELECT * FROM foo WHERE id LIKE 123%');


$sql->command('select')->columns([qw/ foo bar /])->source({name => 'foo', as => 'boo'});
is("$sql", 'SELECT foo, bar FROM foo AS boo');

$sql->command('select')->columns([qw/ foo bar /])->source(
    [   'table1',
        {   join       => 'inner',
            name       => 'table2',
            constraint => 'table1.foo=table2.bar'
        }
    ]
);
is("$sql", "SELECT foo, bar FROM table1 INNER JOIN table2 ON table1.foo=table2.bar");

$sql->command('select')->columns([qw/ foo bar /])->source(
    [   'table1', 'table2',
        {   join       => 'inner',
            name       => 'table3',
            constraint => 'table1.foo=table2.bar'
        },
    ]
);
is("$sql", "SELECT foo, bar FROM table1, table2 INNER JOIN table3 ON table1.foo=table2.bar");

use Test::More tests => 2;

use lib 't/lib';

use User;
use Article;
use Tag;

User->delete_objects;
Article->delete_objects;
Tag->delete_objects;

User->new(
    name     => 'foo',
    password => 'bar',
    articles => [{title => 'hello', tags => {name => 'shit'}}]
)->create;

User->new(
    name     => 'boo',
    password => 'baz',
    articles => [{title => 'hallo', tags => {name => 'good'}}]
)->create;

my @users = User->find_objects(where => ['articles.tags.name' => 'good']);
is(@users, 1);
is($users[0]->column('name'), 'boo');

User->delete_objects;
Article->delete_objects;
Tag->delete_objects;

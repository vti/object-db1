use Test::More tests => 10;

use lib 't/lib';

use User;

User->delete_objects;

User->new(name => 'foo', password => 'bar')->create;

my @users = User->find_objects(columns => 'name');
is(@users, 1);
ok($users[0]->column('id'));
is($users[0]->column('name'), 'foo');
ok(not defined $users[0]->column('password'));

my @users = User->find_objects(columns => [qw/ password name /]);
is(@users, 1);
ok($users[0]->column('id'));
is($users[0]->column('name'), 'foo');
is($users[0]->column('password'), 'bar');

@users = User->find_objects(columns => [{name => \'COUNT(*)', as => 'count'}]);
ok($users[0]->column('id'));
is($users[0]->column('count'), 1);

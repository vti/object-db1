use Test::More tests => 8;

use lib 't/lib';

use User;

User->delete_objects;

User->create(name => 'foo', password => 'bar');

my @users = User->find_objects(columns => 'name');
is(@users, 1);
is($users[0]->column('id'), 1);
is($users[0]->column('name'), 'foo');
ok(not defined $users[0]->column('password'));

my @users = User->find_objects(columns => [qw/ name password /]);
is(@users, 1);
is($users[0]->column('id'), 1);
is($users[0]->column('name'), 'foo');
is($users[0]->column('password'), 'bar');
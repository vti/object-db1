use Test::More tests => 3;

use lib 't/lib';

use User;

User->delete_objects;

User->create(name => 'foo', password => 'bar');

User->update_objects(where => [name => 'foo'], bind => [qw/ haha xexe /]);

@users = User->find_objects;
is(@users, 1);
is($users[0]->column('name'), 'haha');
is($users[0]->column('password'), 'xexe');

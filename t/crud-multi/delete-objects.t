use Test::More tests => 2;

use lib 't/lib';

use User;

User->delete_objects;
is(User->count_objects, 0);

User->create(name => 'foo');
User->create(name => 'bar');
User->delete_objects(where => [name => 'foo']);
is(User->count_objects, 1);

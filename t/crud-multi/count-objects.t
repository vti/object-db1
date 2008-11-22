use Test::More tests => 2;

use lib 't/lib';

use User;

User->delete_objects;

User->create();
is(User->count_objects, 1);

User->create();
is(User->count_objects, 2);

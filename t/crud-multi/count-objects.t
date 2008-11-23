use Test::More tests => 5;

use lib 't/lib';

use User;

User->delete_objects;

User->create(name => 'foo', password => 'bar');
is(User->count_objects, 1);

User->create(name => 'oof', password => 'bar');
is(User->count_objects, 2);

is(User->count_objects(where => [name => 'vti']), 0);
is(User->count_objects(where => [name => 'foo']), 1);
is(User->count_objects(where => [password => 'bar']), 2);

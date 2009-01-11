use Test::More tests => 4;

use lib 't/lib';

use User;

User->delete_objects;

User->begin(behavior => 'immediate');

User->create(name => 'foo');

is(User->count_objects, 1);

User->rollback;

is(User->count_objects, 0);


User->begin(behavior => 'immediate');

User->create(name => 'foo');

is(User->count_objects, 1);

User->commit;

is(User->count_objects, 1);

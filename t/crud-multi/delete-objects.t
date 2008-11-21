use Test::More tests => 1;

use lib 't/lib';

use User;

User->delete_objects;

my @users = User->find_objects;
is(@users, 0);

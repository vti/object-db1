use Test::More tests => 2;

use lib 't/lib';

use Admin;
use UserAdmin;

Admin->delete_objects;
UserAdmin->delete_objects;

my $user = Admin->new(name => 'foo', password => 'bar')->create;
$user->create_related('user_admin', beard => 1);

$user = Admin->new(name => 'boo', password => 'baz')->create;
$user->create_related('user_admin', beard => 0);

my @users = Admin->find_objects(where => ['user_admin.beard' => 1]);
is(@users, 1);
is($users[0]->column('name'), 'foo');

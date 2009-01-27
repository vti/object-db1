use Test::More tests => 10;

use lib 't/lib';

use UserAdmin;
use Admin;
use User;

User->delete_objects;
Admin->delete_objects;
UserAdmin->delete_objects;

my $admin = Admin->new(name => 'root', password => 'foo')->create;
ok($admin);

$admin->create_related('user_admin', beard => 1);
is($admin->column('name'), 'root');
is($admin->column('password'), 'foo');

my $user_admin = $admin->find_related('user_admin');
is($user_admin->column('beard'), 1);
is($admin->count_related('user_admin'), 1);

$admin->update_related('user_admin', bind => [0]);
is($admin->find_related('user_admin')->column('beard'), 0);

$admin = Admin->new(
    name       => 'root2',
    password   => 'foo',
    user_admin => {beard => 1}
);
$admin->create;
ok($admin);
is($admin->find_related('user_admin')->column('beard'), 1);
$admin->update_related('user_admin', bind => [0]);
is($admin->find_related('user_admin')->column('beard'), 0);

$admin = Admin->new(
    name       => 'root3',
    password   => 'foo'
);
$admin->create;
$admin->set_related('user_admin', beard => 1);
is($admin->find_related('user_admin')->column('beard'), 1);

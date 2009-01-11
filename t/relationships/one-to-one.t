use Test::More tests => 6;

use lib 't/lib';

use UserAdmin;
use Admin;

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

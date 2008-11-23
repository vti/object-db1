use Test::More tests => 5;

use lib 't/lib';

use UserAdmin;
use Admin;

my $admin = Admin->create(name => 'root', password => 'foo');
ok($admin);

UserAdmin->create(user_id => $admin->column('id'), beard => 1);
is($admin->column('name'), 'root');
is($admin->column('password'), 'foo');

my $user_admin = $admin->find_related('user_admin');
is($user_admin->column('beard'), 1);
is($admin->count_related('user_admin'), 1);

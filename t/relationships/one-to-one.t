use Test::More tests => 4;

use lib 't/lib';

use UserAdmin;
use Admin;

my $admin = Admin->create(name => 'root', password => 'foo');
UserAdmin->create(user_id => $admin->column('id'), beard => 1);

ok($admin);
is($admin->column('name'), 'root');
is($admin->column('password'), 'foo');

my $user_admin = $admin->find_related('user_admin');
is($user_admin->column('beard'), 1);

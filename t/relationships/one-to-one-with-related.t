use Test::More tests => 8;

use lib 't/lib';

use Admin;
use UserAdmin;

Admin->delete_objects;
UserAdmin->delete_objects;

my $user = Admin->new(name => 'foo', password => 'bar')->create;
$user->create_related('user_admin', beard => 1);

my @users = Admin->find_objects(with => 'user_admin');
$user = shift @users;
ok($user);
is($user->column('name'), 'foo');
is($user->column('password'), 'bar');
is($user->related('user_admin')->column('beard'), 1);

my $users = Admin->find_objects(with => 'user_admin');
$user = $users->next;
ok($user);
is($user->column('name'), 'foo');
is($user->column('password'), 'bar');
is($user->related('user_admin')->column('beard'), 1);

#my @users = Article->find_objects(with => 'user');
#is(@users, 2);
#is($users[0]->related('user')->column('name'), 'foo');
#is($users[1]->related('user')->column('name'), 'foo');


#my $users = Article->find_objects(with => 'user');
#ok($users->isa('ObjectDB::Iterator'));

#my $user = $users->next;
#is($user->related('user')->column('name'), 'foo');

#$user = $users->next;
#is($user->related('user')->column('name'), 'foo');


#$user = Article->find_objects(with => 'user', single => 1);
#is($user->related('user')->column('name'), 'foo');

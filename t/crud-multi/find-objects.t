use Test::More tests => 12;

use lib 't/lib';

use User;

User->delete_objects;

my @users = User->find_objects;
is(@users, 0);

is_deeply([], [User->find_objects]);

User->new(name => 'foo', password => 'bar')->create;

@users = User->find_objects;
is(@users, 1);
is($users[0]->column('name'), 'foo');

my $users = User->find_objects;
ok($users);
while (my $u = $users->next) {
    is($u->column('name'), 'foo');
}

User->new(name => 'root', password => 'boo')->create;
User->new(name => 'boot', password => 'booo')->create;

my $user = User->find_objects(where => [name => 'root'], single => 1);
is($user->column('name'), 'root');

@users = User->find_objects(where => [name => 'root']);
is(@users, 1);
is($users[0]->column('name'), 'root');

@users = User->find_objects(where => [password => 'boo']);
is(@users, 1);
is($users[0]->column('name'), 'root');

@users = User->find_objects(where => [password => 'boooo']);
is(@users, 0);

use Test::More tests => 11;

use lib 't/lib';

use User;

User->delete_objects;

my @users = User->find_objects;
is(@users, 0);

is_deeply([], [User->find_objects]);

User->create(name => 'foo', password => 'bar');

@users = User->find_objects;
is(@users, 1);
is($users[0]->column('name'), 'foo');

my $users = User->find_objects;
ok($users);
while (my $u = $users->next) {
    is($u->column('name'), 'foo');
}

User->create(name => 'root', password => 'boo');
User->create(name => 'root', password => 'booo');

@users = User->find_objects(where => {name => 'root'});
is(@users, 2);
is($users[0]->column('name'), 'root');

@users = User->find_objects(where => {password => 'boo'});
is(@users, 1);
is($users[0]->column('name'), 'root');

@users = User->find_objects(where => {password => 'boooo'});
is(@users, 0);

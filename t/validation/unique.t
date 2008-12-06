use Test::More tests => 4;

use lib 't/lib';

use User;

User->delete_objects;

my $user = User->new(name => 'foo', password => 'boo');
is($user->is_valid, 1);
$user->create;

my $user2 = User->new(name => 'foo', password => 'boo');
is($user2->is_valid, 0);
is_deeply($user2->error, {name => [qw/ unique /]});

is($user->is_valid, 1);

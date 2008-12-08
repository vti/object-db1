use Test::More tests => 2;

use lib 't/lib';

use Unique;

Unique->delete_objects;

my $user = Unique->new(name => 'foo', password => 'boo');
$user->create;
ok(not defined $user->errors);

my $user2 = Unique->new(name => 'foo', password => 'boo');
$user2->create;
is_deeply($user2->errors, {name => [qw/ unique /]});

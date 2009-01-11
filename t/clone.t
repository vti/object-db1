use Test::More tests => 2;

use lib 't/lib';

use User;

my $user = User->new(name => 'foo')->create;
ok($user->column('id'));

my $user2 = $user->clone;
ok(not defined $user2->column('id'));

$user->delete;

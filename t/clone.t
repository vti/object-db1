use Test::More tests => 2;

use lib 't/lib';

use User;

my $user = User->create(name => 'foo');
ok($user->column('id'));

$user = $user->clone;
ok(not defined $user->column('id'));

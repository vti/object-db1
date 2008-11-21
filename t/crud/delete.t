use Test::More tests => 4;

use lib 't/lib';

use User;

my $u = User->create(name => 'foo', password => 'boo');

is(User->delete(id => $u->column('id')), 1);

is(User->delete(id => 345345), '0E0');

eval { User->delete(); };
ok($@);

$u = User->create();
ok($u->delete());

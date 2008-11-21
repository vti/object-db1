use Test::More tests => 2;

use lib 't/lib';

use User;

my $u = User->create(name => 'foo', password => 'boo');

ok(User->delete(id => $u->column('id')));

eval { User->delete(); };
ok($@);

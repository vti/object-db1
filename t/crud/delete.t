use Test::More tests => 4;

use lib 't/lib';

use User;

my $u = User->new(name => 'foo', password => 'boo')->create;

is(User->new(id => $u->column('id'))->delete, 1);

ok(not defined User->new(id => 345345)->delete);

eval { User->new->delete; };
ok($@);

$u = User->new->create;
ok($u->delete);

use Test::More tests => 3;

use lib 't/lib';

use User;

my $u = User->new();

ok($u);

$u->column('foo' => 'bar');
is($u->column('foo'), 'bar');

$u = User->new(foo => 'bar');
is($u->column('foo'), 'bar');

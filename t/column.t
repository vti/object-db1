use Test::More tests => 6;

use lib 't/lib';

use User;

my $u = User->new();

ok($u);

ok(not defined $u->column('id'));

$u->column(id => 'boo');
is($u->column('id'), 'boo');

$u->column(id => undef);
ok(not defined $u->column('id'));

$u->column(id => 'bar');
$u->column('id');
is($u->column('id'), 'bar');

$u = User->new(id => 'foo');
is($u->column('id'), 'foo');

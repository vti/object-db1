use Test::More tests => 19;

use lib 't/lib';

use User;

my $u = User->new();
$u->create();
ok($u);
ok($u->column('id'));
ok(not defined $u->column('name'));
ok(not defined $u->column('password'));

$u = User->new(name => 'foo');
$u->create();
ok($u);
ok($u->column('id'));
is($u->column('name'), 'foo');
ok(not defined $u->column('password'));

$u = User->new(name => 'foo', password => 'bar');
$u->create();
ok($u);
ok($u->column('id'));
is($u->column('name'), 'foo');
is($u->column('password'), 'bar');

$u = User->create();
ok($u);
ok($u->column('id'));
ok(not defined $u->column('name'));
ok(not defined $u->column('password'));

$u = User->create(name => 'bar', password => 'foo');
ok($u->column('id'));
is($u->column('name'), 'bar');
is($u->column('password'), 'foo');

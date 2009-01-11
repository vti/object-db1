use Test::More tests => 20;

use lib 't/lib';

use User;

User->delete_objects;

my $u = User->new;
$u->create;
ok($u);
ok($u->column('id'));
ok(not defined $u->column('name'));
ok(not defined $u->column('password'));
$u->delete;

$u = User->new(name => 'foo');
$u->create;
ok($u);
ok($u->column('id'));
is($u->column('name'), 'foo');
ok(not defined $u->column('password'));
$u->delete;

$u = User->new(name => 'boo', password => 'bar');
$u->create;
ok($u);
ok($u->column('id'));
is($u->column('name'), 'boo');
is($u->column('password'), 'bar');
ok($u->create);
$u->delete;

$u = User->new->create;
ok($u);
ok($u->column('id'));
ok(not defined $u->column('name'));
ok(not defined $u->column('password'));
$u->delete;

$u = User->new(name => 'bar', password => 'foo')->create;
ok($u->column('id'));
is($u->column('name'), 'bar');
is($u->column('password'), 'foo');

$u->delete;

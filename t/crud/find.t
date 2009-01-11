use Test::More tests => 8;

use lib 't/lib';

use User;

my $u_ = User->new(name => 'foo', password => 'boo')->create;

eval { User->new->find };
ok($@);

$u = User->new(id => $u_->column('id'))->find;
is($u->column('id'),       $u_->column('id'));
is($u->column('name'),     'foo');
is($u->column('password'), 'boo');

$u = User->new(id => $u_->column('id'));
$u->find;
is($u->column('id'),       $u_->column('id'));
is($u->column('name'),     'foo');
is($u->column('password'), 'boo');

$u = User->new(id => undef)->find;
ok(not defined $u);

User->delete_objects;

use Test::More tests => 7;

use lib 't/lib';

use User;

my $u_ = User->create(name => 'foo', password => 'boo');

$u = User->find(id => $u_->column('id'));
is($u->column('id'), $u_->column('id'));
is($u->column('name'), 'foo');
is($u->column('password'), 'boo');

$u = User->new(id => $u_->column('id'));
$u->find;
is($u->column('id'), $u_->column('id'));
is($u->column('name'), 'foo');
is($u->column('password'), 'boo');

$u = User->find(id => undef);
is($u->not_found, 1);

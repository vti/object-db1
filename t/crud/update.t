use Test::More tests => 2;

use lib 't/lib';

use User;

my $u = User->create(name => 'foo', password => 'bar');

$u->column(name => 'fuu');
$u->column(password => 'boo');
$u->update;

$u = User->find(id => $u->column('id'));
is($u->column('name'), 'fuu');
is($u->column('password'), 'boo');

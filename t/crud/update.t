use Test::More tests => 2;

use lib 't/lib';

use User;

my $u = User->new(name => 'foo', password => 'bar')->create;

$u->column(name => 'fuu');
$u->column(password => 'boo');
$u->update;

$u = User->new(id => $u->column('id'))->find;
is($u->column('name'), 'fuu');
is($u->column('password'), 'boo');

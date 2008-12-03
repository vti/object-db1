use Test::More tests => 7;

use lib 't/lib';

use User;

my $u = User->new(name => 'bar');

is_deeply($u->to_hash, {name => 'bar'});

is($u->is_in_db, 0);
is($u->is_modified, 0);

$u->column(name => 'bar');
is($u->is_modified, 0);

$u->column(name => 'foo');
is($u->is_modified, 1);

$u->create;
is($u->is_in_db, 1);
is($u->is_modified, 0);

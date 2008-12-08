use Test::More tests => 3;

use lib 't/lib';

use Unique;

Unique->delete_objects;

my $u = Unique->create(name => 'foo', password => 'bar');
my $u2 = Unique->create(name => 'boo', password => 'bar');

$u->update;
ok(not defined $u->errors);

$u->column(name => 'boo');
$u->update;
is_deeply($u->errors, {name => [qw/ unique /]});

$u->column(name => undef);
$u->update;
is_deeply($u->errors, {name => [qw/ null length /]});

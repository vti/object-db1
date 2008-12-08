use Test::More tests => 3;

use lib 't/lib';

use Unique;

Unique->delete_objects;

my $u = Unique->create(name => 'foo', password => 'bar');
ok(not defined $u->errors);

$u->column(name => undef);
$u->delete;
is_deeply($u->errors, {name => [qw/ null length /]});

$u->column(name => 'a');
$u->delete;
is_deeply($u->errors, {name => [qw/ length /]});

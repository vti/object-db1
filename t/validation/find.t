use Test::More tests => 2;

use lib 't/lib';

use Unique;

my $u = Unique->find(name => '12');
ok(not defined $u->errors);

Unique->delete_objects;

my $u = Unique->create(name => 'foo', password => 'bar');
ok(not defined $u->errors);

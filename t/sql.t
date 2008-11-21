use Test::More tests => 2;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

ok(defined $sql);
is("$sql", "");

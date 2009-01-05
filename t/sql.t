use Test::More tests => 1;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new;
ok($sql->isa('ObjectDB::SQL'));

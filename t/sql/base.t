use Test::More tests => 1;

use ObjectDB::SQL::Base;

my $sql = ObjectDB::SQL::Base->new;
ok($sql->isa('ObjectDB::SQL::Base'));

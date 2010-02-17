use Test::More tests => 4;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->build('select');

ok(defined $sql);
ok($sql->isa('ObjectDB::SQL::Select'));

$sql = ObjectDB::SQL->build('insert',
                          table   => 'foo',
                          columns => [qw/ a b c /],
                          bind    => [qw/ a b c/]);
is("$sql", "INSERT INTO `foo` (`a`, `b`, `c`) VALUES (?, ?, ?)");
is_deeply($sql->bind, [qw/ a b c /]);

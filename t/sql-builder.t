use Test::More tests => 4;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('select');

ok(defined $sql);
ok($sql->isa('ObjectDB::SQL::Select'));

$sql = ObjectDB::SQLBuilder->build('insert',
                          table   => 'foo',
                          columns => [qw/ a b c /],
                          bind    => [qw/ a b c/]);
is("$sql", "INSERT INTO `foo` (`a`, `b`, `c`) VALUES (?, ?, ?)");
is_deeply($sql->bind, [qw/ a b c /]);

use Test::More tests => 4;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

ok(defined $sql);
is("$sql", "");

# proxy
$sql = ObjectDB::SQL->new(command => 'insert',
                          table   => 'foo',
                          columns => [qw/ a b c /],
                          bind    => [qw/ a b c/]);
is("$sql", "INSERT INTO foo (a, b, c) VALUES (?, ?, ?)");
is_deeply($sql->bind, [qw/ a b c /]);

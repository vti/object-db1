use Test::More tests => 3;

use ObjectDB::SQLBuilder;

my $sql = ObjectDB::SQLBuilder->build('update');

$sql->table('foo')->columns([qw/ hello boo /])->bind([1, 2]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ?");
is_deeply($sql->bind, [qw/ 1 2 /]);

$sql->table('foo')->columns([qw/ hello boo /])->where([id => 2]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ? WHERE (`id` = '2')");

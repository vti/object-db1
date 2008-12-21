use Test::More tests => 3;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('update')->table('foo')->columns([qw/ hello boo /])->bind([1, 2]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ?");
is_deeply($sql->bind, [qw/ 1 2 /]);

$sql->command('update')->table('foo')->columns([qw/ hello boo /])->where([id => 2]);
is("$sql", "UPDATE `foo` SET hello = ?, boo = ? WHERE (`id` = '2')");

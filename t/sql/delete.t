use Test::More tests => 2;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('delete')->table('foo');
is("$sql", "DELETE FROM `foo`");

$sql->command('delete')->table('foo')->where([id => 2]);
is("$sql", "DELETE FROM `foo` WHERE (`id` = '2')");

use Test::More tests => 2;

use ObjectDB::SQL;

my $sql = ObjectDB::SQL->new();

$sql->command('update')->table('foo')->columns([qw/ hello boo /]);
is("$sql", "UPDATE foo SET hello = ?, boo = ?");

$sql->command('update')->table('foo')->columns([qw/ hello boo /])->where(id => 2);
is("$sql", "UPDATE foo SET hello = ?, boo = ? WHERE id = '2'");

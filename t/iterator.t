use Test::More tests => 1;

use lib 't/lib';

use ObjectDB::Iterator;
use User;

my $u = User->create(name => 'foo', password => 'bar');

my $dbh = User->init_db;
my $sth = $dbh->prepare("SELECT * FROM user");
$sth->execute;

my $i = ObjectDB::Iterator->new(sth => $sth);
ok($i);

while (my $value = $i->next) {
    diag $value;
    #die $value;
}

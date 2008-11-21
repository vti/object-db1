use Test::More tests => 2;

use lib 't/lib';

use ObjectDB::Iterator;
use User;

my $u = User->create(name => 'foo', password => 'bar');

my $dbh = User->init_db;
my $sth = $dbh->prepare("SELECT * FROM user");
$sth->execute;

my $i = ObjectDB::Iterator->new(sth => $sth, class => 'User');
ok($i);

my $count = 0;
while (my $value = $i->next) {
    $count++;
}

ok($count);

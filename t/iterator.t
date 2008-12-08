use Test::More tests => 4;

use lib 't/lib';

use ObjectDB::Iterator;
use User;

User->delete_objects;

User->create(name => 'foo', password => 'bar');
User->create(name => 'bar', password => 'foo');

my $dbh = User->init_db;
my $sth = $dbh->prepare("SELECT * FROM user");
$sth->execute;

my $i = ObjectDB::Iterator->new(sth => $sth, class => 'User');
ok($i);
is($i->step, 0);

my $count = 0;
while (my $value = $i->next) {
    $count++;
}

is($count, 2);
is($i->step, 2);

use Test::More tests => 2;

use lib 't/lib';

use Article;
use User;

my $u = User->create;
$u->create_related('articles', title => 'foo');

my $iterator = $u->related('articles');
ok($iterator->isa('ObjectDB::Iterator'));

my @articles = $u->related('articles');
is(@articles, 1);

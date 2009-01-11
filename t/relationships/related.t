use Test::More tests => 5;

use lib 't/lib';

use Article;
use User;

my $u = User->new(name => 'foo')->create;
$u->create_related('articles', title => 'foo');

my $iterator = $u->related('articles');
ok($iterator->isa('ObjectDB::Iterator'));

my @articles = $u->related('articles');
is(@articles, 1);
ok($articles[0]->isa('Article'));

is($articles[0]->related('user')->column('name'), $u->column('name'));
# cached
is($articles[0]->related('user')->column('name'), $u->column('name'));

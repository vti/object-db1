use Test::More tests => 7;

use lib 't/lib';

use Article;
use User;

my $u = User->create;

Article->delete_objects;

my @articles = $u->find_related('articles');
is(@articles, 0);

Article->create(user_id => $u->column('id'), title => 'boo');
Article->create(user_id => $u->column('id'), title => 'foo');
my @articles = $u->find_related('articles');
is(@articles, 2);
is($articles[0]->column('title'), 'boo');

@articles = $u->find_related('articles', where => [title => 'foo']);
is(@articles, 1);
is($articles[0]->column('title'), 'foo');

$u->delete_related('articles', where => [title => 'boo']);
@articles = $u->find_related('articles', where => [title => 'boo']);
is(@articles, 0);

$u->delete_related('articles');
@articles = $u->find_related('articles');
is(@articles, 0);

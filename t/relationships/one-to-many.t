use Test::More tests => 11;

use lib 't/lib';

use Article;
use User;

my $u = User->new->create;
is($u->count_related('articles'), 0);

Article->delete_objects;

my @articles = $u->find_related('articles');
is(@articles, 0);

Article->new(title => 'mega')->create;

$u->create_related('articles', Article->new(title => 'boo'));
$u->create_related('articles', title => 'foo');
my @articles = $u->find_related('articles', order_by => 'id DESC');
is(@articles, 2);
is($u->count_related('articles'), 2);
is($articles[0]->column('title'), 'foo');

@articles = $u->find_related('articles', where => [title => 'foo']);
is($u->count_related('articles', where => [title => 'foo']), 1);
is(@articles, 1);
is($articles[0]->column('title'), 'foo');

$u->update_related('articles', where => [title => 'foo'], columns => ['title'], bind => ['zoo']);
ok($u->find_related('articles', where => [title => 'zoo']));

$u->delete_related('articles', where => [title => 'boo']);
@articles = $u->find_related('articles', where => [title => 'boo']);
is(@articles, 0);

$u->delete_related('articles');
@articles = $u->find_related('articles');
is(@articles, 0);

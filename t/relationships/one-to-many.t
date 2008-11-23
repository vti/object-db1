use Test::More tests => 11;

use lib 't/lib';

use Article;
use User;

my $u = User->create;
is($u->count_related('articles'), 0);

Article->delete_objects;

my @articles = $u->find_related('articles');
is(@articles, 0);

Article->create(title => 'mega');

Article->create(user_id => $u->column('id'), title => 'boo');
Article->create(user_id => $u->column('id'), title => 'foo');
my @articles = $u->find_related('articles');
is(@articles, 2);
is($u->count_related('articles'), 2);
is($articles[0]->column('title'), 'boo');

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

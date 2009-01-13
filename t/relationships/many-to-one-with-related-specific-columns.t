use Test::More tests => 7;

use lib 't/lib';

use Article;
use User;
use Category;

Article->delete_objects;
User->delete_objects;

my $category = Category->new(title => 'haha')->create;

my $user = User->new(name => 'foo', password => 'bar')->create;
$user->create_related(
    'articles',
    title       => 'zoo',
    category_id => $category->column('id')
);
$user->create_related('articles', title => 'boo');

my @articles = Article->find_objects(
    columns => 'title',
    with    => {name => 'user', columns => 'name'}
);
is(@articles,                                     2);
is($articles[0]->related('user')->column('name'), 'foo');
ok(not defined $articles[0]->related('user')->column('password'));

$article = Article->find_objects(
    with   => ['user', {name => 'category', columns => []}],
    single => 1
);
is($article->related('user')->column('name'),     'foo');
is($article->related('user')->column('password'), 'bar');
ok($article->related('category')->column('id'));
ok(not defined $article->related('category')->column('title'));

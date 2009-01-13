use Test::More tests => 5;

use lib 't/lib';

use Article;
use Category;
use User;

Article->delete_objects;
User->delete_objects;
Category->delete_objects;

my $user = User->new(name => 'foo', password => 'bar')->create;

my $category =
  Category->new(user_id => $user->column('id'), title => 'foo')->create;

$user->create_related(
    'articles',
    title       => 'zoo',
    category_id => $category->column('id')
);

my @articles;

eval { @articles = Article->find_objects(with => ['category.user']); };
ok($@);

@articles = Article->find_objects(with => ['category', 'category.user']);
is($articles[0]->related('category')->column('title'), 'foo');
is($articles[0]->related('category')->related('user')->column('name'), 'foo');

my $articles = Article->find_objects(with => ['category', 'category.user']);
my $article = $articles->next;
is($article->related('category')->column('title'), 'foo');
is($article->related('category')->related('user')->column('name'), 'foo');

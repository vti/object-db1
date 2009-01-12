use Test::More tests => 8;

use lib 't/lib';

use Article;
use User;

Article->delete_objects;
User->delete_objects;

my $user = User->new(name => 'foo', password => 'bar')->create;
$user->create_related('articles', title => 'zoo');
$user->create_related('articles', title => 'boo');

my @articles = Article->find_objects(with => 'user');
is(@articles, 2);
is($articles[0]->related('user')->column('name'), 'foo');
is($articles[1]->related('user')->column('name'), 'foo');


my $articles = Article->find_objects(with => 'user');
ok($articles->isa('ObjectDB::Iterator'));

my $article = $articles->next;
is($article->related('user')->column('name'), 'foo');

$article = $articles->next;
is($article->related('user')->column('name'), 'foo');


$article = Article->find_objects(with => 'user', single => 1);
is($article->related('user')->column('name'), 'foo');


$article = Article->find_objects(with => ['user', 'category'], single => 1);
is($article->related('user')->column('name'), 'foo');

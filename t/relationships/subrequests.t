use Test::More tests => 2;

use lib 't/lib';

use Article;
use Tag;
use ArticleTagMap;

Article->delete_objects;
Tag->delete_objects;
ArticleTagMap->delete_objects;

my $article = Article->new(title => 'foo')->create;
$article->create_related('tags', name => 'one');
$article->create_related('tags', name => 'two');

my $article2 = Article->new(title => 'boo')->create;
$article2->create_related('tags', name => 'one');
$article2->create_related('tags', name => 'two');

is($article->count_related('tags'), 2);

my $articles = Article->find_objects;
ok($articles->isa('ObjectDB::Iterator'));

while (my $article = $articles->next) {
    my @tags = $article->find_related('tags');
}

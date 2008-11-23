use Test::More tests => 3;

use lib 't/lib';

use Article;
use Tag;
use ArticleTagMap;

my $article = Article->create(title => 'foo');
my $tag = Tag->create(name => 'shit');

my $map = ArticleTagMap->create(
    article_id => $article->column('id'),
    tag_id     => $tag->column('id')
);

my $map_article = $map->find_related('article');
is($map_article->column('title'), 'foo');

my $map_tag = $map->find_related('tag');
is($map_tag->column('name'), 'shit');

my @tags = $article->find_related('tags');
is(@tags, 1);

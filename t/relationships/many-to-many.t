use Test::More tests => 8;

use lib 't/lib';

use Article;
use Tag;
use ArticleTagMap;

my $article = Article->create(title => 'foo');
my $tag = Tag->create(name => 'shit');

ArticleTagMap->delete_objects;

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
is($tags[0]->column('article_id'), $article->column('article_id'));
is($tags[0]->column('tag_id'), $tag->column('tag_id'));

#$article->set_related('tags', []);
is($article->count_related('tags', where => [name => 'shot']), 0);
is($article->count_related('tags', where => [name => 'shit']), 1);
is($article->count_related('tags'), 1);


use Test::More tests => 23;

use lib 't/lib';

use Article;
use Tag;
use ArticleTagMap;

Tag->delete_objects;

my $article = Article->new(title => 'foo')->create;
my $tag = Tag->new(name => 'shit')->create;

ArticleTagMap->delete_objects;

my $map = ArticleTagMap->new(
    article_id => $article->column('id'),
    tag_id     => $tag->column('id')
)->create;

my $map_article = $map->find_related('article');
is($map_article->column('title'), 'foo');

my $map_tag = $map->find_related('tag');
is($map_tag->column('name'), 'shit');

my @tags = $article->find_related('tags');
is(@tags, 1);
is($tags[0]->column('article_id'), $article->column('article_id'));
is($tags[0]->column('tag_id'), $tag->column('tag_id'));

is($article->count_related('tags', where => [name => 'shot']), 0);
is($article->count_related('tags', where => [name => 'shit']), 1);
is($article->count_related('tags'), 1);

$article->delete_related('tags');
is($article->count_related('tags'), 0);

Tag->new(name => 'more')->create;

is(Tag->count_objects, 2);

is($article->count_related('tags'), 0);
$article->create_related('tags', name => 'foo');
is($article->count_related('tags'), 1);
is(Tag->count_objects, 3);

$article->create_related('tags', name => 'more');
is($article->count_related('tags'), 2);
is(Tag->count_objects, 3);

$article->set_related('tags', name => 'foo');
is($article->count_related('tags'), 1);
is(Tag->count_objects, 3);

$article->set_related('tags', {name => 'more'});
is($article->count_related('tags'), 1);
is(Tag->count_objects, 3);

$article->set_related('tags', [{name => 'more'}, {name => 'haha'}]);
is($article->count_related('tags'), 2);
is(Tag->count_objects, 4);

$article->set_related('tags', []);
is($article->count_related('tags'), 0);
is(Tag->count_objects, 4);

Article->delete_objects;


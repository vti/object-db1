use Test::More tests => 12;

use lib 't/lib';

use Article;
use Podcast;
use Comment;

Comment->delete_objects;
Article->delete_objects;
Podcast->delete_objects;

my $article = Article->new(title => 'boo')->create;
my $article_comment = $article->create_related('comments', content => 'cool');

my $podcast = Podcast->new(title => 'boo')->create;
my $podcast_comment = $podcast->create_related('comments', content => 'sucks');

is($article_comment->column('master_id'), $article->column('id'));
is($article_comment->column('type'), 'article');

my @article_comments = $article->find_related('comments');
is(scalar @article_comments, 1);
is($article->count_related('comments'), 1);
is($article_comments[0]->column('content'), 'cool');

$article->update_related(
    'comments',
    columns => [qw/ content /],
    bind    => [qw/ cool2 /]
);
is($article->find_related('comments')->next->column('content'), 'cool2');

$article->delete_related('comments');
is($article->count_related('comments'), 0);

is($podcast_comment->column('master_id'), $podcast->column('id'));
is($podcast_comment->column('type'), 'podcast');

my @podcast_comments = $podcast->find_related('comments');
is(scalar @podcast_comments, 1);
is($podcast->count_related('comments'), 1);
is($podcast_comments[0]->column('content'), 'sucks');

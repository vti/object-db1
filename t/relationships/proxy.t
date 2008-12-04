use Test::More tests => 2;

use lib 't/lib';

use Article;
use Podcast;
use Comment;

Comment->delete_objects;
Article->delete_objects;
Podcast->delete_objects;

my $article = Article->create(title => 'foo');
my $article_comment = $article->create_related('comments', content => 'cool');

is($article_comment->find_related('master')->column('title'), 'foo');

my $podcast = Podcast->create(title => 'boo');
my $podcast_comment = $podcast->create_related('comments', content => 'sucks');

is($podcast_comment->find_related('master')->column('title'), 'boo');

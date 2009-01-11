use Test::More tests => 2;

use lib 't/lib';

use Article;
use Tag;

Tag->delete_objects;

my $article = Article->new(
    title => 'foo',
    tags  => [{name => 'one'}, {name => 'two'}]
)->create;

my @tags = $article->find_related('tags');
is(scalar @tags, 2);

is(Tag->count_objects, 2);

Tag->delete_objects;
$article->delete;

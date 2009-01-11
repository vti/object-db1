use Test::More tests => 2;

use lib 't/lib';

use Article;
use Tag;

Tag->delete_objects;
Article->delete_objects;

Article->new(title => 'foo', tags => [{name => 'rab'}, {name => 'bar'}])->create;

Article->new(title => 'boo', tags => [{name => 'baz'}, {name => 'zab'}])->create;

my @articles = Article->find_objects(where => ['tags.name' => 'rab']);
is(@articles, 1);
is($articles[0]->column('title'), 'foo');

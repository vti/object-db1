use Test::More tests => 6;

use lib 't/lib';

use Article;

Article->delete_objects;

my @articles = Article->find_objects;
is(@articles, 0);

foreach (1 .. 11) {
    Article->new(title => 'foo', content => $_)->create;
}

@articles = Article->find_objects(page => 1, page_size => 10);
is(@articles, 10);

@articles = Article->find_objects(page => 1);
is(@articles, 10);

@articles = Article->find_objects(page => 3, page_size => 10);
is(@articles, 0);

@articles = Article->find_objects(page => 'a', page_size => 10);
is(@articles, 11);

@articles = Article->find_objects(page => 2, page_size => 5);
is(@articles, 5);

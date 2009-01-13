use Test::More tests => 10;

use lib 't/lib';

use Article;

Article->delete_objects;

my @articles = Article->find_objects;
is(@articles, 0);

foreach my $i (1 .. 11) {
    Article->new(title => $i)->create;
}

@articles = Article->find_objects(page => 0, page_size => 10);
is(@articles, 10);

@articles = Article->find_objects(page => 1, page_size => 10);
is(@articles, 10);

@articles = Article->find_objects(page => 1);
is(@articles, 10);

@articles = Article->find_objects(page => 3, page_size => 10);
is(@articles, 0);

@articles = Article->find_objects(page => 'a', page_size => 10);
is(@articles, 10);

@articles = Article->find_objects(page => '9a', page_size => 10);
is(@articles, 10);

@articles = Article->find_objects(page => 2, page_size => 5);
is(@articles, 5);

@articles = Article->find_objects(page => 2, page_size => 5, single => 1);
is(@articles, 1);
is($articles[0]->column('title'), 1);

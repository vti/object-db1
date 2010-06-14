#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;
plan skip_all => "SKIP";

plan tests => 68;

use lib 't/lib';

use Author;
use Article;
use Podcast;
use Category;
use Comment;

# Create an author with article and comments on article, create category
Category->new(id => 1, title => "stuff1")->create;
Category->new(id => 2, title => "stuff2")->create;
Category->new(id => 3, title => "stuff3")->create;

# Add at least two comments to make sure that if ( $map->{$sign} ) in
# _map_rows_to_objects is tested
my $author = Author->new(
    name     => 'foo',
    articles => [
        {   title    => 'article title',
            comments => [
                {content => 'comment content'},
                {content => 'comment content second'}
            ],
            category_id => 1
        },
        {title => 'article title2', category_id => 2},
        {   title       => 'article title3',
            comments    => [{content => 'comment content3'},],
            category_id => 3
        }
    ]
)->create;

# First simple test
my $authors = Author->new->find(with => [qw/articles articles.comments/]);
is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is($authors->[0]->related('articles')->[1]->column('title'),
    'article title2');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);


# Same tests with autoload of articles
#$authors = Author->new->find(with => [qw/articles.comments/]);
#is(@$authors,                                                1);
#is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
#is($authors->[0]->related('articles')->[1]->column('title'),
    #'article title2');
#is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      #->column('content'),
    #'comment content'
#);

# Save data for validation purposes
my $article_id;
my $comment_master_id;
my $comment_id;

ok($article_id = $authors->[0]->related('articles')->[0]->column('id'));
ok($comment_master_id =
      $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('master_id'));
ok($comment_id =
      $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('id'));


# Make sure that articles do not load a second time
$authors = Author->new->find(with => [qw/articles.comments articles/]);
is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is($authors->[0]->related('articles')->[1]->column('title'),
    'article title2');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);


# Add another level to up the ante
Podcast->new(id => $comment_master_id, title => 'pod title')->create;


# Find all authors with all articles with all comments with podcast
$authors =
  Author->new->find(
    with => [qw/articles articles.comments articles.comments.podcast/]);
is(@$authors,                                                1);
is(@{$authors->[0]->related('articles')},                    3);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[1]
      ->column('content'),
    'comment content second'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->related('podcast')->column('title'),
    'pod title'
);
is($authors->[0]->related('articles')->[2]->column('title'),
    'article title3');
is( $authors->[0]->related('articles')->[2]->related('comments')->[0]
      ->column('content'),
    'comment content3'
);

# Same test, but different format of commands
$authors = Author->new->find(with => [qw/articles.comments.podcast/]);
is(@$authors,                                                1);
is(@{$authors->[0]->related('articles')},                    3);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[1]
      ->column('content'),
    'comment content second'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->related('podcast')->column('title'),
    'pod title'
);
is($authors->[0]->related('articles')->[2]->column('title'),
    'article title3');
is( $authors->[0]->related('articles')->[2]->related('comments')->[0]
      ->column('content'),
    'comment content3'
);

# Find all authors with all articles with all comments with podcast, also find category
$authors = Author->new->find(
    with => [
        qw/articles articles.comments articles.comments.podcast articles.category/
    ]
);
is(@$authors,                                                1);
is(@{$authors->[0]->related('articles')},                    3);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[1]
      ->column('content'),
    'comment content second'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->related('podcast')->column('title'),
    'pod title'
);
is( $authors->[0]->related('articles')->[0]->related('category')
      ->column('title'),
    'stuff1'
);
is( $authors->[0]->related('articles')->[1]->related('category')
      ->column('title'),
    'stuff2'
);
is($authors->[0]->related('articles')->[2]->column('title'),
    'article title3');
is( $authors->[0]->related('articles')->[2]->related('comments')->[0]
      ->column('content'),
    'comment content3'
);
is( $authors->[0]->related('articles')->[2]->related('category')
      ->column('title'),
    'stuff3'
);

# Same tests with autoload of articles and comments
$authors =
  Author->new->find(with => [qw/articles.comments.podcast articles.category/]);
is(@$authors,                                                1);
is(@{$authors->[0]->related('articles')},                    3);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[1]
      ->column('content'),
    'comment content second'
);
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->related('podcast')->column('title'),
    'pod title'
);
is( $authors->[0]->related('articles')->[0]->related('category')
      ->column('title'),
    'stuff1'
);
is( $authors->[0]->related('articles')->[1]->related('category')
      ->column('title'),
    'stuff2'
);
is($authors->[0]->related('articles')->[2]->column('title'),
    'article title3');
is( $authors->[0]->related('articles')->[2]->related('comments')->[0]
      ->column('content'),
    'comment content3'
);
is( $authors->[0]->related('articles')->[2]->related('category')
      ->column('title'),
    'stuff3'
);

# Find articles, than comments, than category
$authors =
  Author->new->find(with => [qw/articles articles.comments articles.category/]);
is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('category')
      ->column('title'),
    'stuff1'
);
is( $authors->[0]->related('articles')->[1]->related('category')
      ->column('title'),
    'stuff2'
);
is( $authors->[0]->related('articles')->[2]->related('category')
      ->column('title'),
    'stuff3'
);

# same tests with autoload of articles
$authors = Author->new->find(with => [qw/articles.comments articles.category/]);
is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);
is( $authors->[0]->related('articles')->[0]->related('category')
      ->column('title'),
    'stuff1'
);
is( $authors->[0]->related('articles')->[1]->related('category')
      ->column('title'),
    'stuff2'
);
is( $authors->[0]->related('articles')->[2]->related('category')
      ->column('title'),
    'stuff3'
);

# Find articles and comments with where constraint
$authors = Author->new->find(
    where => ['articles.comments.type' => 'article'],
    with  => [qw/articles articles.comments/]
);
is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);

### TO DO: # Find comments, than category -> add one level (podcast)
### TO DO: # add even more articles, categories, podcasts to check if _map_rows_to_objects works correctly


# Cleanup
Author->new->delete;
Podcast->new->delete;
Category->new->delete;
Comment->new->delete;

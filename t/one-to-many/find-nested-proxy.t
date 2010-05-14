#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 10;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'foo',
    articles => {title => 'foo', comments => [{content => 'bar'}]}
);

$author->create;

my $authors = Author->find(with => [qw/articles articles.comments/]);

is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'foo');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);

$authors = Author->find(
    where => ['articles.comments.type' => 'article'],
    with  => [qw/articles articles.comments/]
);

is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'foo');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);

$author->delete;




### Test a case where there are two comments of diffent type with the same master_id
use Article;
use Podcast;
use Comment;

# Clean up data
Article->delete; # Data from previous tests left from outside of this file
Comment->delete; # just to be sure

# Create one comment via Article and one comment via Podcast with the same master_id
my $article = Article->new( id => 999, comments => [{ title => 'test1' }] )->create;
my $podcast = Podcast->new( id => 999, comments => [{ title => 'test1' }] )->create;

# Read comments from db, just to make sure data is correct in next test
my $comments = Comment->find( order_by => 'type' );
is(@$comments, 2);
ok( $comments->[0]->column('type') eq 'article' &&
    $comments->[0]->column('master_id') eq '999' );
ok( $comments->[1]->column('type') eq 'podcast' &&
    $comments->[1]->column('master_id') eq '999' );

# Find all articles with related comments
my $articles = Article->find(
    with => ['comments']
);

# Article should have only one comment, because a second comment with same master id
# belongs to podcast, not article
is( @{$articles->[0]->related('comments')}, 2);


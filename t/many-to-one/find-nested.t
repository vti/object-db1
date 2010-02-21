#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Article;
use Category;
use Comment;

my @categories;

push @categories,
  Category->new(
    title    => 'bar',
    articles => {
        title    => 'foo',
        comments => {content => 'baz'}
    }
  )->create;

is_deeply(Comment->find(where => ['article.category.title' => 'foo']), []);

my $comments = Comment->find(
    where => ['article.category.title' => 'bar'],
    with => ['article', 'article.category']
);

is(@$comments, 1);
is($comments->[0]->related('article')->related('category')->column('title'),
    'bar');

$categories[0]->delete;

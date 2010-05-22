#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 5;

use lib 't/lib';

use Author;
use Category;

my $category = Category->new(title => 'general')->create;

my $author = Author->new(
    name     => 'foo',
    articles => [
        {category_id => $category->column('id'), title => 'foo'},
        {title       => 'foo'}
    ]
)->create;

ok($author);

my $authors = Author->new->find(where => ['articles.category.title' => 'foo']);

is_deeply($authors, []);

$authors = Author->new->find(
    where => ['articles.category.title' => 'general'],
    with => ['articles', 'articles.category']
);


is(@$authors, 1);

my $articles = $authors->[0]->related('articles');

is(@$articles, 1);

is($articles->[0]->column('title'), 'foo');

$author->delete;
$category->delete;

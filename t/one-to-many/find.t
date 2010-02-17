#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'foo',
    articles => [{title => 'foo'}, {title => 'foo'}]
)->create;

ok($author);

my $authors = Author->find(where => ['articles.title' => 'bar']);

is_deeply($authors, []);

$authors =
  Author->find(where => ['articles.title' => 'foo'], with => 'articles');

is(@$authors, 1);

my $articles = $authors->[0]->related('articles');

is(@$articles, 2);

is($articles->[0]->column('title'), 'foo');

$author->delete;

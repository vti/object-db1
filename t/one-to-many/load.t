#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => 'TODO';

plan => 3;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors,
  Author->new(
    name     => 'foo',
    articles => [{title => 'bar'}, {title => 'baz'}]
  )->create;

my $author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'articles');

my $articles = $author->related('articles');
is(@$articles, 2);

is($articles->[0]->column('title'), 'bar');
is($articles->[1]->column('title'), 'baz');

$authors[0]->delete;

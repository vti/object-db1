#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors,
  Author->new(name => 'foo', articles => {title => 'foo'})->create;

my $author = Author->new(id => $authors[0]->column('id'))->load;

my $articles = $author->find_related('articles');

is(@$articles,                      1);
is($articles->[0]->column('title'), 'foo');

$authors[0]->delete;

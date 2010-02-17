#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors,
  Author->new(name => 'foo', articles => {title => 'foo'})->create;

ok($authors[0]->update_related('articles' => {set => {title => 'bar'}}));

my $author = Author->new(id => $authors[0]->column('id'))->load;

my $articles = $author->find_related('articles');
is(@$articles, 1);

is($articles->[0]->column('title'), 'bar');

$authors[0]->delete;

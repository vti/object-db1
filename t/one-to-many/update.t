#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors,
  Author->new(name => 'foo', articles => {title => 'foo'})->create;

$authors[0]->related('articles')->[0]->column(title => 'bar');
ok($authors[0]->update);

my $author = Author->new(id => $authors[0]->column('id'))->load;

my $articles = $author->load_related('articles');
is(@$articles, 1);

is($articles->[0]->column('title'), 'bar');

$author->column(name => 'bar');
$articles->[0]->column(title => 'foo');
$author->update;

$author = Author->new(id => $authors[0]->column('id'))->load;
is($author->column('name'), 'bar');

$articles = $author->find_related('articles');

is(@$articles, 1);

is($articles->[0]->column('title'), 'foo');

$authors[0]->delete;

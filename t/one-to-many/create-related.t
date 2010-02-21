#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors, Author->new(name => 'foo')->create;

my $articles = $authors[0]->create_related('articles' => {title => 'bar'});

ok($articles);
is($articles->column('title'), 'bar');

my $author = Author->new(id => $authors[0]->column('id'))->load;

$articles = $author->find_related('articles');

is(@$articles,                      1);
is($articles->[0]->column('title'), 'bar');

$authors[0]->delete;

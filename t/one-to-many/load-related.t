#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;

my @authors;

push @authors,
  Author->new(name => 'foo', articles => {title => 'foo'})->create;

my $author = Author->new(id => $authors[0]->column('id'))->load;

my $articles = $author->load_related('articles');

is(@$articles,                      1);
is($articles->[0]->column('title'), 'foo');

$articles = $author->related('articles');

is(@$articles,                      1);
is($articles->[0]->column('title'), 'foo');

$authors[0]->delete;

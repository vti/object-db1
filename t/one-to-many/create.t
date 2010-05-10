#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 6;

use lib 't/lib';

use Author;
use Article;

my $author = Author->new(
    name => 'foo',
    articles =>
      [{title => 'foo', comments => {content => 'foo'}}, {title => 'bar'}]
)->create;

ok($author);

my $articles = $author->related('articles');

is(@$articles, 2);

is($articles->[0]->column('author_id'), $author->column('id'));
is($articles->[0]->column('title'),     'foo');
is($articles->[0]->related('comments')->[0]->column('content'), 'foo');
is($articles->[0]->related('comments')->[0]->column('type'),    'article');

$author->delete;

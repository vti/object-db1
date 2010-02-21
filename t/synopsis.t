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

my $author = Author->new(
    name     => 'foo',
    articles => [
        {title => 'foo', tags => {name => 'people'}},
        {title => 'bar', tags => [{name => 'unix'}, {name => 'perl'}]}
    ]
)->create;

ok($author);

my $comment =
  $author->related('articles')->[0]
  ->create_related('comments' => {content => 'foo'});

ok($comment);

my $articles = Article->find(where => ['tags.name' => 'unix']);
is(@$articles, 1);

ok($author->delete);

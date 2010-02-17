#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use Author;
use Article;

my $author = Author->new(
    name     => 'foo',
    articles => [{title => 'foo'}, {title => 'bar'}]
)->create;

ok($author);

my $articles = $author->related('articles');
is(@$articles,                          2);
is($articles->[0]->column('author_id'), $author->column('id'));
is($articles->[0]->column('title'),     'foo');

$author->delete;

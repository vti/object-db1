#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles, Article->new(name => 'foo', tags => {name => 'foo'})->create;

my $article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'tags');

my $tags = $article->related('tags');

is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

$articles[0]->delete;
Tag->delete(where => [name => [qw/foo/]]);

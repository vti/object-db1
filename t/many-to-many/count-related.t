#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles, Article->new(name => 'foo', tags => {name => 'foo'})->create;

my $article = Article->new(id => $articles[0]->column('id'))->load;

is($article->count_related('tags'), 1);

$articles[0]->delete;
Tag->delete(where => [name => [qw/foo/]]);

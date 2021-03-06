#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Article;
use ArticleTagMap;
use Tag;

my @articles;

push @articles, Article->new(name => 'foo', tags => {name => 'foo'})->create;

my $article = Article->new(id => $articles[0]->column('id'))->load;

my $tags = $article->load_related('tags');

is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

$tags = $article->related('tags');

is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

$articles[0]->delete;
Tag->new->delete(where => [name => [qw/foo/]]);

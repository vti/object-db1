#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Article;
use ArticleTagMap;
use Tag;

my $id;

my $article = Article->new(name => 'foo', tags => {name => 'foo'})->create;

$id = $article->column('id');

$article->delete;

ok(not defined Article->new(id => $id)->load);

ok( not defined ArticleTagMap->new->find(where => [article_id => $id], single => 1)
);

my $tag = Tag->new(name => 'foo')->load;
ok($tag);

$tag->delete;

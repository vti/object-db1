#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 6;

use lib 't/lib';

use Article;
use ArticleTagMap;
use Tag;

my $id;

my $article =
  Article->new(name => 'foo', tags => [{name => 'foo'}, {name => 'bar'}])
  ->create;

$id = $article->column('id');

$article->delete_related('tags', {where => [name => 'bar']});
is(@{$article->related('tags')}, 1);
is($article->related('tags')->[0]->column('name'), 'foo');

$article->delete_related('tags');
ok(!$article->related('tags'));

ok( not defined ArticleTagMap->new->find(where => [article_id => $id],
        single => 1));

$article = Article->new(id => $id)->load;

ok($article);

$article->delete;

my $tag = Tag->new(name => 'foo')->load;

ok($tag);

$tag->delete;

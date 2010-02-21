#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 6;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles, Article->new(title => 'foo', tags => {name => 'foo'})->create;

$articles[0]->related('tags')->[0]->column(name => 'bar');
ok($articles[0]->update);

my $article = Article->new(id => $articles[0]->column('id'))->load;

my $tags = $article->load_related('tags');

is(@$tags,                     1);
is($tags->[0]->column('name'), 'bar');

$article->column(title => 'bar');
$tags->[0]->column(name => 'foo');
$article->update;

$article = Article->new(id => $articles[0]->column('id'))->load;

is($article->column('title'), 'bar');

$tags = $article->find_related('tags');

is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

$articles[0]->delete;
Tag->delete(where => [name => [qw/foo/]]);

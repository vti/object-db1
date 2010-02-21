#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use Article;
use Category;

my @articles;
my @categories;

push @categories, Category->new(title => 'bar')->create;

push @articles,
  Article->new(title => 'foo', category_id => $categories[0]->column('id'))
  ->create;

my $article = Article->new(id => $articles[0]->column('id'))->load;

my $category = $article->find_related('category');

ok($category);
is($category->column('title'), 'bar');

$articles[0]->delete;
$categories[0]->delete;

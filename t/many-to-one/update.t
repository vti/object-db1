#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';

use Category;
use Article;

my @articles;
my @categories;

push @categories, Category->new(title => 'bar')->create;

push @articles,
  Article->new(title => 'foo', category_id => $categories[0]->column('id'))
  ->create;

$articles[0]->load_related('category');
$articles[0]->related('category')->column(title => 'foo');
ok($articles[0]->update);

my $category =
  Article->new(id => $articles[0]->column('id'))->load(with => 'category');

ok($category);
$category = $articles[0]->related('category');
ok($category);
is($category->column('title'), 'foo');

$articles[0]->column(title => 'bar');
$category->column(title => 'bar');
$articles[0]->update;

my $article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'category');

is($article->column('title'), 'bar');

$category = $article->related('category');
ok($category);
is($category->column('title'), 'bar');

$articles[0]->delete;
$categories[0]->delete;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Article;
use Category;

my @categories;
my @articles;

push @categories, Category->new(title => 'foo')->create;

push @articles,
  Article->new(title => 'bar', category_id => $categories[0]->column('id'))
  ->create;

my $article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'category');

my $category = $article->related('category');
ok($category);
is($category->column('title'), 'foo');

$articles[0]->delete;
$categories[0]->delete;

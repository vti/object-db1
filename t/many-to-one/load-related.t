#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

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

my $category = $article->load_related('category');

ok($category);
$category = $article->related('category');
ok($category);
is($category->column('title'), 'bar');

$articles[0]->delete;
$categories[0]->delete;

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

ok($articles[0]->update_related('category' => {set => {title => 'foo'}}));

my $article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'category');

my $category = $article->related('category');
ok($category);
is($category->column('title'), 'foo');

$articles[0]->delete;
$categories[0]->delete;

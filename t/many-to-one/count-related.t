#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

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

is($article->count_related('category'), 1);

$articles[0]->delete;
$categories[0]->delete;

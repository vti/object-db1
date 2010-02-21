#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Article;
use Category;

my @articles;
my @categories;

push @categories, Category->new(title => 'bar')->create;

push @articles,
  Article->new(title => 'foo', category_id => $categories[0]->column('id'))
  ->create;

is_deeply(Article->find(where => ['category.title' => 'foo']), []);

my $articles =
  Article->find(where => ['category.title' => 'bar'], with => 'category');

is(@$articles,                                           1);
is($articles->[0]->related('category')->column('title'), 'bar');

$articles[0]->delete;
$categories[0]->delete;

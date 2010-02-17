#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use Article;

my @articles;

foreach my $i (1 .. 11) { push @articles, Article->new(title => $i)->create; }

my @data = (
    {page => 0,    page_size => 10, total => 10},
    {page => 1,    page_size => 10, total => 10},
    {page => 1,    total     => 10},
    {page => 3,    page_size => 10, total => 0},
    {page => 'a',  page_size => 10, total => 10},
    {page => '9a', page_size => 10, total => 10},
    {page => 2,    page_size => 10, total => 1},
    {page => 2,    page_size => 5,  total => 5}
);

foreach my $data (@data) {
    my $articles = Article->find(
        page      => $data->{page},
        page_size => $data->{page_size}
    );

    is(@$articles, $data->{total});
}

my $article = Article->find(page => 2, page_size => 5, single => 1);
is($article->column('title'), 1);

$_->delete for @articles;

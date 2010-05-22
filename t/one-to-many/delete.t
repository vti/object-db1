#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;
use Article;
use Comment;

my $author_id;
my $article_id;

my $author = Author->new(
    name     => 'foo',
    articles => [
        {   title    => 'foo',
            comments => {content => 'bar'}
        },
        {title => 'bar'},
    ]
)->create;

is(@{$author->related('articles')}, 2);

$author_id  = $author->column('id');
$article_id = $author->related('articles')->[0]->column('id');

$author->delete;

ok(not defined Author->new(id => $author_id)->load);

is_deeply(Article->new->find(where => [author_id => $author_id]), []);

ok( not defined Comment->new->find(
        where  => [type => 'article', master_id => $article_id],
        single => 1
    )
);

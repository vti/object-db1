#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Article;
use Comment;

my $id;

my $author =
  Article->new(name => 'foo', comments => {title => 'foo'})->create;
$id = $author->column('id');

$author->delete_related('comments');

ok( not defined Comment->find(
        where  => [type => 'article', master_id => $id],
        single => 1
    )
);

my $article = Article->new(id => $id)->load;
ok($article);

$article->delete;

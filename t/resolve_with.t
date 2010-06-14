#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 3;

use lib 't/lib';

use Author;
use Article;
use Comment;
use ObjectDB::SQL::Select;
use ObjectDB::Chain;

my $author = Author->new;
my $sql = ObjectDB::SQL::Select->new;

my $chain = ObjectDB::Chain->new(parent => $author, sql => $sql);
$chain->_resolve_with();
$chain->_resolve_with([]);

$sql = ObjectDB::SQL::Select->new;
$chain = ObjectDB::Chain->new(parent => $author, sql => $sql);
$chain->_resolve_with(['articles']);
is_deeply(
    $sql->sources,
    [   {   name       => 'article',
            as         => 'article',
            columns    => [Article->schema->columns],
            join       => 'left',
            constraint => ['article.author_id', 'author.id']
        }
    ]
);

$sql = ObjectDB::SQL::Select->new;
$chain = ObjectDB::Chain->new(parent => $author, sql => $sql);
$chain->_resolve_with(['articles', 'articles.comments']);
is_deeply(
    $sql->sources,
    [   {   name       => 'article',
            as         => 'article',
            columns    => [Article->schema->columns],
            join       => 'left',
            constraint => ['article.author_id', 'author.id']
        },
        {   name    => 'comment',
            as      => 'comment',
            columns => [Comment->schema->columns],
            join    => 'left',
            constraint =>
              ['comment.master_id', 'article.id', 'comment.type', 'article']
        }
    ]
);

$sql = ObjectDB::SQL::Select->new;
$chain = ObjectDB::Chain->new(parent => $author, sql => $sql);
$chain->_resolve_with(['articles.comments']);
is_deeply(
    $sql->sources,
    [   {   name       => 'article',
            as         => 'article',
            columns    => [Article->schema->columns],
            join       => 'left',
            constraint => ['article.author_id', 'author.id']
        },
        {   name    => 'comment',
            as      => 'comment',
            columns => [Comment->schema->columns],
            join    => 'left',
            constraint =>
              ['comment.master_id', 'article.id', 'comment.type', 'article']
        }
    ]
);

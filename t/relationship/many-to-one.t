#!perl

use strict;
use warnings;

use Test::More tests => 4;

use ObjectDB::Relationship::ManyToOne;

use lib 't/lib';

my $rel = ObjectDB::Relationship::ManyToOne->new(
    name       => 'author_rel',
    type       => 'many to one',
    class      => 'Author',
    orig_class => 'Article',
    map        => {author_id => 'id'},
    join_args  => [title => 'foo']
);
ok($rel);

is($rel->related_table, 'author');

is_deeply(
    $rel->to_source,
    {   name       => 'author',
        as         => 'author',
        join       => 'left',
        constraint => [
            'author.id'    => 'article.author_id',
            'author.title' => 'foo'
        ]
    }
);

is_deeply(
    $rel->to_source(rel_as => 'articles'),
    {   name       => 'author',
        as         => 'author',
        join       => 'left',
        constraint => [
            'author.id'    => 'article.author_id',
            'author.title' => 'foo'
        ]
    }
);

use strict;
use warnings;

use Test::More tests => 6;

use ObjectDB::Relationship::ManyToMany;

use lib 't/lib';

my $rel = ObjectDB::Relationship::ManyToMany->new(
    name       => 'tags',
    orig_class => 'Article',
    type       => 'many to many',
    map_class  => 'ArticleTagMap',
    map_from   => 'article',
    map_to     => 'tag'
);
ok($rel);

is($rel->related_table, 'tag');

is_deeply($rel->to_map_source,
    {
        name       => 'article_tag_map',
        join       => 'left',
        constraint => ['article.id' => 'article_tag_map.article_id']
    }
);

is_deeply($rel->to_self_map_source,
    {
        name       => 'article_tag_map',
        join       => 'left',
        constraint => ['tag.id' => 'article_tag_map.tag_id']
    }
);

is_deeply($rel->to_source,
    {
        name       => 'tag',
        as         => 'tag',
        join       => 'left',
        constraint => ['tag.id' => 'article_tag_map.tag_id']
    }
);

is_deeply($rel->to_self_source,
    {
        name       => 'article',
        join       => 'left',
        as         => 'article',
        constraint => ['article.id' => 'article_tag_map.article_id']
    }
);

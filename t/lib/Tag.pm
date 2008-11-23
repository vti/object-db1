package Tag;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table          => 'tag',
    columns        => [qw/ id name /],
    primary_keys   => ['id'],
    auto_increment => 'id',
    unique_keys    => ['name'],

    relationships => {
        articles => {
            type      => 'many to many',
            map_class => 'ArticleTagMap',
            map_from  => 'tag',
            map_to    => 'article'
        }
    }
);

1;

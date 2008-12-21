package Article;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table          => 'article',
    columns        => [qw/ id user_id title name /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        user => {
            type  => 'many to one',
            class => 'User',
            map   => {user_id => 'id'}
        },
        tags => {
            type      => 'many to many',
            map_class => 'ArticleTagMap',
            map_from  => 'article',
            map_to    => 'tag'
        },
        comments => {
            type  => 'one to many',
            class => 'Comment',
            where => {type => 'article'},
            map   => {id => 'master_id'}
        }
    }
);

sub tags { shift->related('tags') }

1;

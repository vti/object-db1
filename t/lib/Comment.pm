package Comment;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table        => 'comment',
    columns      => [qw/ master_id type content /],
    primary_keys => [qw/ master_id type /],

    relationships => {
        master => {
            type      => 'proxy',
            proxy_key => 'type',
        },
        article => {
            type  => 'many to one',
            class => 'Article',
            map   => {master_id => 'id'}
        },
        podcast => {
            type  => 'many to one',
            class => 'Podcast',
            map   => {master_id => 'id'}
        }
    }
);

1;

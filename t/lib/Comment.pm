package Comment;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table        => 'comment',
    columns      => [qw/id master_id type content/],
    primary_keys => [qw/id/],

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

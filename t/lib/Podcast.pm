package Podcast;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table          => 'podcast',
    columns        => [qw/ id title /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        comments => {
            type  => 'one to many',
            class => 'Comment',
            where => {type => 'podcast'},
            map   => {id => 'master_id'}
        }
    }
);

1;

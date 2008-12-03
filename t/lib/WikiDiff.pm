package WikiDiff;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table          => 'wiki_diff',
    columns        => [qw/ id wiki_id title addtime revision /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        wiki => {
            type  => 'many to one',
            class => 'Wiki',
            map   => {wiki_id => 'id'}
        }
    }
);

1;

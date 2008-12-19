package Wiki;

use strict;
use warnings;

use base 'DB';

use ObjectDB::MixIn::VCS;

__PACKAGE__->meta(
    table          => 'wiki',
    columns        => [qw/ id title addtime revision /, user_id => { no_vcs => 1 }],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        diffs => {
            type  => 'one to many',
            class => 'WikiDiff',
            map   => {id => 'wiki_id'}
        }
    }
);

1;

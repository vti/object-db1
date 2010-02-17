package Family;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table   => 'family',
    columns => [
        qw/id parent_id name/,
    ],
    primary_keys   => 'id',
    auto_increment => 'id',
    relationships  => {
        parent => {
            type  => 'many to one',
            class => 'Family',
            map   => {parent_id => 'id'}
        },
        ansestors => {
            type  => 'one to many',
            class => 'Family',
            map   => {id => 'parent_id'}
        }
    }
);

1;

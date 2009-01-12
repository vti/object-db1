package Category;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table          => 'category',
    columns        => [qw/ id title /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        articles => {
            type  => 'one to many',
            class => 'Article',
            map   => {id => 'category_id'}
        }
    }
);

1;

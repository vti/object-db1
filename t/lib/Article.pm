package Article;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table => 'article',
    columns => [qw/ id user_id title /],
    primary_keys => ['id'],
    auto_increment => 'id',

    relationships => {
        user => {
            type => 'belongs_to',
            class => 'User',
            map => {user_id => 'id'}
        }
    }
);

1;

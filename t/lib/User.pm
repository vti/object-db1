package User;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table => 'user',
    columns => [qw/ id name password /],
    primary_keys => ['id'],
    auto_increment => 'id',

    relationships => {
        articles => {
            type => 'has_many',
            class => 'Article',
            map => {id => 'user_id'}
        }
    }
);

1;

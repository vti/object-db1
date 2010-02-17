package Author;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table          => 'author',
    columns        => [qw/id name password/],
    primary_keys   => ['id'],
    auto_increment => 'id',
    unique_keys    => 'name',

    relationships => {
        author_admin => {
            type  => 'one to one',
            class => 'AuthorAdmin',
            map   => {id => 'author_id'}
        },
        articles => {
            type  => 'one to many',
            class => 'Article',
            map   => {id => 'author_id'}
        }
    }
);

1;

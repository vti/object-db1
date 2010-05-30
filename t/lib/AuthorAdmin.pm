package AuthorAdmin;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table        => 'author_admin',
    columns      => [qw/author_id beard/],
    primary_keys => ['author_id'],

    relationships => {
        admin_articles => {
            type  => 'one to many',
            class => 'Article',
            map   => {author_id => 'author_id'}
        }
    }
);

1;

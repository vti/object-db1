package Admin;

use strict;
use warnings;

use base 'Author';

__PACKAGE__->schema->add_relationship(
    author_admin => {
        type  => 'one to one',
        class => 'AuthorAdmin',
        map   => {id => 'author_id'}
    }
);

1;

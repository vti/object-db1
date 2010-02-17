package AuthorAdmin;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table        => 'author_admin',
    columns      => [qw/author_id beard/],
    primary_keys => ['author_id'],
);

1;

package Foo;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table        => 'foo',
    columns      => [qw/id name password/],
    primary_keys => ['id'],
);

1;

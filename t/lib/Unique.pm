package Unique;

use strict;
use warnings;

use base 'DB';

use ObjectDB::Validation;

__PACKAGE__->meta(
    table          => 'user',
    columns        => [qw/ id password /, name => {length => [3, 8]}],
    primary_keys   => ['id'],
    auto_increment => 'id',
    unique_keys    => 'name'
);

1;

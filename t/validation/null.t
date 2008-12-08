package Model;
use strict;
use lib 't/lib';
use base 'DB';
use ObjectDB::Validation;

__PACKAGE__->meta(
    table   => 'table',
    columns => [
        'id', 'required',
        'required_zero',
        nullable  => {is_null => 1},
        required2 => {is_null => 0},
    ],
    auto_increment => 'id',
    primary_keys   => 'id',
    unique_keys    => 'unique'
);

1;

package main;
use Test::More tests => 3;

my $model = Model->new(required_zero => 0);
ok($model);

is($model->is_valid, 0);
is_deeply(
    $model->error,
    {   required  => [qw/ null /],
        required2 => [qw/ null /]
    }
);

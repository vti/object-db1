package Model;
use strict;
use lib 't/lib';
use base 'DB';
use ObjectDB::Validation;

__PACKAGE__->meta(
    table   => 'table',
    columns => [
        'id',
        'title'   => {regex => qr/\d+/},
    ],
    auto_increment => 'id',
    primary_keys   => 'id'
);

1;

package main;
use Test::More tests => 3;

my $model = Model->new(title => '1234');
is($model->is_valid, 1);

$model = Model->new(title => '1234a');
is($model->is_valid, 0);
is_deeply($model->errors, {title => [qw/ regex /]});

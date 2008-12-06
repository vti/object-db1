package Model;
use strict;
use lib 't/lib';
use base 'DB';

__PACKAGE__->meta(
    table   => 'table',
    columns => [
        'id',
        'null'    => {length => 3, is_null => 1},
        'title'   => {length => 3},
        'content' => {length => [3, 6]},
        'link'    => {length => [3, 6]},
    ],
    auto_increment => 'id',
    primary_keys   => 'id'
);

1;

package main;
use Test::More tests => 2;

my $model = Model->new(title => '1234', content => '1234567', link => '12');
is($model->is_valid, 0);
is_deeply(
    $model->error,
    {   title   => [qw/ length /],
        content => [qw/ length /],
        link    => [qw/ length /]
    }
);

$model->column

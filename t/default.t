package Default;
use strict;
use base 'ObjectDB';

__PACKAGE__->meta(
    table   => 'default',
    columns => ['id', title => {default => 'abc'}],
    primary_keys => 'id'
);

package main;
use Test::More tests => 2;

my $d = Default->new();
is($d->column('title'), 'abc');

$d = Default->new(title => 'foo');
is($d->column('title'), 'foo');

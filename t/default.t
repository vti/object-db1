package Default;
use strict;
use base 'ObjectDB';

__PACKAGE__->meta(
    table   => 'default',
    columns => [
        'id',
        title   => {default => 'abc'},
        addtime => {
            default => sub {time}
        }
    ],
    primary_keys => 'id'
);

package main;
use Test::More tests => 3;

my $d = Default->new();
is($d->column('title'), 'abc');

$d = Default->new(title => 'foo');
is($d->column('title'), 'foo');

$d = Default->new();
ok($d->column('addtime') >= time);

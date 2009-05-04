package Model::Simple;

use base 'ObjectDB';

__PACKAGE__->meta(
    table => 'simple',
    columns => 'foo',
    primary_keys => 'foo'
);

package Model::Base;

use base 'ObjectDB';

__PACKAGE__->meta(
    table => 'base',
    columns => [qw/ foo bar baz /],
    primary_keys => [qw/ foo /]
);

package Model;
use base 'Model::Base';

__PACKAGE__->meta->add_column('gaz');
__PACKAGE__->meta->del_column('bar');

package Model::Options;
use base 'ObjectDB';

__PACKAGE__->meta(
    table => 'options',
    columns => 'foo',
    primary_keys => 'foo',
    auto_increment => 'foo',
    unique_keys => 'foo'
);

package Artist;
use base 'ObjectDB';

__PACKAGE__->meta(
    table => 'artist',
    columns => 'id',
    primary_keys => 'id',

    relationships => {
        albums => {
            type => 'many to one',
            class => 'Album',
            map => {id => 'artist_id'}
        }
    }
);

package Album;
use base 'ObjectDB';

__PACKAGE__->meta(
    table => 'album',
    columns => ['id', 'artist_id'],
    primary_keys => 'id',

    relationships => {
        artist => {
            type => 'many to one',
            class => 'Artist',
            map => {artist_id => 'id'}
        }
    }
);

package Advanced;
use base 'Album';

__PACKAGE__->meta->add_columns(qw/year month/, 'time' => {default => 'now'});
__PACKAGE__->meta->add_relationships(
    foo => {type => 'one to one'},
    bar => {type => 'one to many'}
);

package ColumnsWithOptions;
use base 'ObjectDB';

__PACKAGE__->meta(
    table        => 'table',
    columns      => ['id', title => {length => 1}],
    primary_keys => 'id'
);

package main;

use Test::More tests => 31;

use lib 't/lib';

is(Model::Simple->meta->table, 'simple');
is_deeply([Model::Simple->meta->columns], [qw/ foo /]);
is_deeply([Model::Simple->meta->primary_keys], [qw/ foo /]);
is(Model::Simple->meta->is_primary_key('foo'), 1);

is_deeply([sort Model::Base->meta->columns], [sort qw/ foo bar baz /]);
is_deeply([Model::Base->meta->primary_keys], [qw/ foo /]);

ok(Model::Base->meta->is_column('foo'));
ok(!Model::Base->meta->is_column('fooo'));

is_deeply([sort Model->meta->columns], [sort qw/ foo baz gaz /]);
is_deeply([Model->meta->primary_keys], [qw/ foo /]);

ok(Model->meta->is_column('foo'));
ok(!Model->meta->is_column('fooo'));

ok(Model->meta->is_column('gaz'));
ok(!Model->meta->is_column('bar'));

ok(Model::Options->meta->is_column('foo'));
is_deeply([Model::Options->meta->primary_keys], [qw/ foo /]);
is_deeply(Model::Options->meta->auto_increment, 'foo');
is_deeply([sort Model::Options->meta->columns], [sort qw/ foo /]);
is_deeply([Model::Options->meta->unique_keys], [qw/ foo /]);
is(Model::Options->meta->is_unique_key('foo'), 1);
is(Model::Options->meta->is_auto_increment('foo'), 1);

my $relationships = Artist->meta->relationships;
is(keys %$relationships, 1);
is_deeply($relationships->{albums}->class, 'Album');

$relationships = Advanced->meta->relationships;
is(Advanced->meta->is_column('year'), 1);
is(Advanced->meta->is_column('month'), 1);
is(Advanced->meta->is_column('time'), 1);
is(keys %$relationships, 3);
is($relationships->{foo}->orig_class, 'Advanced');
is_deeply($relationships->{foo}->type, 'one to one');

is_deeply([ColumnsWithOptions->meta->columns], [qw/ id title /]);
is_deeply(ColumnsWithOptions->meta->_columns,
    {id => {}, title => {length => 1}});

1;

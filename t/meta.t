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
            type => 'has_many',
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

    belongs_to => {
        name => 'artist',
        class => 'Artist',
        map => {artist_id => 'id'}
    }
);

package main;

use Test::More tests => 22;

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

my $relationships = Artist->meta->relationships;
is(keys %$relationships, 1);
is_deeply($relationships->{albums}->{class}, 'Album');

1;

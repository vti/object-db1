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

package main;

use Test::More tests => 13;

use lib 't/lib';

is(Model::Simple->meta->table, 'simple');
is_deeply([Model::Simple->meta->columns], [qw/ foo /]);
is_deeply([Model::Simple->meta->primary_keys], [qw/ foo /]);

is_deeply([sort Model::Base->meta->columns], [sort qw/ foo bar baz /]);
is_deeply([Model::Base->meta->primary_keys], [qw/ foo /]);

ok(Model::Base->meta->has_column('foo'));
ok(!Model::Base->meta->has_column('fooo'));

is_deeply([sort Model->meta->columns], [sort qw/ foo baz gaz /]);
is_deeply([Model->meta->primary_keys], [qw/ foo /]);

ok(Model->meta->has_column('foo'));
ok(!Model->meta->has_column('fooo'));

ok(Model->meta->has_column('gaz'));
ok(!Model->meta->has_column('bar'));

1;

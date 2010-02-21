#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 10;

use lib 't/lib';

use Foo;
use Author;

# No primary keys
eval { Foo->new->column(password => 'foo')->update };
like($@, qr/no primary or unique keys specified/);

# DBI error
my $foo = Foo->new(id => 1);
$foo->column(name => 'bar');
ok(not defined $foo->update);
like($foo->error, qr/(no such table|doesn't exist)/);

# Updating and in-place checking
my $author = Author->new(name => 'foo', password => 'bar')->create;
$author->column(name     => 'fuu');
$author->column(password => 'boo');
$author->update;
is($author->column('name'),     'fuu');
is($author->column('password'), 'boo');

# Load from database
$author = Author->new(id => $author->column('id'))->load;
is($author->column('name'),     'fuu');
is($author->column('password'), 'boo');

eval {Author->update()};
like($@, qr/set is required/);

Author->update(set => {name => 'haha'});
$author = Author->new(id => $author->column('id'))->load;
is($author->column('name'),     'haha');
is($author->column('password'), 'boo');

# Cleanup
$author->delete;

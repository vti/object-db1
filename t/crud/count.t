#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 6;

use lib 't/lib';

use Foo;
use Author;

my @authors;

ok(not defined Foo->count);

push @authors, Author->new(name => 'foo', password => 'bar')->create;
is(Author->count, 1);

push @authors, Author->new(name => 'oof', password => 'bar')->create;
is(Author->count, 2);

is(Author->count(where => [name => 'vti']), 0);

is(Author->count(where => [name => 'foo']), 1);

is(Author->count(where => [password => 'bar']), 2);

$_->delete for @authors;

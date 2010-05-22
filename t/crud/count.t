#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 7;

use lib 't/lib';

use Foo;
use Author;

my @authors;

my $foo = Foo->new;
ok(not defined $foo->count);
ok($foo->error);

push @authors, Author->new(name => 'foo', password => 'bar')->create;
is(Author->new->count, 1);

push @authors, Author->new(name => 'oof', password => 'bar')->create;
is(Author->new->count, 2);

is(Author->new->count(where => [name => 'vti']), 0);

is(Author->new->count(where => [name => 'foo']), 1);

is(Author->new->count(where => [password => 'bar']), 2);

$_->delete for @authors;

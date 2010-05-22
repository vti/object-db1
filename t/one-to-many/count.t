#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'bar',
    articles => [{title => 'foo'}]
)->create;

ok($author);

is(Author->new->count(where => ['articles.title' => 'bar']), 0);

is(Author->new->count(where => ['articles.title' => 'foo']), 1);

$author->delete;

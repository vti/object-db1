#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles,
  Article->new(name => 'foo', tags => [{name => 'bar'}, {name => 'baz'}])
  ->create;

is(Article->count(where => ['tags.name' => 'foo']), 0);

is(Article->count(with => 'tags'), 1);

$articles[0]->delete;
Tag->delete(where => [name => [qw/bar baz/]]);

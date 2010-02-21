#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'foo');
$author->create;

ok($author->column('id'));

my $author2 = $author->clone;
ok(not defined $author2->column('id'));

$author->delete;

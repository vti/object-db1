#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;

is(Author->count(where => ['author_admin.beard' => 1]), 0);

is( Author->count(
        where => ['author_admin.beard' => 0],
        with  => 'author_admin'
    ),
    1
);

$author->delete;

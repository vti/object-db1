#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'foo',
    articles => [{title => 'foo'}, {title => 'foo'}]
)->create;

ok($author);

is(Author->count(where => ['articles.title' => 'bar']), 0);

is(Author->count(where => ['articles.title' => 'foo']), 1);

$author->delete;

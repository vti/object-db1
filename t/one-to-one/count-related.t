#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;

$author = Author->new(id => $author->column('id'))->load;

is($author->count_related('author_admin'), 1);

$author->delete;

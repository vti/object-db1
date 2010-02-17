#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'bar');

is_deeply($author->to_hash, {name => 'bar'});

is($author->is_in_db,    0);
is($author->is_modified, 0);

$author->column(name => 'bar');
is($author->is_modified, 0);

$author->column(name => 'foo');
is($author->is_modified, 1);

$author->create;

is($author->is_in_db,    1);
is($author->is_modified, 0);

$author->init(name => 'foo');
is($author->is_modified, 0);

$author->is_modified(0);
$author->init(name => 'foo');
is($author->is_modified, 0);

$author->is_modified(0);
$author->init(name => undef);
is($author->is_modified, 1);

$author->is_modified(0);
$author->init(name => undef);
is($author->is_modified, 0);

$author->delete;

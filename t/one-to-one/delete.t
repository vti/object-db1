#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;
use AuthorAdmin;

my $id;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;
$id = $author->column('id');

$author->delete;

$author = Author->new(id => $id)->load;
ok(not defined $author);

$author = AuthorAdmin->find(where => [author_id => $id], single => 1);

ok(not defined $author);

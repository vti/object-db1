#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use Author;
use AuthorAdmin;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;

my $id = $author->column('id');

$author->delete_related('author_admin');

my $author_admin =
  AuthorAdmin->find(where => [author_id => $id], single => 1);
ok(not defined $author_admin);

$author = Author->new(id => $id)->load;

ok($author);

$author->delete;

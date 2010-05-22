#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;
ok($author);

my $authors = Author->new->find(where => ['author_admin.beard' => 1]);

is_deeply($authors, []);

$authors =
  Author->new->find(where => ['author_admin.beard' => 0], with => 'author_admin');

is(@$authors, 1);

is($authors->[0]->related('author_admin')->column('beard'), 0);

$author->delete;

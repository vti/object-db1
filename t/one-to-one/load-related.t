#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;

my @authors;

push @authors,
  Author->new(name => 'foo', author_admin => {beard => 0})->create;

my $author = Author->new(id => $authors[0]->column('id'))->load;

my $author_admin = $author->load_related('author_admin');

ok($author_admin);
is($author_admin->column('beard'), 0);

$author_admin = $author->related('author_admin');

ok($author_admin);
is($author_admin->column('beard'), 0);

$authors[0]->delete;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;

my @authors;

push @authors,
  Author->new(name => 'foo', author_admin => {beard => 0})->create;

my $author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'author_admin');

my $author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 0);

$authors[0]->delete;

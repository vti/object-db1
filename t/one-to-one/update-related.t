#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';

use Author;

my @authors;

push @authors,
  Author->new(name => 'foo', author_admin => {beard => 0})->create;

my $author_admin =
  $authors[0]->update_related('author_admin' => {set => {beard => 1}});
ok($author_admin);

my $author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'author_admin');

$author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 1);

$authors[0]->delete;

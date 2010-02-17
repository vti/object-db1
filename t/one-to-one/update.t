#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';

use Author;

my @authors;

push @authors,
  Author->new(name => 'foo', author_admin => {beard => 0})->create;

$authors[0]->related('author_admin')->column(beard => 1);
ok($authors[0]->update);

my $author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'author_admin');

my $author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 1);

$author->column(name => 'bar');
$author_admin->column(beard => 0);
ok($author->update);

$author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'author_admin');

is($author->column('name'), 'bar');

$author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 0);

$authors[0]->delete;

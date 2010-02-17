#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use Author;

my @authors;

push @authors, Author->new(name => 'foo')->create;

my $author_admin = $authors[0]->set_related('author_admin' => {beard => 1});

ok($author_admin);
is($author_admin->column('beard'), 1);

my $author =
  Author->new(id => $authors[0]->column('id'))->load(with => 'author_admin');

$author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 1);

$author_admin = $authors[0]->set_related('author_admin' => {beard => 0});

ok($author_admin);
is($author_admin->column('beard'), 0);

$author =
  Author->new(id => $authors[0]->column('id'))
  ->load(with => 'author_admin');

$author_admin = $author->related('author_admin');
ok($author_admin);
is($author_admin->column('beard'), 0);

$authors[0]->delete;

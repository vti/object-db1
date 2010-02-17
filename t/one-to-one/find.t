#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use Author;

my $author = Author->new(name => 'foo', author_admin => {beard => 0})->create;
ok($author);

my $authors = Author->find(where => ['author_admin.beard' => 1]);

is_deeply($authors, []);

$authors =
  Author->find(where => ['author_admin.beard' => 0], with => 'author_admin');

is(@$authors, 1);

is($authors->[0]->related('author_admin')->column('beard'), 0);

$author->delete;

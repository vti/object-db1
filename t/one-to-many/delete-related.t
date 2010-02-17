#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;
use Article;

my $id;

my $author = Author->new(name => 'foo', articles => {title => 'foo'})->create;
$id = $author->column('id');

$author->delete_related('articles');

ok(not defined Article->find(where => [author_id => $id], single => 1));

$author = Author->new(id => $id)->load;
ok($author);

$author->delete;
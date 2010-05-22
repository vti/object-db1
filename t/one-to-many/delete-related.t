#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Author;
use Article;

my $id;

my $author = Author->new(name => 'foo', articles => {title => 'foo'})->create;
$id = $author->column('id');

$author->delete_related('articles');

ok(not defined Article->new->find(where => [author_id => $id], single => 1));

# Check if articles are removed from author object too
ok(!$author->related('articles'));

$author = Author->new(id => $id)->load;
ok($author);

$author->delete;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles, Article->new(name => 'foo')->create;

my $tag = $articles[0]->create_related('tags' => {name => 'foo'});

ok($tag);
is($tag->column('name'), 'foo');

$articles[0]->delete;
Tag->delete(where => [name => [qw/foo/]]);

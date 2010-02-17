#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use Article;
use Tag;

my $article =
  Article->new(name => 'foo', tags => [{name => 'foo'}, {name => 'bar'}])
  ->create;

ok($article);

my $tags = $article->related('tags');

is(@$tags, 2);

is($tags->[0]->column('name'), 'foo');
is($tags->[1]->column('name'), 'bar');

$article->delete;

Tag->delete(where => [name => [qw/foo bar/]]);

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 5;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles,
  Article->new(name => 'foo', tags => [{name => 'bar'}, {name => 'baz'}])
  ->create;

is_deeply(Article->find(where => ['tags.name' => 'foo']), []);

my $articles = Article->find(with => 'tags');

is(@$articles, 1);

my $tags = $articles->[0]->related('tags');
is(@$tags,                     2);
is($tags->[0]->column('name'), 'bar');
is($tags->[1]->column('name'), 'baz');

$articles[0]->delete;
Tag->delete(where => [name => [qw/bar baz/]]);

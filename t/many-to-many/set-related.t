#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use Article;
use Tag;

my @articles;

push @articles, Article->new(name => 'foo')->create;

my $tags = $articles[0]->set_related('tags' => {name => 'foo'});
is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

my $article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'tags');

$tags = $article->related('tags');
is(@$tags,                     1);
is($tags->[0]->column('name'), 'foo');

$tags = $articles[0]->set_related('tags' => {name => 'bar'});

is(@$tags,                     1);
is($tags->[0]->column('name'), 'bar');

my $tag = Tag->new(name => 'foo')->load;

ok($tag);

$article =
  Article->new(id => $articles[0]->column('id'))->load(with => 'tags');

$tags = $article->related('tags');
is(@$tags,                     1);
is($tags->[0]->column('name'), 'bar');

$articles[0]->delete;
Tag->delete(where => [name => [qw/foo bar/]]);

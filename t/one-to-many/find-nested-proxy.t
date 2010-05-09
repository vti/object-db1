#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 3;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'foo',
    articles => {title => 'foo', comments => [{content => 'bar'}]}
);

$author->create;

my $authors = Author->find(with => [qw/articles articles.comments/]);

is(@$authors,                                                1);
is($authors->[0]->related('articles')->[0]->column('title'), 'foo');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);

$author->delete;

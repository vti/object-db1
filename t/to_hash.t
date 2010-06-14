#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 5;

use lib 't/lib';

use Author;

my $author = Author->new(
    name     => 'bar',
    articles => [
        {title => 'foo', tags => {name => 'people'}},
        {title => 'bar', tags => [{name => 'unix'}, {name => 'perl'}]}
    ]
);

is_deeply(
    $author->to_hash,
    {   name     => 'bar',
        articles => [
            {title => 'foo', tags => {name => 'people'}},
            {title => 'bar', tags => [{name => 'unix'}, {name => 'perl'}]}
        ]
    }
);

$author->create;

$author =
  Author->new(name => 'bar')->load(with => [qw/articles articles.tags/]);

my $hash = $author->to_hash;
is($hash->{name}, 'bar');
is(@{$hash->{articles}}, 2);
is(@{$hash->{articles}->[0]->{tags}}, 1);
is(@{$hash->{articles}->[1]->{tags}}, 2);

$author->delete;

Tag->new->delete;

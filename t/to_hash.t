#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 1;

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

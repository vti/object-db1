#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Author;

my $author = Author->new(
    name        => 'bar',
    articles => [
        {title => 'foo', tags => {name => 'people'}},
        {title => 'bar', tags => [{name => 'unix'}, {name => 'perl'}]}
    ]
);

my $authorh = $author->to_hash;

is($authorh->{name}, $author->column('name'), 'name column ok');

is(ref $author->{articles}, 'ARRAY', 'found articles');

done_testing;

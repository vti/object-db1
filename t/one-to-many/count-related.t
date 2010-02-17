#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib 't/lib';

use Author;
use Article;

my @authors;

push @authors,
  Author->new(name => 'foo', articles => {title => 'foo'})->create;

my $author = Author->new(id => $authors[0]->column('id'))->load;

is($author->count_related('articles'), 1);

$authors[0]->delete;

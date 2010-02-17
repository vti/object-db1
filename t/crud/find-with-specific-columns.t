#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use lib 't/lib';

use Author;

my @authors;

push @authors, Author->new(name => 'foo', password => 'bar')->create;

my $authors = Author->find(columns => 'name');
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('name'), 'foo');
ok(not defined $authors->[0]->column('password'));

$authors = Author->find(columns => [qw/ password name /]);
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('name'),     'foo');
is($authors->[0]->column('password'), 'bar');

$authors = Author->find(columns => [{name => \'COUNT(*)', as => 'count'}]);
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('count'), 1);

# Cleanup
$_->delete for @authors;

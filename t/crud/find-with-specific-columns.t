#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 11;

use lib 't/lib';

use Author;

my @authors;

push @authors, Author->new(name => 'foo', password => 'bar')->create;

my $authors = Author->new->find(columns => 'name');
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('name'), 'foo');
ok(not defined $authors->[0]->column('password'));

$authors = Author->new->find(columns => [qw/ password name /]);
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('name'),     'foo');
is($authors->[0]->column('password'), 'bar');

$authors = Author->new->find(columns => [{name => \'COUNT(*)', as => 'count'}]);
is(@$authors, 1);
ok($authors->[0]->column('id'));
is($authors->[0]->column('count'), 1);

# Cleanup
$_->delete for @authors;

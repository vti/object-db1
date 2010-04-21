#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 4;

use lib 't/lib';

use Author;

my @authors;

push @authors, Author->new(name => 'root', password => 'boo')->create;
push @authors, Author->new(name => 'boot', password => 'booo')->create;

my $authors = Author->find(order_by => 'name', iterator => 1);
isa_ok($authors, 'ObjectDB::Iterator');

my $author = $authors->next;
is($author->column('name'), 'boot');
$author = $authors->next;
is($author->column('name'), 'root');
$author = $authors->next;
ok(not defined $author);

$_->delete for @authors;

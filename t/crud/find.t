#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 8;

use lib 't/lib';

use Foo;
use Author;

my $author;
my $authors;
my @authors;

# Unknown table
ok(not defined Foo->find);

# Not found multiple
is_deeply(Author->find(where => [name => 'root']), []);

# Not found single
ok(not defined Author->find(where => [name => 'root'], single => 1));

push @authors, Author->new(name => 'root', password => 'boo')->create;
push @authors, Author->new(name => 'boot', password => 'booo')->create;

# Find single
$author = Author->find(where => [name => 'root'], single => 1);
is($author->column('name'), 'root');

# Find multiple by unique key
$authors = Author->find(where => [name => 'root']);
is(@$authors,                    1);
is($authors->[0]->column('name'), 'root');

# Find multiple by normal column
$authors = Author->find(where => [password => 'boo']);
is(@$authors,                    1);
is($authors->[0]->column('name'), 'root');

$_->delete for @authors;

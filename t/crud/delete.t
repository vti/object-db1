#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 8;

use lib 't/lib';

use TestDB;

use Foo;
use Author;

my $author;

my $foo = Foo->new(id => 1);
ok(not defined $foo->delete);
like($foo->error, qr/(no such table|doesn't exist)/);

eval { Author->new->delete };
like($@, qr/no primary or unique keys specified/);

$author = Author->new(id => 345345);
ok(not defined $author->delete);

$author = Author->new(name => 'foo')->create;
$author = Author->new(name => 'foo', password => 'boo');
ok($author->delete);

$author = Author->new(name => 'root');
$author->create;
ok(Author->delete(where => [name => 'root']));

ok(not defined Author->delete(where => [id => 123456]));
ok(not defined Author->delete(where => [name => 'abc']));

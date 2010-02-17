#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use lib 't/lib';

use TestDB;

use Foo;
use Author;

my $foo = Foo->new;
ok(not defined $foo->create);
like($foo->error, qr/(no such table|doesn't exist)/);

my $author = Author->new->create;
ok($author);
ok($author->column('id'));
ok(not defined $author->column('name'));
ok(not defined $author->column('password'));
$author->delete;

$author = Author->new(name => 'foo')->create;
ok($author);
ok($author->column('id'));
is($author->column('name'), 'foo');
ok(not defined $author->column('password'));
$author->delete;

$author = Author->new(name => 'boo', password => 'bar')->create;
ok($author);
ok($author->column('id'));
is($author->column('name'),     'boo');
is($author->column('password'), 'bar');

$author->create;
is($author->is_modified, 0);
$author->delete;

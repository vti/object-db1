#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use lib 't/lib';

use Foo;
use Author;

eval { Author->new->load };
like($@, qr/no primary or unique keys specified/);

my $foo = Foo->new(id => 123);
ok(not defined $foo->load);
like($foo->error, qr/(no such table|doesn't exist)/);

my $author = Author->new(name => 'foo', password => 'boo')->create;

my $_author = Author->new(id => $author->column('id'));
ok($_author->load);
ok(!$_author->error);
is($_author->column('id'),       $author->column('id'));
is($_author->column('name'),     'foo');
is($_author->column('password'), 'boo');
$_author->delete;

$author = Author->new(id => 999);
ok(not defined $author->load);

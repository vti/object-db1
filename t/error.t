#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Foo;

# SQL error
my $foo = Foo->new(foo => 'bar');
ok(not defined $foo->create);
like($foo->error, qr/(no such table|doesn't exist)/);

#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 5;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->new(title => 'bu');
$wiki->commit;

$wiki->rollback;
is($wiki->column('revision'), 1);

$wiki->column(title => 'haha');
$wiki->commit;

is($wiki->column('title'), 'haha');

ok($wiki->rollback);
is($wiki->column('revision'), 3);
is($wiki->column('title'),    'bu');

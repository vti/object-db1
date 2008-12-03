#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 5;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->new(title => 'Wow');
$wiki->commit;
$wiki->column(title => 'Waw');
$wiki->commit;
is($wiki->column('revision'), 2);

$wiki = Wiki->new(id => $wiki->column('id'));
$wiki->find;
$wiki->find_revision(1);
is($wiki->column('title'), 'Wow');

$wiki = Wiki->new(id => $wiki->column('id'));
$wiki->find;
$wiki->column(title => 'Woo');
$wiki->commit;
is($wiki->column('revision'), 3);
is($wiki->column('title'), 'Woo');

$wiki->find_revision(2);
is($wiki->column('title'), 'Waw');

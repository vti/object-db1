#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 7;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->new(title => 'Wow', user_id => 1);
$wiki->commit;
$wiki->column(title => 'Waw');
$wiki->column(user_id => 2);
$wiki->commit;
is($wiki->column('revision'), 2);

$wiki = Wiki->new(id => $wiki->column('id'));
$wiki->find;
$wiki->load_revision(1);
is($wiki->column('revision'), 1);
is($wiki->column('title'), 'Wow');
is($wiki->column('user_id'), 1);

$wiki = Wiki->new(id => $wiki->column('id'));
$wiki->find;
$wiki->column(title => 'Woo');
$wiki->commit;
is($wiki->column('revision'), 3);
is($wiki->column('title'), 'Woo');

$wiki->load_revision(2);
is($wiki->column('title'), 'Waw');

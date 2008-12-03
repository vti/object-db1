#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 9;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->new(title => 'Wow');
$wiki->commit();

ok($wiki->column('addtime'));
is($wiki->column('revision'), 1);
is($wiki->column('title'), 'Wow');

$wiki = Wiki->select($wiki->column('id'));
is($wiki->column('revision'), 1);

my $old_addtime = $wiki->column('addtime');
#sleep(1);

$wiki->commit;
is($wiki->column('revision'), 1, 'Commit without changes');

$wiki->column(title => $wiki->column('title'));
$wiki->commit;
is($wiki->column('revision'), 1, 'Commit without changes');

$wiki->column(title => 'Wuw');
$wiki->commit();

#isnt($old_addtime, $wiki->addtime);

is($wiki->column('revision'), 2);
is($wiki->column('title'), 'Wuw');

my @diffs = $wiki->find_related('diffs');
is(scalar @diffs, 1);

#$wiki->delete(cascade => 1);

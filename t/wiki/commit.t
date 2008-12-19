#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 12;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->new(title => 'Wow', user_id => 1);
$wiki->commit();

ok($wiki->column('addtime'));
is($wiki->column('revision'), 1);
is($wiki->column('title'), 'Wow');
is($wiki->column('user_id'), 1);

$wiki = Wiki->select($wiki->column('id'));
is($wiki->column('revision'), 1);

my $old_addtime = $wiki->column('addtime');
#sleep(1);

$wiki->commit;
is($wiki->column('revision'), 1, 'Commit without changes');

$wiki->column(title => $wiki->column('title'));
$wiki->commit;
is($wiki->column('revision'), 1, 'Commit without changes');

$wiki->column(user_id => 2);
$wiki->column(title => 'Wuw');
$wiki->commit();

#isnt($old_addtime, $wiki->addtime);

is($wiki->column('revision'), 2);
is($wiki->column('title'), 'Wuw');
is($wiki->column('user_id'), 2);

my @diffs = $wiki->find_related('diffs');
is(scalar @diffs, 1);
is($diffs[0]->column('user_id'), 1);

#$wiki->delete(cascade => 1);

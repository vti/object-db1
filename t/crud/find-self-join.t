#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use Family;

my $father = Family->new(name => 'father')->create;
ok($father->create_related(ansestors => {name => 'child'}));

my $people = Family->find(with => ['parent', 'ansestors']);
is(@$people, 2);

my ($_father, $child) = @$people;

is($_father->column('name'), 'father');
ok(not defined $_father->related('parent'));
is($_father->related('ansestors')->[0]->column('name'), 'child');

is($child->column('name'), 'child');
is($child->related('parent')->column('name'), 'father');
ok(not defined $child->related('ansestors'));

# Cleanup
$father->delete;

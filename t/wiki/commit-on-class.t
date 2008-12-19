#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 1;

use lib 't/lib';

use Wiki;

my $wiki = Wiki->commit(title => 'Wow');
ok($wiki);

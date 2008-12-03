package main;
use Test::More tests => 2;

use lib 't/lib';

use MixedIn;

ok(MixedIn->can('hello'));
ok(not defined MixedIn->can('_hello'));

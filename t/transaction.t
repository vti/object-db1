#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib 't/lib';

use Author;

my $author;

Author->begin_work;
Author->new(name => 'foo') ->create;
is(Author->count, 1);
Author->rollback;
is(Author->count, 0);

Author->begin_work;
$author = Author->new(name => 'foo')->create;
is(Author->count, 1);
Author->commit;
is(Author->count, 1);

$author->delete;

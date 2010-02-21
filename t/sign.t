#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

use lib 't/lib';

use Author;
use Digest::MD5 'md5_hex';

my $author = Author->new(name => 'bar');
is($author->sign, md5_hex("Author:name,bar"));

#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Test::More;
use Encode;

plan tests => 2;

use lib 't/lib';

use Author;
use Digest::MD5 'md5_hex';

my $author = Author->new(name => 'bar');
is($author->sign, md5_hex("Author:name,bar"));

$author = Author->new(name => 'привет');
is($author->sign, md5_hex("Author:name," . Encode::encode_utf8("привет")));

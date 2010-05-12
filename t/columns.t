#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use Author;

my $author = Author->new;

# Use columns method as a getter
ok($author);
is_deeply([$author->columns], []);

# Set one column
$author->column(id => 'boo');
is_deeply([$author->columns], [qw/ id /]);

# TO DO: test default value

# Use columns method as a setter and pass multiple values
$author = $author->columns(id => 'bar', name => 'test1');
ok(ref $author eq 'Author');
ok($author->column('id') eq 'bar' && $author->column('name') eq 'test1');

# Set values to undef
$author->columns(id => undef, name => undef);
ok(!defined $author->column('id') && !defined $author->column('name'));

# Check getter after multiple values have been set
$author = Author->new;
$author->columns(id => 'bar', name => 'test1');
is_deeply([$author->columns], [qw/ id name /]);

# Odd number of hash elements
ok(!eval { $author->columns(id => 'bar', 'odd number of hash elements') });

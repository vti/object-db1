#!/usr/bin/perl

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 2;

use lib 't/lib';

use ObjectDB::Iterator;
use Author;

my $author = Author->new(name => 'foo', password => 'bar')->create;

my $dbh = Author->init_db;
my $sth = $dbh->prepare("SELECT * FROM author");
$sth->execute;

my $i = ObjectDB::Iterator->new(class => 'Author', sth => $sth);
ok($i);

my $count = 0;
while (my $value = $i->next) {
    $count++;
}

is($count, 1);

$author->delete;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 1;

use lib 't/lib';

use TestDB;

ok(TestDB->cleanup);

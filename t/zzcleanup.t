use Test::More tests => 1;

unlink 'table.db';
ok(!-f 'table.db');

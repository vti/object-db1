use Test::More tests => 3;

use lib 't/lib';

use WikiSimple;

my $wiki = WikiSimple->create(title => 'hello', user_id => 1);
ok($wiki->column('addtime'));
is($wiki->column('revision'), 1);
is($wiki->column('title'), 'hello');

use Test::More tests => 13;

use lib 't/lib';

use WikiSimple;

my $wiki = WikiSimple->new(title => 'hello', user_id => 1)->create;

$wiki = WikiSimple->new(id => $wiki->column('id'))->find;
ok($wiki);

is($wiki->is_modified, 0);
$wiki->update;
is($wiki->column('revision'), 1);

$wiki->column(title => 'hello');
$wiki->update;
is($wiki->column('revision'), 1);

$wiki->column(title => 'hallo');
$wiki->column(user_id => 2);
$wiki->update;
my $addtime = $wiki->column('addtime');
is($wiki->column('revision'), 2);
is($wiki->column('title'), 'hallo');
is($wiki->column('user_id'), 2);

my @history = $wiki->find_related('history');
is(scalar @history, 1);
my $history = shift @history;
ok($history);
is($history->column('revision'), 1);
is($history->column('user_id'), 1);
is($history->column('title'), 'hello');
is($history->column('addtime'), $addtime);

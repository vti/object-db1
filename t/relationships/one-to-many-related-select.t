use Test::More tests => 4;

use lib 't/lib';

use Article;
use User;

my $u = User->create(name => 'foo');
$u->create_related('articles', title => 'bar');

$u = User->create(name => 'bar');
$u->create_related('articles', title => 'foo');

my @users = User->find_objects(where => ['articles.title' => 'boo']);
is(@users, 0);

@users = User->find_objects(where => ['articles.title' => 'bar']);
is(@users, 1);
is($users[0]->column('name'), 'foo');

is(User->count_objects(where => ['articles.title' => 'bar']), 1);

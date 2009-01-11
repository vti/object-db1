use Test::More tests => 5;

use lib 't/lib';

use Article;
use User;

Article->delete_objects;
User->delete_objects;

my $user = User->new(name => 'foo', password => 'bar')->create;
$user->create_related('articles', title => 'zoo');
$user->create_related('articles', title => 'boo');

my $user = User->new(name => 'boo', password => 'baz')->create;
$user->create_related('articles', title => 'koo');
$user->create_related('articles', title => 'goo');

my @articles =
  Article->find_objects(
    where => ['user.name' => 'boo', 'user.password' => 'baz'], with => 'user');
is(@articles, 2);
is($articles[0]->column('title'), 'koo');
is($articles[0]->related('user')->column('name'), 'boo');
is($articles[1]->column('title'), 'goo');

is(Article->count_objects(where => ['user.name' => 'boo']), 2);

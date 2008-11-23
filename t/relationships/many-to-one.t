use Test::More tests => 2;

use lib 't/lib';

use Article;
use User;

my $u = User->create(name => 'root');

Article->delete_objects;

my $article = Article->create(user_id => $u->column('id'), title => 'boo');
my $user = $article->find_related('user');
is($user->column('id'), $u->column('id'));
is($user->column('name'), 'root');

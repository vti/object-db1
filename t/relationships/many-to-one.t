use Test::More tests => 3;

use lib 't/lib';

use Article;
use User;

my $u = User->new(name => 'root')->create;

Article->delete_objects;

my $article = Article->new(title => 'foo')->create;
ok(not defined $article->find_related('user'));

$article = Article->new(user_id => $u->column('id'), title => 'boo')->create;
my $user = $article->find_related('user');
is($user->column('id'), $u->column('id'));
is($user->column('name'), 'root');

Article->delete_objects;
User->delete_objects;

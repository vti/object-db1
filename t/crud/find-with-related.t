use Test::More tests => 3;

use lib 't/lib';

use User;
use Article;

my $u = User->new(name => 'admin', password => 'boo')->create;
my $article = $u->create_related('articles', title => 'bar');

$article =
 Article->new(id => $article->column('id'))->find(with => 'user');

ok($article);
is($article->column('title'), 'bar');
is($article->related('user')->column('name'), 'admin');

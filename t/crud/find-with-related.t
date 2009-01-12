use Test::More tests => 4;

use lib 't/lib';

use User;
use Category;
use Article;

my $u = User->new(name => 'admin', password => 'boo')->create;
my $cat = Category->new(title => 'foo')->create;

my $article = $u->create_related(
    'articles',
    category_id => $cat->column('id'),
    title       => 'bar'
);

$article =
 Article->new(id => $article->column('id'))->find(with => [qw/ user category /]);

ok($article);
is($article->column('title'), 'bar');
is($article->related('user')->column('name'), 'admin');
is($article->related('category')->column('title'), 'foo');

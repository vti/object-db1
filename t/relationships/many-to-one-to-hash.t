use Test::More tests => 1;

use lib 't/lib';

use Article;
use User;

User->delete_objects(where => [name => 'foo']);

my $u = User->create(name => 'foo');
$u->create_related('articles', title => 'boo');
$u->create_related('articles', title => 'foo');

my $articles =
  Article->find_objects(where => [title => 'foo'], with => 'user');

is_deeply(
    $articles->next->to_hash,
    {   title   => 'foo',
        name    => '',
        user_id => $u->column('id'),
        id      => 2,
        user    => {
            id       => $u->column('id'),
            name     => 'foo',
            password => ''
        }
    }
);

Article->delete_objects;
User->delete_objects;

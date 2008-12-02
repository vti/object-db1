use Test::More tests => 10;

use lib 't/lib';

use Tree;

Tree->delete_objects();

my $parent = Tree->create(title => 'bar');

ok($parent->column('id'));
ok(not defined $parent->column('path'));
is($parent->column('level'), 0);

my $child = $parent->create_related('ansestors', title => 'foo');
is($child->column('path'), $parent->column('id'));
is($child->column('level'), 1);

my $grandchild = $child->create_related('ansestors', title => 'baz');
is($grandchild->column('path'),
    $parent->column('id') . '-' . $child->column('id'));
is($grandchild->column('level'), 2);

my @tree = Tree->find_objects(order_by => 'path ASC');
is($tree[0]->column('id'), $parent->column('id'));
is($tree[1]->column('id'), $child->column('id'));
is($tree[2]->column('id'), $grandchild->column('id'));

use Test::More tests => 45;

use lib 't/lib';

use Article;
use NestedComment;

NestedComment->delete_objects;

my $master = Article->new(
    category_id => 1,
    user_id     => 1,
    title       => 'bar'
)->create;

my $c1 = NestedComment->new(
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 1
)->create;
is($c1->column('lft'), 2);
is($c1->column('rgt'), 3);
is($c1->column('level'), 0);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 1);

my $c2 = NestedComment->new(
    user_id     => 1,
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 2
)->create;
is($c2->column('lft'), 4);
is($c2->column('rgt'), 5);
is($c2->column('level'), 0);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 2);

my $c3 = NestedComment->new(
    user_id     => 1,
    master_id   => $master->column('id'),
    master_type => 'article',
    content     => 3
)->create;
is($c3->column('lft'), 6);
is($c3->column('rgt'), 7);
is($c3->column('level'), 0);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 3);

my $c4 = $c1->create_related('ansestors', content => 4);
is($c4->column('lft'), 3);
is($c4->column('rgt'), 4);
is($c4->column('level'), 1);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 4);

my $c5 = $c2->create_related('ansestors', content => 5);
is($c5->column('lft'), 7);
is($c5->column('rgt'), 8);
is($c5->column('level'), 1);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 5);

my $c6 = $c3->create_related('ansestors', content => 6);
is($c6->column('lft'), 11);
is($c6->column('rgt'), 12);
is($c6->column('level'), 1);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 6);

my $c7 = $c5->create_related('ansestors', content => 7);
is($c7->column('lft'), 8);
is($c7->column('rgt'), 9);
is($c7->column('level'), 2);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 7);

my $c8 = $c6->create_related('ansestors', content => 8);
is($c8->column('lft'), 14);
is($c8->column('rgt'), 15);
is($c8->column('level'), 2);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 8);

my $c9 = $c6->create_related('ansestors', content => 9);
is($c9->column('lft'), 16);
is($c9->column('rgt'), 17);
is($c9->column('level'), 2);
$master = $master->new(id => $master->column('id'))->find;
is($master->column('comment_count'), 9);

my $comments = NestedComment->find_objects(
    where => [
        master_type => 'article',
        master_id   => $master->column('id')
    ],
    order_by => 'lft ASC'
);

foreach my $content (qw/ 1 4 2 5 7 3 6 8 9 /) {
    my $comment = $comments->next;
    is($comment->column('content'), $content);
}

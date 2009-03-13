package NestedComment;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table   => 'nested_comment',
    columns => [
        qw/ id master_id master_type parent_id level rgt lft content /,
        addtime => {
            default => sub {time}
        }
    ],
    primary_keys   => 'id',
    auto_increment => 'id',
    relationships  => {
        parent => {
            type  => 'many to one',
            class => 'NestedComment',
            map   => {parent_id => 'id'}
        },
        ansestors => {
            type  => 'one to many',
            class => 'NestedComment',
            map   => {id => 'parent_id'}
        },
        master => {
            type      => 'proxy',
            proxy_key => 'master_type',
        },
        article => {
            type  => 'many to one',
            class => 'Article',
            map   => {master_id => 'id'}
        },
        podcast => {
            type  => 'many to one',
            class => 'Podcast',
            map   => {master_id => 'id'}
        }
    }
);

sub create {
    my $self = shift;

    my $rgt = 1;
    my $level = 0;

    $self->begin(behavior => 'immediate');

    eval {
        if ($self->column('parent_id')) {
            my $parent = $self->find_related('parent');

            $self->column(master_id => $parent->column('master_id'));
            $self->column(master_type => $parent->column('master_type'));

            $level = $parent->column('level') + 1;

            $rgt = $parent->column('lft');
        }

        my $master = $self->find_related('master');

        my $comment_count = $self->count_objects(
            where => [
                master_type => $self->column('master_type'),
                master_id   => $self->column('master_id')
            ]
        );

        if ($comment_count) {
            my $left;

            $left = $self->find_objects(
                where => [
                    master_id   => $self->column('master_id'),
                    master_type => $self->column('master_type'),
                    parent_id   => $self->column('parent_id')
                ],
                order_by => 'addtime DESC, id DESC',
                limit    => 1,
                single   => 1
            );

            $rgt = $left->column('rgt') if $left;

            $self->update_objects(
                columns => ['rgt'],
                bind    => [\'rgt + 2'],
                where   => [rgt => {'>' => $rgt}]
            );
            $self->update_objects(
                columns => ['lft'],
                bind    => [\'lft + 2'],
                where   => [lft => {'>' => $rgt}]
            );
        }

        $self->column(lft => $rgt + 1);
        $self->column(rgt => $rgt + 2);
        $self->column(level => $level);
        $self->SUPER::create;

        $master->column(comment_count => $comment_count + 1);
        $master->update;
    };

    if ($@) {
        $self->rollback;
        return;
    }

    $self->commit;

    return $self;
}

1;

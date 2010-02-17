package NestedComment;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table => 'nested_comment',
    columns =>
      [qw/id addtime master_id master_type parent_id level rgt lft content/,],
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
    my ($dbh, $cb) = @_;

    my $rgt           = 1;
    my $level         = 0;
    my $comment_count = 0;

    if ($self->column('parent_id')) {
        my $parent = $self->find_related('parent');

        if ($parent) {
            $self->column(master_id   => $parent->column('master_id'));
            $self->column(master_type => $parent->column('master_type'));

            $level = $parent->column('level') + 1;

            $rgt = $parent->column('lft');
        }
    }

    $comment_count = $self->count(
        where => [
            master_type => $self->column('master_type'),
            master_id   => $self->column('master_id')
        ]
    );

    if ($comment_count) {
        my $left = $self->find(
            where => [
                master_id   => $self->column('master_id'),
                master_type => $self->column('master_type'),
                parent_id   => $self->column('parent_id')
            ],
            order_by => 'addtime DESC, id DESC',
            single   => 1
        );


        $rgt = $left->column('rgt') if $left;

        $self->update(
            set   => {'rgt' => \'rgt + 2'},
            where => [rgt   => {'>' => $rgt}]
        );

        $self->update(
            set   => {'lft' => \'lft + 2'},
            where => [lft   => {'>' => $rgt}]
        );
    }

    $self->column(lft   => $rgt + 1);
    $self->column(rgt   => $rgt + 2);
    $self->column(level => $level);

    $self->column(addtime => time) unless $self->column('addtime');

    return $self->SUPER::create;
}

1;

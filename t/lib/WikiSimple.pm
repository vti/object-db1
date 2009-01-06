package WikiSimple;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table   => 'wiki_simple',
    columns => [
        qw/ id parent_id user_id title /,
        revision => {default => 1},
        addtime  => {
            default => sub {time}
        },
    ],
    primary_keys   => [qw/ id /],
    auto_increment => 'id',

    relationships => {
        parent => {
            type  => 'many to one',
            class => 'WikiSimple',
            map   => {parent_id => 'id'}
        },
        history => {
            type  => 'one to many',
            class => 'WikiSimple',
            map   => {id => 'parent_id'}
        }
    }
);

sub update {
    my $self = shift;

    return $self unless $self->is_modified;

    my @pk = $self->meta->primary_keys;
    my @pk_values = map { $self->column($_) } @pk;

    my $initial = $self->meta->class->select(@pk_values);
    return $self unless $initial;

    $self->column(revision => $self->column('revision') + 1);
    $self->SUPER::update;

    $self->create_related('history', $initial->clone);

    return $self;
}

1;

package Tree;

use strict;
use warnings;

use base 'DB';

__PACKAGE__->meta(
    table        => 'tree',
    columns      => [qw/ id parent_id title path /, level => {default => 0}],
    primary_keys => [qw/ id /],
    auto_increment => 'id',

    relationships => {
        parent => {
            type => 'many to one',
            class => 'Tree',
            map => {parent_id => 'id'}
        },
        ansestors => {
            type => 'one to many',
            class => 'Tree',
            map => {id => 'parent_id'}
        }
    }
);

sub create {
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);

    if (my $parent = $self->find_related('parent')) {
        my $parent_path = $parent->column('path');
        my $path =
          $parent_path
          ? join('-', $parent_path, $parent->column('id'))
          : $parent->column('id');

        $self->column(path => $path);
        $self->column(level => ++($path =~ tr/-//));
    }

    $self->SUPER::create();
}

1;

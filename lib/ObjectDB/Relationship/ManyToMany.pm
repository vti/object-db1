package ObjectDB::Relationship::ManyToMany;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

__PACKAGE__->attr([qw/ _map_class map_from map_to /]);

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(
        @_,
        _map_class => delete $params{map_class},
    );

    return $self;
}

sub map_class {
    my $self = shift;

    my $map_class = $self->_map_class;

    unless ($map_class->can('isa')) {
        eval "require $map_class;";
    }

    return $map_class;
}

sub class {
    my $self = shift;

    my $map_class = $self->map_class;
    unless ($map_class->can('isa')) {
        eval "require $map_class;";
    }

    $self->_class($map_class->meta->relationships->{$self->map_to}->class)
      unless $self->_class;

    return $self->SUPER::class;
}

sub to_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->meta->relationships->{$map_to}->map};

    my $table = $self->class->meta->table;
    my $map_table = $self->map_class->meta->table;

    return {
        name       => $table,
        join       => 'left',
        constraint => "$table.$to=$map_table.$from"
    };
}

sub to_map_source {
    my $self = shift;

    my $map_from = $self->map_from;
    my $map_to = $self->map_to;

    my ($from, $to) =
      %{$self->map_class->meta->relationships->{$map_from}->map};

    my $table = $self->orig_class->meta->table;
    my $map_table = $self->map_class->meta->table;

    return {
        name       => $map_table,
        join       => 'left',
        constraint => "$table.$to=$map_table.$from"
    };
}

1;

package ObjectDB::Meta;

use strict;
use warnings;

use base 'ObjectDB::Base';

require Clone;
require Carp;

our %objects;

sub new {
    my $class     = shift;
    my $for_class = shift;
    my %params    = @_;

    foreach my $parent (_get_parents($for_class)) {
        if (my $parent_meta = $objects{$parent}) {
            my $meta = Clone::clone $parent_meta;

            return $meta;
        }
    }

    my %values;

    my $columns      = $params{columns};
    my $primary_keys = $params{primary_keys};
    my $table        = $params{table};

    Carp::croak("No table in $for_class") unless $table;
    Carp::croak("No columns in $for_class") unless $columns;
    Carp::croak("No primary keys in $for_class") unless $primary_keys;

    my @columns =
      ref $columns ? @{$columns} : ($columns);
    $columns = {map { $_ => {} } @columns };

    $primary_keys = ref $primary_keys ? $primary_keys : [$primary_keys];

    my $self = $class->SUPER::new(table        => $table,
                                  columns      => $columns,
                                  primary_keys => $primary_keys);

    return $self;
}

sub table {
    my $self = shift;
    return $self->{table};
}

sub has_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name;

    return exists $self->{columns}->{$name};
}

sub columns {
    my $self = shift;

    return keys %{$self->{columns}};
}

sub primary_keys {
    my $self = shift;

    return @{$self->{primary_keys}};
}

sub add_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name;

    $self->{columns}->{$name} = {};
}

sub del_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name && $self->has_column($name);

    delete $self->{columns}->{$name};
}

sub _get_parents {
    my $class = shift;
    my @parents;

    no strict 'refs';
    # shift our class name
    foreach my $sub_class (@{"${class}::ISA"}) {
        push (@parents, _get_parents($sub_class))
          if ($sub_class->isa('ObjectDB') && $sub_class ne 'ObjectDB');
    }

    return $class, @parents;
}

1;

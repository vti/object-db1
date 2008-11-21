package ObjectDB::Meta;

use strict;
use warnings;

use base 'ObjectDB::Base';

require Clone;
require Carp;

__PACKAGE__->attr('table', chained => 1);
__PACKAGE__->attr('auto_increment', chained => 1);

__PACKAGE__->attr('_primary_keys', default => sub {[]}, chained => 1);
__PACKAGE__->attr('_unique_keys', default => sub {[]}, chained => 1);
__PACKAGE__->attr('_columns', default => sub {{}}, chained => 1);

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

    my $columns        = $params{columns};
    my $primary_keys   = $params{primary_keys};
    my $unique_keys   = $params{unique_keys};
    my $table          = $params{table};
    my $auto_increment = $params{auto_increment};

    Carp::croak("No table in $for_class") unless $table;
    Carp::croak("No columns in $for_class") unless $columns;
    Carp::croak("No primary keys in $for_class") unless $primary_keys;

    my @columns =
      ref $columns ? @{$columns} : ($columns);
    $columns = {map { $_ => {} } @columns };

    $primary_keys = ref $primary_keys ? $primary_keys : [$primary_keys];
    $unique_keys = ref $unique_keys ? $unique_keys : [$unique_keys];

    my $self = $class->SUPER::new(table          => $table,
                                  auto_increment => $auto_increment,
                                  _columns       => $columns,
                                  _primary_keys  => $primary_keys,
                                  _unique_keys  => $unique_keys);

    return $self;
}

sub is_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name;

    return exists $self->_columns->{$name};
}

sub columns {
    my $self = shift;

    return keys %{$self->_columns};
}

sub primary_keys {
    my $self = shift;

    return @{$self->_primary_keys};
}

sub is_primary_key {
    my $self = shift;
    my ($name) = @_;

    return 0 unless $name;

    my @rv = grep {$name eq $_} $self->primary_keys;
    return @rv ? 1 : 0;
}

sub unique_keys {
    my $self = shift;

    return @{$self->_unique_keys};
}

sub is_unique_key {
    my $self = shift;
    my ($name) = @_;

    return 0 unless $name;

    my @rv = grep {$name eq $_} $self->unique_keys;
    return @rv ? 1 : 0;
}

sub add_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name;

    $self->_columns->{$name} = {};
}

sub del_column {
    my $self = shift;
    my ($name) = @_;

    return unless $name && $self->is_column($name);

    delete $self->_columns->{$name};
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

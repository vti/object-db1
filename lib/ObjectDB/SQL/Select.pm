package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::SQL';

__PACKAGE__->attr([qw/ group_by having order_by limit offset /], chained => 1);
__PACKAGE__->attr([qw/ _sources _columns /], default => sub {[]}, chained => 1);
__PACKAGE__->attr([qw/ where_logic where /], chained => 1);

sub source {
    my $self = shift;
    my ($source) = @_;

    $source = {name => $source} unless ref $source eq 'HASH';

    $source->{columns} ||= [];
    push @{$self->_sources}, $source
      unless grep { $_->{name} eq $source->{name} } @{$self->_sources};

    return $self;
}

sub columns {
    my $self = shift;

    if (@_) {
        die 'first define source' unless @{$self->_sources};

        $self->_sources->[-1]->{columns} = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

        return $self;
    }

    my @column_names = ();

    foreach my $col (@{$self->_sources->[0]->{columns}}) {
        if (ref $col eq 'SCALAR') {
            $col = $$col;
        } elsif (ref $col eq 'HASH') {
            ($col) = $col->{as};
        }

        push @column_names, $col;
    }

    return @column_names;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'SELECT ';

    my $need_prefix = @{$self->_sources} > 1;
    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        if (@{$source->{columns}}) {
            $query .= ', ' unless $first;

            my @columns;
            foreach my $col (@{$source->{columns}}) {
                if (ref $col eq 'SCALAR') {
                    push @columns, $$col;
                } else {
                    my $col_full = $col;

                    my $as;
                    if (ref $col_full eq 'HASH') {
                        $as = $col_full->{as};
                        $col_full = $col_full->{name};
                    }

                    if (ref $col_full eq 'SCALAR') {
                        $col_full = $$col_full;
                    } else {
                        if ($col_full =~ s/^(\w+)\.//) {
                            $col_full = "$1.`$col_full`"
                        } elsif ($need_prefix) {
                            $col_full = $source->{name} . ".`$col_full`"
                        } else {
                            $col_full = "`$col_full`";
                        }
                    }

                    push @columns, $as ? "$col_full AS $as" : $col_full;
                }
            }

            $query .= join(', ', @columns);

            $first = 0;
        }
    }

    $query .= ' FROM ';

    $query .= $self->_sources_to_string;

    my $default_prefix;
    if ($need_prefix) {
        $default_prefix = $self->_sources->[0]->{name};
    }

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where, $default_prefix);
    }

    if (my $group_by = $self->group_by) {
        if ($default_prefix && $group_by !~ m/^\w+\./) {
            $group_by = $default_prefix . '.' . $group_by;
        }

        $query .= ' GROUP BY ' . $group_by;
    }

    $query .= ' HAVING ' . $self->having if $self->having;

    if (my $order_by = $self->order_by) {
        if ($default_prefix && $order_by !~ m/^\w+\./) {
            $order_by = $default_prefix . '.' . $order_by;
        }

        $query .= ' ORDER BY ' . $order_by;
    }

    $query .= ' LIMIT ' . $self->limit if $self->limit;

    $query .= ' OFFSET ' . $self->offset if $self->offset;

    return $query;
}

sub _sources_to_string {
    my $self = shift;

    my $string = "";

    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        $string .= ', ' unless $first || $source->{join};

        $string .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};
        $string .= '`' . $source->{name} . '`';

        $string .= ' AS ' . '`' . $source->{as} . '`' if $source->{as};

        $string .= ' ON ' . $source->{constraint} if $source->{constraint};

        $first = 0;
    }

    return $string;
}

1;

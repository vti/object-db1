package ObjectDB::SQL;

use strict;
use warnings;

use base 'ObjectDB::Base';

use overload '""' => sub { shift->to_string }, fallback => 1;

__PACKAGE__->attr([qw/ command table group_by having order_by limit offset /], chained => 1);
__PACKAGE__->attr('columns', default => sub {[]}, chained => 1);
__PACKAGE__->attr('where', default => sub {{}}, chained => 1);

sub insert { shift->command('insert') }

sub clear {
    my $self = shift;

    $self->command(undef);
    $self->table(undef);
    $self->columns([]);
    $self->_where({});
}

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub to_string {
    my $self = shift;

    my $query = "";
    return $query unless $self->command;

    if ($self->command eq 'insert') {
        $query .= 'INSERT INTO ';
        $query .= $self->table;
        $query .= ' (';
        $query .= join(', ', @{$self->columns});
        $query .= ')';
        $query .= ' VALUES (';
        $query .= '?, ' x (@{$self->columns} - 1);
        $query .= '?)';
    } elsif ($self->command eq 'select') {
        $query .= 'SELECT ';
        $query .= join(', ', @{$self->columns});
        $query .= ' FROM ';
        $query .= $self->table;

        if (%{$self->where}) {
            $query .= ' WHERE ';
            $query .= $self->_where_to_string;
        }

        if ($self->group_by) {
            $query .= ' GROUP BY ';
            $query .= $self->group_by;
        }

        if ($self->having) {
            $query .= ' HAVING ';
            $query .= $self->having;
        }

        if ($self->order_by) {
            $query .= ' ORDER BY ';
            $query .= $self->order_by;
        }

        if ($self->limit) {
            $query .= ' LIMIT ';
            $query .= $self->limit;
        }

        if ($self->offset) {
            $query .= ' OFFSET ';
            $query .= $self->offset;
        }
    } elsif ($self->command eq 'update') {
        $query .= 'UPDATE ';
        $query .= $self->table;
        $query .= ' SET ';

        my $i = @{$self->columns} - 1;
        foreach my $name (@{$self->columns}) {
            $query .= "$name = ?";
            $query .= ', ' if $i;
            $i--;
        }

        if (%{$self->where}) {
            $query .= ' WHERE ';
            $query .= $self->_where_to_string;
        }
    } elsif ($self->command eq 'delete') {
        $query .= 'DELETE FROM ';
        $query .= $self->table;

        if (%{$self->where}) {
            $query .= ' WHERE ';
            $query .= $self->_where_to_string;
        }
    }

    return $query;
}

sub _where_to_string {
    my $self = shift;

    my $string = "";
    my $where = $self->where;

    foreach my $key (keys %$where) {
        $string .= "$key = '$where->{$key}'";
    }

    return $string;
}

1;

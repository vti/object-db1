package ObjectDB::SQL;

use strict;
use warnings;

use base 'ObjectDB::Base';

use overload '""' => sub { shift->to_string }, fallback => 1;

__PACKAGE__->attr([qw/ command table /], chained => 1);
__PACKAGE__->attr('columns', default => sub {[]}, chained => 1);
__PACKAGE__->attr('_where', default => sub {{}}, chained => 1);

sub insert { shift->command('insert') }

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub where {
    my $self = shift;

    if (@_) {
        $self->_where({@_});
        return $self;
    } else {
        return $self->_where;
    }
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

        if ($self->where) {
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

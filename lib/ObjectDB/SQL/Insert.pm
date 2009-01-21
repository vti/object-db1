package ObjectDB::SQL::Insert;

use strict;
use warnings;

use base 'ObjectDB::SQL';

__PACKAGE__->attr([qw/ table /], chained => 1);
__PACKAGE__->attr('columns', default => sub { [] }, chained => 1);
__PACKAGE__->attr('bind', default => sub { [] }, chained => 1);

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'INSERT INTO ';
    $query .= '`' . $self->table . '`';
    if (@{$self->columns}) {
        $query .= ' (';
        $query .= join(', ', map {"`$_`"} @{$self->columns});
        $query .= ')';
        $query .= ' VALUES (';
        $query .= '?, ' x (@{$self->columns} - 1);
        $query .= '?)';
    } else {
        if ($self->driver && $self->driver eq 'mysql') {
            $query .= '() VALUES()';
        } else {
            $query .= ' DEFAULT VALUES';
        }
    }

    return $query;
}

1;

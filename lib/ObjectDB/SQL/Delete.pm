package ObjectDB::SQL::Delete;

use strict;
use warnings;

use base 'ObjectDB::SQL';

__PACKAGE__->attr([qw/ table where bind /], chained => 1);

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'DELETE FROM ';
    $query .= '`' . $self->table . '`';

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where);
    }

    return $query;
}

1;

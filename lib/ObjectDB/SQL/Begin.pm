package ObjectDB::SQL::Begin;

use strict;
use warnings;

use base 'ObjectDB::SQL';

__PACKAGE__->attr([qw/ behavior /], chained => 1);

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'BEGIN';

    if ($self->driver && $self->driver eq 'mysql') {
        $query .= ' WORK';
    }

    if ($self->behavior && (!$self->driver || $self->driver eq 'SQLite')) {
        $query .= ' ';
        $query .= uc $self->behavior;
    }

    return $query;
}

1;

package ObjectDB::SQL::Delete;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ _parent table bind /], chained => 1);
__PACKAGE__->attr('where', default => sub {{}}, chained => 1);

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'DELETE FROM ';
    $query .= $self->table;

    if (%{$self->where}) {
        $query .= ' WHERE ';
        $query .= $self->_parent->_where_to_string($self->where);
    }

    return $query;
}

1;

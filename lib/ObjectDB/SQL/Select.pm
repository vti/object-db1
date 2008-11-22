package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ _parent source group_by having order_by limit offset /], chained => 1);
__PACKAGE__->attr([qw/ columns bin /], default => sub {[]}, chained => 1);
__PACKAGE__->attr('where', default => sub {{}}, chained => 1);

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'SELECT ';

    if (@{$self->columns}) {
        $query .= join(', ', @{$self->columns});
    } else {
        $query .= '*';
    }

    $query .= ' FROM ';
    if (ref $self->source eq 'HASH') {
        $query .= $self->source->{source};

        my $join = $self->source->{join};
        $query .= ' ' . uc $join->{op} . ' JOIN ';
        $query .= $join->{source};
        $query .= ' ON ' . $join->{constraint};
    } else {
        $query .= $self->source;
    }

    if (%{$self->where}) {
        $query .= ' WHERE ';
        $query .= $self->_parent->_where_to_string($self->where);
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

    return $query;
}

1;

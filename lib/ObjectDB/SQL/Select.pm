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

    my $sources = $self->source;
    $sources = ref $sources eq 'ARRAY' ? $sources : [$sources];
    $query .= shift @$sources;
    foreach my $source (@$sources) {
        if (ref $source eq 'HASH') {
            $query .= ' ' . uc $source->{join} . ' JOIN ';
            $query .= $source->{source};
            $query .= ' ON ' . $source->{constraint} if $source->{constraint};
        } else {
            $query .= ', ';
            $query .= $source;
        }
    }

    if (%{$self->where}) {
        $query .= ' WHERE ';
        $query .= $self->_parent->_where_to_string($self->where);
    }

    $query .= ' GROUP BY ' . $self->group_by if $self->group_by;

    $query .= ' HAVING ' . $self->having if $self->having;

    $query .= ' ORDER BY ' . $self->order_by if $self->order_by;

    $query .= ' LIMIT ' . $self->limit if $self->limit;

    $query .= ' OFFSET ' . $self->offset if $self->offset;

    return $query;
}

1;

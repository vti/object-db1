package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ _parent source group_by having order_by limit offset /], chained => 1);
__PACKAGE__->attr([qw/ columns bin /], default => sub {[]}, chained => 1);
__PACKAGE__->attr('where', chained => 1);

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
        $query .= join(', ', map {ref $_ ? $$_ : "`$_`"} @{$self->columns});
    } else {
        $query .= '*';
    }

    $query .= ' FROM ';

    my $sources = $self->source;
    $sources = ref $sources eq 'ARRAY' ? $sources : [$sources];
    #$query .= shift @$sources;
    my $first = 1;
    foreach my $source (@$sources) {
        if (ref $source eq 'HASH') {
            $query .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};
            $query .= '`' . $source->{name} . '`';
            $query .= ' AS ' . $source->{as} if $source->{as};
            $query .= ' ON ' . $source->{constraint} if $source->{constraint};
        } else {
            $query .= ', ' unless $first;
            $query .= '`' . $source . '`';
        }
        $first = 0;
    }

    if ($self->where) {
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

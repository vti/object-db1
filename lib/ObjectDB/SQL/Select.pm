package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ _parent group_by having order_by limit offset /], chained => 1);
__PACKAGE__->attr([qw/ _sources _columns bind /], default => sub {[]}, chained => 1);
__PACKAGE__->attr('where', chained => 1);

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

    return @{$self->_sources->[0]->{columns}};
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'SELECT ';

    my $need_prefix = @{$self->_sources} > 1;
    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        $query .= ', ' unless $first;
        my $prefix = $need_prefix ? $source->{name} : undef;

        if (@{$source->{columns}}) {
            $query .= join(', ',
                map { ref $_ ? $$_ : $need_prefix ? "$prefix.`$_`" : "`$_`" }
                  @{$source->{columns}});
        } else {
            $query .= $need_prefix ? "$prefix.*" : '*';
        }

        $first = 0;
    }

    $query .= ' FROM ';

    $first = 1;
    foreach my $source (@{$self->_sources}) {
        $query .= ', ' unless $first || $source->{join};

        $query .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};
        $query .= '`' . $source->{name} . '`';

        $query .= ' AS ' . '`' . $source->{as} . '`' if $source->{as};

        $query .= ' ON ' . $source->{constraint} if $source->{constraint};

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

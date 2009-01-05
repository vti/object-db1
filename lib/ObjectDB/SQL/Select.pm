package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::SQL';

__PACKAGE__->attr([qw/ group_by having order_by limit offset /], chained => 1);
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
        if (@{$source->{columns}}) {
            $query .= ', ' unless $first;
            my $prefix = $need_prefix ? $source->{name} : undef;

            $query .= join(', ',
                map { ref $_ ? $$_ : $need_prefix ? "$prefix.`$_`" : "`$_`" }
                  @{$source->{columns}});

            $first = 0;
        }
    }

    $query .= ' FROM ';

    $query .= $self->_sources_to_string;

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_where_to_string($self->where);
    }

    $query .= ' GROUP BY ' . $self->group_by if $self->group_by;

    $query .= ' HAVING ' . $self->having if $self->having;

    $query .= ' ORDER BY ' . $self->order_by if $self->order_by;

    $query .= ' LIMIT ' . $self->limit if $self->limit;

    $query .= ' OFFSET ' . $self->offset if $self->offset;

    return $query;
}

sub _sources_to_string {
    my $self = shift;

    my $string = "";

    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        $string .= ', ' unless $first || $source->{join};

        $string .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};
        $string .= '`' . $source->{name} . '`';

        $string .= ' AS ' . '`' . $source->{as} . '`' if $source->{as};

        $string .= ' ON ' . $source->{constraint} if $source->{constraint};

        $first = 0;
    }

    return $string;
}

1;

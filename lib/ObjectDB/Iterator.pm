package ObjectDB::Iterator;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr('step', chained => 1, default => 0);
__PACKAGE__->attr([qw/ with class sth /], chained => 1);

sub next {
    my $self = shift;

    return unless $self->sth;

    my @row = $self->sth->fetchrow_array;
    return unless @row;

    $self->step($self->step + 1);

    my @columns = $self->class->meta->columns;

    my $object = $self->class->_map_row_to_object(
        row  => \@row,
        columns => \@columns,
        with => $self->with
    );

    return $object;
}

1;

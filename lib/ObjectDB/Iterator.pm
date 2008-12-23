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

    my %values = map { $_ => shift @row } @columns;

    my $object = $self->class->new(%values);

    if ($self->with) {
        my $relationship = $object->meta->relationships->{$self->with};

        if (   $relationship->{type} eq 'many to one'
            || $relationship->{type} eq 'one to one')
        {
            %values =
              map { $_ => shift @row } $relationship->{class}->meta->columns;
            $object->_relationships->{$self->with} =
              $relationship->{class}->new(%values);
        }
        else {
            die 'not supported';
        }
    }

    $object->iterator($self);

    return $object;
}

1;

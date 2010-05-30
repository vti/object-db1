package ObjectDB::Iterator;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub sth { @_ > 1 ? $_[0]->{sth} = $_[1] : $_[0]->{sth} }

sub next {
    my $self = shift;

    return unless $self->sth;

    my @row = $self->sth->fetchrow_array;
    return unless @row;

    my $objects = $self->{object}->_map_rows_to_objects(
        rows    => [[@row]],
        sql     => $self->{sql},
    );

    return $objects->[0];
}

1;

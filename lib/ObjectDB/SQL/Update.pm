package ObjectDB::SQL::Update;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ _parent table where /], chained => 1);
__PACKAGE__->attr([qw/ columns bind /], default => sub {[]}, chained => 1);

sub add_columns {
    my $self = shift;

    return unless @_;

    push @{$self->columns}, @_;
}

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'UPDATE ';
    $query .= $self->table;
    $query .= ' SET ';

    my $i = @{$self->columns} - 1;
    foreach my $name (@{$self->columns}) {
        $query .= "$name = ?";
        $query .= ', ' if $i;
        $i--;
    }

    if ($self->where) {
        $query .= ' WHERE ';
        $query .= $self->_parent->_where_to_string($self->where);
    }

    return $query;
}

1;
